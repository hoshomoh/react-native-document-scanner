import DocumentScanner, {
  type ScanOptions,
  type ScanResult,
  type ScanMetadata,
  type TextBlock,
  type ProcessOptions,
  FilterType,
  FormatType,
  Platform,
  OcrEngine,
} from './NativeDocumentScanner';

/**
 * Available image filters.
 * Use these constants instead of raw strings for type safety.
 */
export const Filter = {
  /** No filter (original colors) */
  COLOR: FilterType.COLOR,
  /** Desaturated image */
  GRAYSCALE: FilterType.GRAYSCALE,
  /** High-contrast black & white */
  MONOCHROME: FilterType.MONOCHROME,
  /** Noise reduction (for noisy photos) */
  DENOISE: FilterType.DENOISE,
  /** Edge enhancement (for blurry text) */
  SHARPEN: FilterType.SHARPEN,
  /** Full OCR pipeline: denoise → sharpen → monochrome */
  OCR_OPTIMIZED: FilterType.OCR_OPTIMIZED,
} as const;

/**
 * Available output formats.
 */
export const Format = {
  /** JPEG format (smaller file size) */
  JPG: FormatType.JPG,
  /** PNG format (lossless) */
  PNG: FormatType.PNG,
} as const;

export function scanDocuments(options?: ScanOptions): Promise<ScanResult[]> {
  return DocumentScanner.scanDocuments(options);
}

export function processDocuments(
  options: ProcessOptions
): Promise<ScanResult[]> {
  return DocumentScanner.processDocuments(options);
}

export { reconstructText } from './textReconstructor';
export type { ReconstructOptions } from './textReconstructor';

export type {
  ScanOptions,
  ScanResult,
  ScanMetadata,
  TextBlock,
  ProcessOptions,
};
export { FilterType, FormatType, Platform, OcrEngine };
