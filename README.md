# react-native-document-scanner

A React Native library for scanning documents using VisionKit

## Installation

```sh
yarn add @hoshomoh/react-native-document-scanner
# or
npm i @hoshomoh/react-native-document-scanner
```

## Usage

```typescript
import { scanDocuments } from '@hoshomoh/react-native-document-scanner';

// ...

try {
  const uris = await scanDocuments({
    maxPageCount: 5,
    quality: 0.9,
    format: 'jpg',
  });
  console.log('Scanned documents:', uris);
} catch (error) {
  console.error('Scanning failed:', error);
}
```

### Options

| Name           | Type             | Description                                                                  |
| -------------- | ---------------- | ---------------------------------------------------------------------------- |
| `maxPageCount` | `number`         | Maximum number of pages to return. Default: unlimited (or VisionKit default) |
| `quality`      | `number`         | Image compression quality (0.0 - 1.0). Default: 1.0                          |
| `format`       | `'png' \| 'jpg'` | Output image format. Default: 'jpg'                                          |
