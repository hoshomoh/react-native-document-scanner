# react-native-document-scanner

A powerful, high-performance React Native library for scanning documents and extracting text using native platform APIs.

## Features

- 📸 **Document Scanning**: Native UI for scanning documents with auto-detection and perspective correction
- 🖼️ **Image Processing**: 6 filter presets including OCR-optimized pipeline
- 📝 **OCR (Text Recognition)**: Extract text with layout preservation and confidence scores
- ⚙️ **Batch Processing**: Process existing images from file system or Base64
- 🚀 **TurboModules**: Built with React Native New Architecture for maximum performance
- 📱 **Cross-Platform**: Full support for iOS (VisionKit) and Android (ML Kit)

## Platform Support

| Feature             | iOS              | Android                   |
| ------------------- | ---------------- | ------------------------- |
| Document Scanning   | VisionKit        | ML Kit Document Scanner   |
| OCR                 | Vision Framework | ML Kit Text Recognition   |
| Image Filters       | CoreImage        | ColorMatrix + Convolution |
| Layout Preservation | ✅               | ✅                        |
| Confidence Scores   | ✅               | ✅                        |

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

No additional setup required. The library uses ML Kit which is downloaded on-demand.

> **Note**: On first use, ML Kit may need to download the document scanner model (~20MB).

---

## Usage

### 1. Scan Documents (Camera UI)

Opens the native system scanner UI.

```typescript
import { scanDocuments } from '@hoshomoh/react-native-document-scanner';

try {
  const results = await scanDocuments({
    maxPageCount: 5,
    quality: 0.8,
    format: 'jpg',
    filter: 'ocrOptimized', // Best for text extraction
    includeText: true,
  });

  results.forEach((page, index) => {
    console.log(`Page ${index + 1}:`, page.uri);
    console.log('Text:', page.text);
    console.log('Blocks:', page.blocks);
  });
} catch (error) {
  console.error('Scan failed:', error);
}
```

### 2. Process Existing Images (Headless)

Run filters and OCR on images you already have.

```typescript
import { processDocuments } from '@hoshomoh/react-native-document-scanner';

try {
  const results = await processDocuments({
    images: [
      'file:///path/to/image1.jpg',
      'content://media/external/images/123',
      'data:image/png;base64,iVBORw0KGgo...',
    ],
    filter: 'sharpen',
    includeText: true,
    includeBase64: true,
  });

  console.log('Processed results:', results);
} catch (error) {
  console.error('Processing failed:', error);
}
```

---

## API Reference

### `scanDocuments(options?: ScanOptions): Promise<ScanResult[]>`

Opens the native document scanner UI and returns scanned pages.

### `processDocuments(options: ProcessOptions): Promise<ScanResult[]>`

Processes existing images without opening the camera UI.

---

## Options

### `ScanOptions`

| Property        | Type             | Default     | Description                           |
| --------------- | ---------------- | ----------- | ------------------------------------- |
| `maxPageCount`  | `number`         | `undefined` | Maximum pages to scan (0 = unlimited) |
| `quality`       | `number`         | `1.0`       | JPEG compression quality (0.0-1.0)    |
| `format`        | `'jpg' \| 'png'` | `'jpg'`     | Output image format                   |
| `filter`        | `FilterType`     | `'color'`   | Image filter to apply                 |
| `includeBase64` | `boolean`        | `false`     | Include Base64 string in result       |
| `includeText`   | `boolean`        | `false`     | Perform OCR and include text/blocks   |

### `ProcessOptions`

| Property        | Type             | Default      | Description                                               |
| --------------- | ---------------- | ------------ | --------------------------------------------------------- |
| `images`        | `string[]`       | **Required** | Array of image sources (file URI, content URI, or Base64) |
| `quality`       | `number`         | `1.0`        | JPEG compression quality (0.0-1.0)                        |
| `format`        | `'jpg' \| 'png'` | `'jpg'`      | Output image format                                       |
| `filter`        | `FilterType`     | `'color'`    | Image filter to apply                                     |
| `includeBase64` | `boolean`        | `false`      | Include Base64 string in result                           |
| `includeText`   | `boolean`        | `true`       | Perform OCR (defaults to true for processing)             |

---

## Filters

The library supports 6 image filters:

| Filter         | Description                                   | Best For                      |
| -------------- | --------------------------------------------- | ----------------------------- |
| `color`        | No filter (original)                          | Photos, colored documents     |
| `grayscale`    | Desaturated image                             | General documents             |
| `monochrome`   | High-contrast B&W                             | Clean text documents          |
| `denoise`      | Noise reduction                               | Noisy photos, low-light scans |
| `sharpen`      | Edge enhancement                              | Blurry text, soft focus       |
| `ocrOptimized` | Full pipeline: denoise → sharpen → monochrome | **Best OCR accuracy**         |

### Example: Using ocrOptimized

```typescript
const results = await scanDocuments({
  filter: 'ocrOptimized',
  includeText: true,
});
```

---

## Result Types

### `ScanResult`

```typescript
interface ScanResult {
  /** Local file URI of the processed image */
  uri?: string;

  /** Base64 string (if includeBase64 is true) */
  base64?: string;

  /** Full, layout-preserved text (if includeText is true) */
  text?: string;

  /** Structured text blocks with metadata */
  blocks?: TextBlock[];
}
```

### `TextBlock`

```typescript
interface TextBlock {
  /** The recognized text content */
  text: string;

  /** Normalized bounding box (0-1 range) */
  frame: {
    x: number; // Left edge (0 = left, 1 = right)
    y: number; // Top edge (0 = top, 1 = bottom)
    width: number; // Normalized width
    height: number; // Normalized height
  };

  /** OCR confidence score (0.0-1.0) */
  confidence?: number;
}
```

---

## OCR Features

### Layout Preservation

The OCR engine preserves spatial layout of text, making it ideal for:

- Receipts (item + price on same line)
- Tables
- Multi-column documents

Example output:

```
Milk                    $3.99
Bread                   $2.49
Tax                     $0.52
---------------------------------
Total                   $7.00
```

### Confidence Scores

Each text block includes a confidence score (0.0-1.0) indicating OCR reliability:

```typescript
results.forEach((page) => {
  page.blocks?.forEach((block) => {
    if (block.confidence && block.confidence > 0.8) {
      console.log('High confidence:', block.text);
    } else {
      console.log('Low confidence:', block.text);
    }
  });
});
```

---

## Error Handling

The library throws errors for common failure cases:

```typescript
try {
  const results = await scanDocuments();
} catch (error) {
  if (error.message.includes('cancelled')) {
    console.log('User cancelled scanning');
  } else if (error.message.includes('unavailable')) {
    console.log('Scanner not available on this device');
  } else {
    console.error('Unexpected error:', error);
  }
}
```

---

## Example App

The repository includes a fully-featured example app:

```sh
cd example
yarn install
cd ios && pod install && cd ..
yarn ios
# or
yarn android
```

---

## Requirements

- React Native 0.76+ (New Architecture required)
- iOS 13.0+ (VisionKit)
- Android API 21+ (ML Kit)

---

## License

MIT
