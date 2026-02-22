# react-native-document-scanner

A powerful, high-performance React Native library for scanning documents and extracting text using native platform APIs. Optimized for structured documents like receipts, invoices, and forms.

## Features

- 📸 **Document Scanning**: Native UI for scanning documents with auto-detection and perspective correction (VisionKit on iOS, ML Kit on Android).
- 🖼️ **Image Processing**: High-performance filters including Grayscale, Monochrome, Denoise, and Sharpen.
- 📝 **Dual-Engine OCR**: Choose between raw platform output (V1) and layout-preserving heuristic extraction (V2).
- 🧠 **Adaptive Heuristics**: Intelligent line clustering and adaptive spacing for perfect horizontal alignment on receipts.
- ⚙️ **Batch Processing**: Headless processing of existing images from file system, Content URIs, or Base64.
- 🗂️ **Result Metadata**: Every `ScanResult` includes `metadata` (platform, OCR engine, filter, version) so you always know exactly how the result was produced.
- 🧾 **Receipt Reconstruction**: Pure JS `reconstructReceipt` utility re-renders `blocks` as a column-aligned string — works across all platforms and versions.
- 🚀 **TurboModules**: Built from the ground up for the React Native New Architecture.
- 📱 **Cross-Platform Parity**: Identical coordinate systems and configuration logic across iOS and Android.

## Platform Support

| Feature             | iOS              | Android                 |
| ------------------- | ---------------- | ----------------------- |
| Document Scanning   | VisionKit        | ML Kit Document Scanner |
| OCR Engine          | Vision Framework | ML Kit Text Recognition |
| Coordinate Origin   | **Top-Left**     | **Top-Left**            |
| Logic Architecture  | Swift            | Kotlin (Coroutines)     |
| Layout Preservation | ✅ (V2)          | ✅ (V2)                 |

---

## Installation

```sh
yarn add @hoshomoh/react-native-document-scanner
# or
npm install @hoshomoh/react-native-document-scanner
```

### iOS Setup

```sh
cd ios && pod install
```

### Android Setup

No additional setup required. Google Play Services will automatically manage ML Kit models.

---

## Usage

### 1. Scan Documents (Camera UI)

Opens the system scanner. Best for manual document capture.

```typescript
import { scanDocuments } from '@hoshomoh/react-native-document-scanner';

const results = await scanDocuments({
  maxPageCount: 5,
  textVersion: 2, // Use V2 for receipt layout extraction
  filter: 'ocrOptimized', // Applies denoise -> sharpen -> monochrome
  includeText: true,
});
```

### 2. Process Existing Images (Headless)

Batch process images already on the device.

```typescript
import { processDocuments } from '@hoshomoh/react-native-document-scanner';

const results = await processDocuments({
  images: ['file:///path/to/receipt.jpg'],
  textVersion: 2,
  includeText: true,
});
```

---

## API Reference

### `scanDocuments(options?: ScanOptions): Promise<ScanResult[]>`

### `processDocuments(options: ProcessOptions): Promise<ScanResult[]>`

### `reconstructReceipt(blocks: TextBlock[], options?: ReconstructOptions): string`

