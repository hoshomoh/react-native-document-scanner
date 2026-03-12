import { TurboModuleRegistry, type TurboModule } from 'react-native';

/** Available image filters for post-processing. */
export enum FilterType {
  /** No filter (original colors). Default. */
  COLOR = 'color',
  /** Desaturates the image. */
  GRAYSCALE = 'grayscale',
  /** High-contrast black & white (best for OCR). */
  MONOCHROME = 'monochrome',
  /** Reduces image noise (improves OCR on noisy photos). */
  DENOISE = 'denoise',
  /** Enhances edge clarity (improves OCR on blurry text). */
  SHARPEN = 'sharpen',
  /** Full pipeline: denoise → sharpen → monochrome (best OCR accuracy). */
  OCR_OPTIMIZED = 'ocrOptimized',
}

/** Available output image formats. */
export enum FormatType {
  /** JPEG format (smaller file size). Default. */
  JPG = 'jpg',
  /** PNG format (lossless). */
  PNG = 'png',
}

/** Platform that generated a ScanResult. */
export enum Platform {
  IOS = 'ios',
  ANDROID = 'android',
}

/** OCR engine used to produce a ScanResult. */
export enum OcrEngine {
  /** iOS 26+ native document understanding (V2). */
  RECOGNIZE_DOCUMENTS_REQUEST = 'RecognizeDocumentsRequest',
  /** Apple Vision text request (V1 or V2 on iOS < 26). */
  VN_RECOGNIZE_TEXT_REQUEST = 'VNRecognizeTextRequest',
  /** Android ML Kit Text Recognition (V1 or V2). */
  ML_KIT = 'MLKit',
  /** OCR was not performed (`includeText` was false). */
  NONE = 'none',
}

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
 * Describes the OCR engine and configuration used to produce a ScanResult.
 * Pass the parent `ScanResult` directly to `reconstructText` — it reads
 * `metadata` internally to select the right reconstruction strategy.
 */
export interface ScanMetadata {
  /** Platform that generated this result. */
  platform: Platform;
  /** OCR engine version that was requested (1 = Raw, 2 = Heuristic). */
  textVersion: number;
  /** Image filter applied before OCR. */
  filter: FilterType;
  /** The specific OCR engine used. */
  ocrEngine: OcrEngine;
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
  /** Configuration and engine metadata for this result. */
  metadata?: ScanMetadata;
}

/**
 * Base configuration options shared by scan and process operations.
 */
export interface BaseOptions {
  /** Compression quality (0.0 to 1.0) for JPEG. Default is 1.0. */
  quality?: number;
  /** Output image format. Use the `Format` constant for type-safe values. Default is 'jpg'. */
  format?: FormatType;
  /**
   * Post-processing filter to apply.
   * - `color`: No filter (default).
   * - `grayscale`: Desaturates the image.
   * - `monochrome`: High-contrast black & white (best for OCR).
   * - `denoise`: Reduces image noise (improves OCR on noisy photos).
   * - `sharpen`: Enhances edge clarity (improves OCR on blurry text).
   * - `ocrOptimized`: Full pipeline: denoise → sharpen → monochrome (best accuracy).
   */
  filter?: FilterType;
  /** Whether to include the base64 string in the result. Default is false. */
  includeBase64?: boolean;
  /** Whether to perform OCR and include text/blocks. */
  includeText?: boolean;
  /**
   * Version of the text recognizer to use.
   * - 1: Raw output (standard Vision/ML Kit behavior).
   * - 2: Heuristic enhanced (Adaptive Clustering for layout preservation). Default.
   */
  textVersion?: number;
}

/**
 * Configuration options for the Document Scanner.
 * Fields are listed explicitly (not via extends) for React Native Codegen compatibility —
 * Codegen only generates struct fields declared directly on the interface.
 */
export interface ScanOptions {
  /** Maximum number of pages to scan. Default is unlimited (or hardware limit). */
  maxPageCount?: number;
  /** Compression quality (0.0 to 1.0) for JPEG. Default is 1.0. */
  quality?: number;
  /** Output image format. Default is FormatType.JPG. */
  format?: FormatType;
  /** Post-processing filter. Default is FilterType.COLOR. */
  filter?: FilterType;
  /** Whether to include the base64 string in the result. Default is false. */
  includeBase64?: boolean;
  /** Whether to perform OCR and include text/blocks. */
  includeText?: boolean;
  /**
   * Version of the text recognizer to use.
   * - 1: Raw output (standard Vision/ML Kit behavior).
   * - 2: Heuristic enhanced (Adaptive Clustering for layout preservation). Default.
   */
  textVersion?: number;
}

/**
 * Configuration options for processing existing images.
 * Fields are listed explicitly (not via extends) for React Native Codegen compatibility —
 * Codegen only generates struct fields declared directly on the interface.
 */
export interface ProcessOptions {
  /**
   * Array of image sources. Each can be:
   * - A file URI (e.g., "file:///path/to/image.jpg")
   * - A base64-encoded string (with or without data URI prefix)
   */
  images: string[];
  /** Compression quality (0.0 to 1.0) for JPEG. Default is 1.0. */
  quality?: number;
  /** Output image format. Default is FormatType.JPG. */
  format?: FormatType;
  /** Post-processing filter. Default is FilterType.COLOR. */
  filter?: FilterType;
  /** Whether to include the base64 string in the result. Default is false. */
  includeBase64?: boolean;
  /** Whether to perform OCR and include text/blocks. */
  includeText?: boolean;
  /**
   * Version of the text recognizer to use.
   * - 1: Raw output (standard Vision/ML Kit behavior).
   * - 2: Heuristic enhanced (Adaptive Clustering for layout preservation). Default.
   */
  textVersion?: number;
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
