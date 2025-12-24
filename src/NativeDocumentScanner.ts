import { TurboModuleRegistry, type TurboModule } from 'react-native';

/**
 * Represents a discrete block of text recognized by the OCR engine.
 * Useful for mapping text to specific regions on the image.
 */
export interface TextBlock {
  /** The text content within the block. */
  text: string;
  /**
   * The normalized bounding box of the text.
   * Coordinates (x, y, width, height) are in the range [0, 1].
   * (0,0) is usually top-left.
   */
  frame: { x: number; y: number; width: number; height: number };
  /**
   * OCR confidence score (0.0 to 1.0).
   * Higher values indicate more reliable recognition.
   * Useful for LLM post-processing to weight or filter results.
   */
  confidence?: number;
}

/**
 * The result of a single scanned page.
 */
export interface ScanResult {
  /** The local file URI of the scanned image (e.g., file:///...). */
  uri?: string;
  /** The Base64 encoded string of the image (if requested). */
  base64?: string;
  /** The full text extracted from the page, preserving layout. */
  text?: string;
  /** Array of structured text blocks with metadata. */
  blocks?: TextBlock[];
}

/**
 * Base configuration options shared by scan and process operations.
 */
export interface BaseOptions {
  /** Compression quality (0.0 to 1.0) for JPEG. Default is 1.0. */
  quality?: number;
  /** Output image format. Default is 'jpg'. */
  format?: 'png' | 'jpg';
  /**
   * Post-processing filter to apply.
   * - `color`: No filter (default).
   * - `grayscale`: Desaturates the image.
   * - `monochrome`: High-contrast black & white (best for OCR).
   * - `denoise`: Reduces image noise (improves OCR on noisy photos).
   * - `sharpen`: Enhances edge clarity (improves OCR on blurry text).
   */
  filter?: 'color' | 'grayscale' | 'monochrome' | 'denoise' | 'sharpen';
  /** Whether to include the base64 string in the result. Default is false. */
  includeBase64?: boolean;
  /** Whether to perform OCR and include text/blocks. */
  includeText?: boolean;
}

/**
 * Configuration options for the Document Scanner.
 */
export interface ScanOptions extends BaseOptions {
  /** Maximum number of pages to scan. Default is unlimited (or hardware limit). */
  maxPageCount?: number;
}

/**
 * Configuration options for processing existing images.
 */
export interface ProcessOptions extends BaseOptions {
  /**
   * Array of image sources. Each can be:
   * - A file URI (e.g., "file:///path/to/image.jpg")
   * - A base64-encoded string (with or without data URI prefix)
   */
  images: string[];
}

/**
 * TurboModule Specification for the Document Scanner.
 */
export interface Spec extends TurboModule {
  /**
   * Opens the native document scanner UI.
   * @param options Configuration options.
   * @returns A Promise resolving to an array of ScanResults.
   */
  scanDocuments(options?: ScanOptions): Promise<ScanResult[]>;

  /**
   * Processes existing images without opening the camera UI.
   * @param options Configuration including image sources.
   * @returns A Promise resolving to an array of ScanResults.
   */
  processDocuments(options: ProcessOptions): Promise<ScanResult[]>;
}

export default TurboModuleRegistry.getEnforcing<Spec>('DocumentScanner');
