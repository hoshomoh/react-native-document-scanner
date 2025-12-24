# react-native-document-scanner

A powerful, high-performance React Native library for scanning documents using Apple's VisionKit and processing images with Vision framework.

Features:

- 📸 **Document Scanning**: Native UI for scanning documents (auto-detection, perspective correction).
- 🖼️ **Image Processing**: Filter presets (grayscale, monochrome) and format conversion.
- 📝 **OCR (Text Recognition)**: Extract text and structured blocks from images.
- ⚙️ **Batch Processing**: Process existing images from file system or Base64.
- 🚀 **TurboModules**: Built with the New Architecture for maximum performance.

## Installation

```sh
yarn add @hoshomoh/react-native-document-scanner
# or
npm i @hoshomoh/react-native-document-scanner
```

Rebuild your app:

```sh
cd ios && pod install
```

## Usage

### 1. Scan Documents (Camera)

Opens the native system scanner UI.

```typescript
import { scanDocuments } from '@hoshomoh/react-native-document-scanner';

try {
  const results = await scanDocuments({
    maxPageCount: 5,
    quality: 0.8,
    format: 'jpg',
    filter: 'monochrome', // Optimized for text
    includeText: true, // Enable OCR
    includeBase64: false,
  });

  console.log('Scanned pages:', results);
} catch (error) {
  console.error('Scan failed:', error);
}
```

### 2. Process Existing Images (Headless)

Run filters and OCR on images you already have (e.g., from Camera Roll or file system).

```typescript
import { processDocuments } from '@hoshomoh/react-native-document-scanner';

try {
  const results = await processDocuments({
    images: ['file:///path/to/image1.jpg', 'data:image/png;base64,...'],
    quality: 1.0,
    filter: 'grayscale',
    includeText: true,
  });

  console.log('Processed results:', results);
} catch (error) {
  console.error('Processing failed:', error);
}
```

## API Reference

### `ScanOptions`

Configuration for `scanDocuments`.

| Property        | Type                                     | Default     | Description                        |
| --------------- | ---------------------------------------- | ----------- | ---------------------------------- |
| `maxPageCount`  | `number`                                 | `undefined` | Limit number of pages (e.g., 1).   |
| `quality`       | `number`                                 | `1.0`       | JPEG compression (0.0 - 1.0).      |
| `format`        | `'jpg' \| 'png'`                         | `'jpg'`     | Output image format.               |
| `filter`        | `'color' \| 'grayscale' \| 'monochrome'` | `'color'`   | Image filter applied post-scan.    |
| `includeBase64` | `boolean`                                | `false`     | Return base64 string.              |
| `includeText`   | `boolean`                                | `false`     | Run OCR and return extracted text. |

### `ProcessOptions`

Configuration for `processDocuments`.

| Property        | Type                                     | Default      | Description                                |
| --------------- | ---------------------------------------- | ------------ | ------------------------------------------ |
| `images`        | `string[]`                               | **Required** | Array of file URIs or Base64 strings.      |
| `quality`       | `number`                                 | `1.0`        | JPEG compression (0.0 - 1.0).              |
| `format`        | `'jpg' \| 'png'`                         | `'jpg'`      | Output image format.                       |
| `filter`        | `'color' \| 'grayscale' \| 'monochrome'` | `'color'`    | Image filter applied.                      |
| `includeBase64` | `boolean`                                | `false`      | Return base64 string.                      |
| `includeText`   | `boolean`                                | `true`       | Run OCR (defaults to true for processing). |

### `ScanResult`

The object returned for each page.

```typescript
interface ScanResult {
  /** Local file URI of the processed image */
  uri?: string;

  /** Base64 string (if includeBase64 is true) */
  base64?: string;

  /** Full, layout-preserved UTF-8 text (if includeText is true) */
  text?: string;

  /** Structured text blocks with bounding boxes */
  blocks?: TextBlock[];
}
```

### `TextBlock`

```typescript
interface TextBlock {
  text: string;
  frame: {
    x: number; // x-coordinate (normalized 0-1)
    y: number; // y-coordinate (normalized 0-1)
    width: number; // normalized width
    height: number; // normalized height
  };
}
```