Reconstructs `blocks` as a column-aligned plain-text string. See [Receipt & Document Reconstruction](#receipt--document-reconstruction) for full details.

### `getReconstructMode(metadata: ScanMetadata): ReconstructMode`

Returns `'paragraphs'` or `'clustered'` based on `result.metadata`, so you never have to hard-code the mode. See [Receipt & Document Reconstruction](#receipt--document-reconstruction).

### Options

| Property        | Type             | Default   | Description                                                              |
| --------------- | ---------------- | --------- | ------------------------------------------------------------------------ |
| `textVersion`   | `1 \| 2`         | `2`       | OCR Engine version (1 = Raw, 2 = Heuristic)                              |
| `includeText`   | `boolean`        | `false`   | Perform OCR and return structured text                                   |
| `filter`        | `FilterType`     | `'color'` | `color`, `grayscale`, `monochrome`, `denoise`, `sharpen`, `ocrOptimized` |
| `quality`       | `number`         | `1.0`     | Image compression quality (0.1 - 1.0)                                    |
| `format`        | `'jpg' \| 'png'` | `'jpg'`   | Output file format                                                       |
| `maxPageCount`  | `number`         | `0`       | (Scan only) Limit pages (0 = unlimited). Max 100.                        |
| `includeBase64` | `boolean`        | `false`   | Returns binary data as Base64 string                                     |
| `images`        | `string[]`       | **Req.**  | (Process only) Local URIs or Base64 data strings                         |

---

## Result Types

### `ScanResult`

| Property   | Type           | Description                                                                        |
| :--------- | :------------- | :--------------------------------------------------------------------------------- |
| `uri`      | `string`       | Local temporary file path of the processed image.                                  |
| `text`     | `string`       | The full extracted text. V2 preserves the visual layout.                           |
| `blocks`   | `TextBlock[]`  | One block per visual line, in top-to-bottom order.                                 |
| `base64`   | `string`       | Optional binary data (if `includeBase64` is true).                                 |
| `metadata` | `ScanMetadata` | Platform, engine, filter, and version used to produce this result. Always present. |

### `TextBlock`

The coordinate system is **unified** across iOS and Android:

- **Range**: `0.0` to `1.0` (Normalized).
- **Origin**: `(0,0)` is the **Top-Left** corner.
- **Sorting**: Blocks are returned in a natural **top-to-bottom reading order**.

```typescript
interface TextBlock {
  text: string; // Content of the block (one visual line)
  confidence?: number; // Engine reliability (0.0–1.0). May be absent — see notes below.
  frame: {
    x: number; // Horizontal offset from left (0.0–1.0)
    y: number; // Vertical offset from top (0.0–1.0)
    width: number; // Normalized width (fraction of image width)
    height: number; // Normalized height (fraction of image height)
  };
}
```

---

## OCR Engine Versions

The library provides two distinct OCR extraction strategies via the `textVersion` parameter. For V1 and V2 (LineCluster path), every entry in the `blocks` array represents exactly one visual line of text, and `blocks[i].text` corresponds to line `i` in the `text` string. On iOS 26+ V2 (`RecognizeDocumentsRequest`), blocks are paragraph-level and may not align 1:1 with split lines — see the [Block Contract](#block-contract) note below.

### Version 1 — Raw Output (`textVersion: 1`)

Returns the platform's native OCR output with minimal post-processing.

|                       | iOS                                                    | Android                                           |
| --------------------- | ------------------------------------------------------ | ------------------------------------------------- |
| **Engine**            | `VNRecognizeTextRequest` (language correction enabled) | ML Kit Text Recognition                           |
| **Block granularity** | One block per Vision observation (≈ one visual line)   | One block per ML Kit `TextLine`                   |
| **`text` field**      | Lines joined with `\n`, no trailing newline            | ML Kit's full recognized text                     |
| **Confidence**        | Always present (per observation)                       | Present when ML Kit provides element-level detail |
| **Best for**          | General prose, paragraphs, unstructured text           | General prose, paragraphs, unstructured text      |

**When to use V1:** You want the raw platform output with the least processing overhead. Suitable for plain paragraphs where layout structure doesn't matter.

---

### Version 2 — Heuristic Enhanced (`textVersion: 2`, default)

Our custom **LineCluster** algorithm rebuilds the document's visual line structure from word-level elements, then reconstructs spacing proportionally.

|                       | iOS (< 26)                                              | iOS 26+                                                | Android                                           |
| --------------------- | ------------------------------------------------------- | ------------------------------------------------------ | ------------------------------------------------- |
| **Engine**            | `VNRecognizeTextRequest` (language correction disabled) | `RecognizeDocumentsRequest`                            | ML Kit Text Recognition                           |
| **Clustering**        | Word-level spatial clustering (LineCluster)             | Native document paragraphs                             | Word-level spatial clustering (LineCluster)       |
| **Block granularity** | One block per cluster (= one visual line)               | One block per paragraph (≈ one visual line)            | One block per cluster (= one visual line)         |
| **`text` field**      | Lines joined with `\n`, trailing newline included       | Paragraphs joined with `\n`, trailing newline included | Lines joined with `\n`, trailing newline included |
| **Confidence**        | Average across observations in the cluster              | Not available (platform does not expose it)            | Average across word elements in the cluster       |
| **Noise filtering**   | `minimumTextHeight` filters sub-1% height artifacts     | Handled natively                                       | N/A (ML Kit filters internally)                   |
| **Multilingual**      | Auto-detected on iOS 16+                                | Supported natively (26 languages)                      | Auto-detected by ML Kit                           |
| **Best for**          | Receipts, invoices, tables, structured forms            | Receipts, invoices, tables, structured forms           | Receipts, invoices, tables, structured forms      |

**When to use V2:** You need reliable line-by-line layout — e.g., aligning item names with their prices on a receipt, or overlaying bounding boxes on the scanned image.

---

### Block Contract

V1 and V2 (LineCluster path) guarantee **one `TextBlock` per visual line**. `blocks[i].text` corresponds to line `i` in the `text` string, making `blocks` a reliable source for building overlay UIs:

```typescript
const { text, blocks } = result;

// Safe for V1 and V2 (LineCluster) on both platforms
blocks.forEach((block, i) => {
  drawBoundingBox(block.frame); // Overlay each line's box on the image
  console.log(block.text); // Text for that line
});
```

> **iOS 26+ V2 note:** `RecognizeDocumentsRequest` returns one block per **paragraph**. For most single-column documents this equals one visual line, but multi-column rows (e.g. a receipt item name and its price) may appear as two separate blocks side by side. Use `reconstructReceipt` to merge and column-align them.

#### Confidence availability

`confidence` is not guaranteed to be present in all cases:

| Version       | iOS                      | Android                                                        |
| ------------- | ------------------------ | -------------------------------------------------------------- |
| V1            | Always present           | Present when ML Kit provides element-level detail for the line |
| V2            | Always present           | Always present                                                 |
| V2 on iOS 26+ | **Absent** (`undefined`) | N/A                                                            |

Always guard when reading confidence:

```typescript
if (block.confidence !== undefined) {
  console.log(`Confidence: ${block.confidence}`);
}
```

#### `text` trailing newline

V2 appends a trailing `\n` to the full `text` string. V1 does not. Account for this when splitting:

```typescript
// Safe on both V1 and V2 — trimEnd removes the trailing newline if present
const lines = result.text.trimEnd().split('\n');
// V1 + V2 (LineCluster): lines.length === result.blocks.length ✓
// iOS 26+ V2: lines.length may differ from blocks.length (paragraph vs line granularity)
```

---

## OCR Engine Deep-Dive

### V1: Raw Platform Output

Returns the native platform output directly. No spatial re-clustering is performed.

- **iOS**: One block per `VNRecognizedTextObservation`. Language correction is **enabled**, which helps with general prose but may merge or alter words in structured tables.
- **Android**: One block per ML Kit `TextLine`. The full `text` string is ML Kit's native concatenation of all recognized lines.
- **Latency**: Minimal — no additional processing beyond the platform OCR call.

### V2: Adaptive LineCluster (iOS < 26 and Android)

Our **LineCluster** algorithm operates at word level and reconstructs visual lines through four heuristics applied in order for each word element:

1. **Height Compatibility** — Elements whose height ratio (`minH / maxH`) falls below `0.40` are never grouped. This prevents subscripts, headers, and footnotes from being merged into adjacent body lines. Uses **median** cluster element height (not union bbox height) to prevent drift as more words are added.

2. **Vertical Overlap & Centerline** — An element must either vertically overlap the cluster by ≥ 50% of the smaller height, or have its center within 70% of the typical line height from the cluster's **median center Y** (not the union midpoint). Using the median prevents centerline drift on long lines.

3. **Adaptive Growth Constraint** — A candidate merge is rejected if it would grow the cluster's union bounding box to more than `1.2×` the typical line height (when horizontally stacked) or `2.0×` (when purely side-by-side). This blocks two adjacent lines from being merged while still accommodating natural OCR jitter.

4. **Best-Cluster Scoring** — When multiple clusters pass all three tests, the one with the highest vertical overlap ratio wins. Ties are broken by closest centerline distance.

After clustering, words within each cluster are sorted left-to-right and the gap between adjacent words is measured. If the gap exceeds `0.5×` the median character height, proportional spaces are inserted based on a `0.3×` space-width factor (capped at 10 spaces). This recreates column alignment on receipts and tables.

### V2: iOS 26+ Native Fast Path

On iOS 26 and later, `textVersion: 2` automatically uses `RecognizeDocumentsRequest` — Apple's structured document understanding API — instead of the heuristic LineCluster path. This API returns native paragraph groupings with precise bounding regions across 26 languages, with no risk of the clustering edge cases that affect older OS versions. The output format is identical to the LineCluster path, so no code changes are required.

---

## Receipt & Document Reconstruction

`reconstructReceipt` is a pure JavaScript utility that re-renders the `blocks` array as a column-aligned plain-text string. It is most useful when the native engine returns one block per paragraph rather than per fully-assembled line — specifically on **iOS 26+** where `RecognizeDocumentsRequest` separates multi-column lines (e.g. an item name block and a price block) into individual paragraph blocks.

### Import

```typescript
import {
  reconstructReceipt,
  getReconstructMode,
} from '@hoshomoh/react-native-document-scanner';
```

### Recommended pattern — let metadata choose the mode

Every `ScanResult` now includes a `metadata` field that identifies the platform, OCR version, and exact engine used. Pass it to `getReconstructMode` to get the correct `mode` automatically:

```typescript
const results = await scanDocuments({ includeText: true, textVersion: 2 });
const result = results[0];

if (result.blocks && result.metadata) {
  const mode = getReconstructMode(result.metadata);
  const receipt = reconstructReceipt(result.blocks, { mode });
  console.log(receipt);
}
```

### `ScanMetadata`

| Field         | Type                 | Description                       |
| ------------- | -------------------- | --------------------------------- |
| `platform`    | `'ios' \| 'android'` | Platform that produced the result |
| `textVersion` | `1 \| 2`             | OCR version that was requested    |
| `filter`      | `FilterType`         | Image filter applied before OCR   |
| `ocrEngine`   | see below            | Exact engine used                 |

`ocrEngine` values and the correct `reconstructReceipt` mode for each:

| `ocrEngine`                   | When                  | `mode`         |
| ----------------------------- | --------------------- | -------------- |
| `"RecognizeDocumentsRequest"` | iOS 26+ V2            | `'paragraphs'` |
| `"VNRecognizeTextRequest"`    | iOS V1 or V2 < iOS 26 | `'clustered'`  |
| `"MLKit"`                     | Android V1 or V2      | `'clustered'`  |
| `"none"`                      | `includeText: false`  | N/A            |

### `reconstructReceipt` options

| Option              | Type                          | Default        | Description                                                                                                                                                                                   |
| ------------------- | ----------------------------- | -------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `mode`              | `'paragraphs' \| 'clustered'` | `'paragraphs'` | Row-grouping strategy. `'paragraphs'` for iOS 26+ V2; `'clustered'` for everything else.                                                                                                      |
| `lineWidth`         | `number`                      | `56`           | Output width in characters. Use 48 for narrow receipts, 64+ for wide documents.                                                                                                               |
| `minConfidence`     | `number`                      | none           | Discard blocks below this confidence threshold before reconstruction. Useful when scan quality is poor. Has no effect on iOS 26+ (confidence is not provided by `RecognizeDocumentsRequest`). |
| `rowGroupingFactor` | `number`                      | from `mode`    | Advanced: override the Y-proximity threshold directly (0.7 for `'paragraphs'`, 0.4 for `'clustered'`).                                                                                        |

### When to use `result.text` vs `reconstructReceipt`

| Source               | Use `result.text`                                   | Use `reconstructReceipt`                                            |
| -------------------- | --------------------------------------------------- | ------------------------------------------------------------------- |
| iOS 26+ V2           | `text` has correct line order but no column spacing | ✅ Reconstructs column alignment from block X positions             |
| iOS < 26 V2          | ✅ Column spacing already baked in by LineCluster   | Optional — use `mode: 'clustered'` if you prefer block-based output |
| Android V2           | ✅ Column spacing already baked in by LineCluster   | Optional — use `mode: 'clustered'`                                  |
| V1 (either platform) | Lines present but no column spacing                 | ✅ Reconstructs alignment from block X positions                    |

---

## OCR Accuracy

### Filter recommendation

The single biggest improvement for poor-quality scans is the `ocrOptimized` filter. It applies a **denoise → sharpen → monochrome** pipeline before OCR:

```typescript
await scanDocuments({
  includeText: true,
  filter: 'ocrOptimized',
  textVersion: 2,
});
```

Use this whenever scans come from a phone camera rather than a dedicated flatbed scanner. It eliminates noise that would otherwise produce garbage characters in the OCR output.

### Confidence filtering

Low-confidence blocks often represent scan artefacts, smudged text, or regions where the engine guessed. Filter them during reconstruction:

```typescript
const receipt = reconstructReceipt(result.blocks ?? [], {
  mode: getReconstructMode(result.metadata!),
  minConfidence: 0.4, // drop blocks the engine was less than 40% sure about
});
```

### Known accuracy limitations

| Scenario                             | Cause                                                                              | Mitigation                                                                                   |
| ------------------------------------ | ---------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| Unusual fonts / handwriting          | OCR engine trained on standard print                                               | Use `ocrOptimized` filter; V2 is more accurate than V1 for structured documents              |
| iOS 26+ item/price column mispairing | `RecognizeDocumentsRequest` paragraph Y centres may differ slightly across columns | Adjust `rowGroupingFactor` in `reconstructReceipt`                                           |
| Non-Latin characters misread         | Wrong language model active                                                        | iOS < 26: `automaticallyDetectsLanguage` is enabled on iOS 16+; Android: ML Kit auto-detects |
| Very small text dropped              | Below `minimumTextHeight` (1% of image height) on iOS                              | Reduce `minimumTextHeight` in `OCRConfiguration.swift` if small legitimate text is lost      |

---

## Technical Safeguards

- **Non-blocking**: All image processing and OCR run on background Swift Concurrency tasks (`Task(priority: .userInitiated)`) or Kotlin coroutines. The UI thread is never blocked.
- **Memory Efficient**: Original bitmaps are recycled immediately, and processed images are stored in temporary cache directories to prevent OOM errors.
- **Coordinate Parity**: Apple Vision uses a bottom-left origin. We mathematically normalize all bounding boxes to top-left origin (`y = 1 - originY - height`), ensuring overlay UIs work identically on both platforms.
- **Failsafe Normalization**: Safe division helpers return `0.0` instead of crashing when image dimensions are zero.
- **Noise Filtering** (iOS V1 & V2 < iOS 26): `minimumTextHeight = 0.01` discards Vision observations whose bounding box is smaller than 1% of the image height, eliminating ruled lines, watermarks, and scan artifacts from the OCR output.

---

## Requirements

- React Native 0.71+ (New Architecture recommended)
- iOS 13.0+
- Android API 21+

## License

MIT
