# react-native-document-scanner

A powerful, high-performance React Native library for scanning documents and extracting text using native platform APIs. Optimized for structured documents like receipts, invoices, and forms.

## Features

- 📸 **Document Scanning**: Native UI for scanning documents with auto-detection and perspective correction (VisionKit on iOS, ML Kit on Android).
- 🖼️ **Image Processing**: High-performance filters including Grayscale, Monochrome, Denoise, and Sharpen.
- 📝 **Dual-Engine OCR**: Choose between raw platform output (V1) and layout-preserving heuristic extraction (V2).
- 🧠 **Adaptive Heuristics**: Intelligent line clustering and adaptive spacing for perfect horizontal alignment on receipts.
- ⚙️ **Batch Processing**: Headless processing of existing images from file system, Content URIs, or Base64.
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

## OCR Engine Versions

The library provides two distinct OCR extraction strategies via the `textVersion` parameter:

### Version 1: Raw Output

- **iOS**: Uses standard Apple Vision `VNRecognizeTextRequest` with language correction enabled.
- **Android**: Returns raw `textBlocks` from ML Kit.
- **Best For**: General prose, paragraphs, and unstructured text.

### Version 2: Heuristic Enhanced (Default)

Our custom **LineCluster** strategy with adaptive growth constraints.

- **Adaptive Clustering**: Distinguishes between stacked lines and skewed text using horizontal overlap analysis.
- **Spatial Reconstruction**: Injects precise spacing between columns based on median character heights.
- **Layout Preservation**: Ensures items and prices on a receipt stay aligned on the same horizontal string.
- **Best For**: Receipts, Invoices, Tables, and Structured Forms.

---

## API Reference

### `scanDocuments(options?: ScanOptions): Promise<ScanResult[]>`

### `processDocuments(options: ProcessOptions): Promise<ScanResult[]>`

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

| Property | Type          | Description                                              |
| :------- | :------------ | :------------------------------------------------------- |
| `uri`    | `string`      | Local temporary file path of the processed image.        |
| `text`   | `string`      | The full extracted text. V2 preserves the visual layout. |
| `blocks` | `TextBlock[]` | Granular metadata for each recognized text segment.      |
| `base64` | `string`      | Optional binary data (if `includeBase64` is true).       |

### `TextBlock`

The coordinate system is **unified** across iOS and Android:

- **Range**: `0.0` to `1.0` (Normalized).
- **Origin**: `(0,0)` is the **Top-Left** corner.
- **Sorting**: Blocks are returned in a natural **top-to-bottom reading order**.

```typescript
interface TextBlock {
  text: string; // Content of the block
  confidence: number; // Engine reliability (0.0 to 1.0)
  frame: {
    x: number; // Horizontal offset (0 = left)
    y: number; // Vertical offset (0 = top)
    width: number; // Normalized width (fraction of image)
    height: number; // Normalized height (fraction of image)
  };
}
```

---

## OCR Engine Deep-Dive

We solve the "Jumbled OCR" problem common in mobile scanning by providing two specialized engines:

### V1: Raw Platform (Deterministic)

Returns the raw output from Apple Vision (with language correction) or Google ML Kit.

- **iOS Strategy**: Uses standard top-candidates from observations.
- **Android Strategy**: Uses standard `TextBlocks`.
- **Latency**: Minimal.

### V2: Adaptive Heuristic (Layout-Aware)

Our custom **LineCluster** algorithm rebuilds the document structure from word-level elements.

- **Collinear Analysis**: Groups words into logical lines even if slightly skewed.
- **Adaptive Spacing**: Measures median character heights to inject proportional whitespace between text columns (perfect for receipts).
- **Growth Constraints**: Prevents vertically adjacent lines from merging while allowing horizontal growth.

---

## Technical Safeguards

- **Multi-Threaded**: All heavy image processing and OCR operations are executed on background IO dispatchers (`Swift GCD` / `Kotlin Coroutines`).
- **Memory Efficient**: Original bitmaps are recycled immediately, and processed images are stored in temporary cache directories to prevent OOM errors.
- **Coordinate Parity**: We've mathematically normalized Apple's bottom-left origin to match Android's top-left origin, ensuring your UI overlays work identically on both platforms.
- **Failsafe Normalization**: Safe division helpers prevent crashes if the device returns an image with zero-width/height metadata.

---

## Requirements

- React Native 0.71+ (New Architecture recommended)
- iOS 13.0+
- Android API 21+

## License

MIT
