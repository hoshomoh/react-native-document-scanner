import type { TextBlock, ScanMetadata } from './NativeDocumentScanner';

// Internal — not part of the public API.
type ReconstructMode = 'paragraphs' | 'clustered';

const MODE_FACTOR: Record<ReconstructMode, number> = {
  paragraphs: 0.5,
  clustered: 0.4,
};

export interface ReconstructOptions {
  /**
   * Width of the output in characters.
   * Default: 56. Use 48 for narrow thermal receipts, 64+ for wide documents.
   */
  lineWidth?: number;
  /**
   * Discard blocks whose `confidence` is below this value before
   * reconstruction. Useful when scan quality is poor and low-confidence
   * blocks produce garbage characters that disrupt the output.
   *
   * Only applies to V1 on any platform. Has no effect on V2 paths (native
   * text is returned directly) or on iOS 26+ RecognizeDocumentsRequest
   * (paragraph confidence is not exposed by the API — blocks always pass).
   *
   * Suggested values: `0.3` (aggressive), `0.5` (moderate).
   * Default: `undefined` (no filtering).
   */
  minConfidence?: number;
  /**
   * Fine-tune the Y-proximity threshold directly. The threshold is
   * `rowGroupingFactor × medianLineHeight`. Increase if blocks on the same
   * visual line are being split into separate rows. Decrease if adjacent
   * lines are being merged.
   *
   * Only applies to the block-based reconstruction path (V1 and iOS 26+).
   */
  rowGroupingFactor?: number;
}

/**
 * Reconstructs a visually-aligned plain-text document from a `ScanResult`.
 *
 * Automatically selects the right strategy based on the OCR engine recorded
 * in `metadata` — no manual mode selection needed:
 *
 * | Engine                          | Strategy                                |
 * |---------------------------------|-----------------------------------------|
 * | V2 · MLKit or VNRecognizeText   | Returns `text` directly — the native    |
 * |                                 | clustering already produced column-     |
 * |                                 | aligned output.                         |
 * | iOS 26+ RecognizeDocumentsReq.  | Spatially reconstructs from paragraph-  |
 * |                                 | level blocks.                           |
 * | V1 · either platform            | Spatially reconstructs from line-level  |
 * |                                 | blocks.                                 |
 *
 * @param scanResult A `ScanResult` (or any object with `text`, `blocks`, `metadata`).
 * @param options    Optional output tuning.
 * @returns A plain-text string with column-aligned rows.
 *
 * @example
 * const results = await scanDocuments({ includeText: true });
 * const text = reconstructReceipt(results[0]);
 */
export function reconstructReceipt(
  scanResult: { text?: string; blocks?: TextBlock[]; metadata?: ScanMetadata },
  options: ReconstructOptions = {}
): string {
  const { metadata, blocks = [], text = '' } = scanResult;

  // V2 via VNRecognizeTextRequest or MLKit: the native adaptive clustering
  // already produced column-aligned text — return it directly.
  // If text is absent (caller omitted it), fall back to block reconstruction
  // using the line-level cluster blocks rather than returning empty.
  if (
    metadata?.textVersion === 2 &&
    metadata.ocrEngine !== 'RecognizeDocumentsRequest'
  ) {
    if (text) {
      return text.trimEnd();
    }
    return reconstructFromBlocks(blocks, 'clustered', options);
  }

  // iOS 26+ RecognizeDocumentsRequest returns paragraph-level blocks;
  // V1 on any platform returns line-level blocks.
  // Both paths use the spatial block reconstruction algorithm.
  const mode: ReconstructMode =
    metadata?.ocrEngine === 'RecognizeDocumentsRequest'
      ? 'paragraphs'
      : 'clustered';

  return reconstructFromBlocks(blocks, mode, options);
}

// ─── Internal block reconstruction algorithm ─────────────────────────────────

function reconstructFromBlocks(
  blocks: TextBlock[],
  mode: ReconstructMode,
  options: ReconstructOptions
): string {
  const { lineWidth = 56, minConfidence } = options;
  const rowGroupingFactor = options.rowGroupingFactor ?? MODE_FACTOR[mode];

  // Step 1: Filter by confidence when requested.
  const filtered =
    minConfidence !== undefined
      ? blocks.filter(
          (b) => b.confidence === undefined || b.confidence >= minConfidence
        )
      : blocks;

  if (filtered.length === 0) {
    return '';
  }

  // Step 2: Compute the median block height (= reference line height).
  const heights = filtered.map((b) => b.frame.height).sort((a, b) => a - b);
  const hMid = Math.floor(heights.length / 2);
  const typicalHeight =
    heights.length % 2 === 0
      ? (heights[hMid - 1]! + heights[hMid]!) / 2
      : heights[hMid]!;

  const threshold =
    rowGroupingFactor * (typicalHeight > 0 ? typicalHeight : 0.02);

  // Step 3: Sort all blocks by midY ascending (top of page first).
  const sorted = [...filtered].sort((a, b) => {
    const midA = a.frame.y + a.frame.height / 2;
    const midB = b.frame.y + b.frame.height / 2;
    return midA - midB;
  });

  // Step 4: Greedy row grouping by midY proximity.
  // Each row tracks a running median centerY so that adding blocks to one
  // side of a long line doesn't pull the reference point away from the others.
  interface Row {
    blocks: TextBlock[];
    midYs: number[];
    medianMidY: number;
  }

  function computeMedian(values: number[]): number {
    const s = [...values].sort((a, b) => a - b);
    const m = Math.floor(s.length / 2);
    return s.length % 2 === 0 ? (s[m - 1]! + s[m]!) / 2 : s[m]!;
  }

  const rows: Row[] = [];

  for (const block of sorted) {
    const blockMidY = block.frame.y + block.frame.height / 2;

    let bestRow: Row | null = null;
    let bestDist = Infinity;

    for (const row of rows) {
      const dist = Math.abs(row.medianMidY - blockMidY);
      if (dist < threshold && dist < bestDist) {
        bestDist = dist;
        bestRow = row;
      }
    }

    if (bestRow !== null) {
      bestRow.blocks.push(block);
      bestRow.midYs.push(blockMidY);
      bestRow.medianMidY = computeMedian(bestRow.midYs);
    } else {
      rows.push({
        blocks: [block],
        midYs: [blockMidY],
        medianMidY: blockMidY,
      });
    }
  }

  // Step 5: Sort rows top-to-bottom.
  rows.sort((a, b) => a.medianMidY - b.medianMidY);

  // Step 6: Render each row into a fixed-width character buffer.
  const lines: string[] = [];

  for (const row of rows) {
    // Sort blocks left-to-right within the row.
    const rowBlocks = [...row.blocks].sort((a, b) => a.frame.x - b.frame.x);

    const buf = new Array<string>(lineWidth).fill(' ');
    let cursor = 0;

    for (const block of rowBlocks) {
      // Map normalized X to a character column, but never retreat behind cursor.
      const col = Math.max(Math.round(block.frame.x * lineWidth), cursor);

      for (let i = 0; i < block.text.length; i++) {
        const pos = col + i;
        if (pos < lineWidth) {
          buf[pos] = block.text[i]!;
        }
      }

      // Advance cursor past this block + a minimum single-space gap.
      cursor = col + block.text.length + 1;
    }

    lines.push(buf.join('').trimEnd());
  }

  return lines.join('\n');
}
