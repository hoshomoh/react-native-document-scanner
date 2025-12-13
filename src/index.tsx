import DocumentScanner, {
  type ScanOptions,
  type ScanResult,
  type TextBlock,
  type ProcessOptions,
} from './NativeDocumentScanner';

export function scanDocuments(options?: ScanOptions): Promise<ScanResult[]> {
  return DocumentScanner.scanDocuments(options);
}

export function processDocuments(
  options: ProcessOptions
): Promise<ScanResult[]> {
  return DocumentScanner.processDocuments(options);
}

export type { ScanOptions, ScanResult, TextBlock, ProcessOptions };
