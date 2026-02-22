import { existsSync, readdirSync, readFileSync } from 'fs';
import { join } from 'path';

import { reconstructReceipt } from '../receiptReconstructor';
import type { ScanMetadata, TextBlock } from '../NativeDocumentScanner';

// ─── Types ───────────────────────────────────────────────────────────────────

interface FixtureOptions {
  lineWidth?: number;
  minConfidence?: number | null;
  rowGroupingFactor?: number;
}

/**
 * Shape of every JSON file in src/__fixtures__/.
 *
 * Drop a new .json file in that folder and it will automatically appear
 * as a Jest test case — no code changes needed.
 *
 * Fields:
 *   description   — Human-readable label shown in test output.
 *   metadata      — Copy the `metadata` field from your ScanResult verbatim.
 *   text          — The raw `text` field from the ScanResult (used by V2 path).
 *   blocks        — The `blocks` array from the ScanResult (used by V1 path).
 *   options       — Optional overrides forwarded to reconstructReceipt().
 *   expected      — If provided, the test asserts exact equality.
 *                   If null / omitted, the test uses a Jest snapshot instead.
 */
interface Fixture {
  _comment?: string;
  description: string;
  metadata: ScanMetadata;
  text?: string;
  blocks: TextBlock[];
  options?: FixtureOptions;
  expected?: string | null;
}

// ─── Test suite ──────────────────────────────────────────────────────────────

const FIXTURES_DIR = join(__dirname, '..', '__fixtures__');

const fixtureFiles = existsSync(FIXTURES_DIR)
  ? readdirSync(FIXTURES_DIR)
      .filter((f) => f.endsWith('.json') && f !== 'template.json')
      .sort()
  : [];

if (fixtureFiles.length === 0) {
  it.todo(
    'No fixture files yet — paste real OCR output into src/__fixtures__/<name>.json'
  );
} else {
  describe('reconstructReceipt', () => {
    test.each(fixtureFiles)('%s', (filename) => {
      const fixture: Fixture = JSON.parse(
        readFileSync(join(FIXTURES_DIR, filename), 'utf-8')
      );

      const { lineWidth, minConfidence, rowGroupingFactor } =
        fixture.options ?? {};

      const result = reconstructReceipt(
        {
          metadata: fixture.metadata,
          blocks: fixture.blocks,
          text: fixture.text,
        },
        {
          lineWidth: lineWidth ?? 56,
          minConfidence: minConfidence ?? undefined,
          rowGroupingFactor,
        }
      );

      if (fixture.expected != null) {
        expect(result).toBe(fixture.expected);
      } else {
        expect(result).toMatchSnapshot();
      }
    });
  });
}
