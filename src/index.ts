import DocumentScanner, {
  type ScanOptions,
  type ScanResult,
  type TextBlock,
  type ProcessOptions,
  type FilterType,
  type FormatType,
} from './NativeDocumentScanner';

/**
 * Available image filters.
 * Use these constants instead of raw strings for type safety.
 */
export const Filter = {
  /** No filter (original colors) */
  COLOR: 'color',
  /** Desaturated image */
  GRAYSCALE: 'grayscale',
  /** High-contrast black & white */
  MONOCHROME: 'monochrome',
  /** Noise reduction (for noisy photos) */
  DENOISE: 'denoise',
  /** Edge enhancement (for blurry text) */
  SHARPEN: 'sharpen',
  /** Full OCR pipeline: denoise → sharpen → monochrome */
  OCR_OPTIMIZED: 'ocrOptimized',
} as const;

/**
 * Available output formats.
 */
export const Format = {
  /** JPEG format (smaller file size) */
  JPG: 'jpg',
  /** PNG format (lossless) */
  PNG: 'png',
} as const;

export function scanDocuments(options?: ScanOptions): Promise<ScanResult[]> {
  return DocumentScanner.scanDocuments(options);
}

export function processDocuments(
  options: ProcessOptions
): Promise<ScanResult[]> {
  return DocumentScanner.processDocuments(options);
}

export type {
  ScanOptions,
  ScanResult,
  TextBlock,
  ProcessOptions,
  FilterType,
  FormatType,
};
