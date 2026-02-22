import Foundation
import Vision
import UIKit

/**
 A robust utility class for performing Optical Character Recognition (OCR)
 using Apple's Vision framework.

 Acts as a Facade delegating to versioned implementations:
 - TextRecognizerV1 (Raw)
 - TextRecognizerV2 (Heuristic, or native document understanding on iOS 26+)
 */
@available(iOS 13.0, *)
public class TextRecognizer {

  /**
   Extracts text from an image using Apple's Vision Framework.

   - Parameter image: `UIImage` object to process.
   - Parameter version: OCR engine version (1 = Raw, 2 = Heuristic).
   - Returns: A tuple containing the structured text and raw blocks.
   */
  public static func recognizeText(from image: UIImage, version: Int = 2) async -> (text: String, blocks: [TextBlock])? {

      guard let cgImage = image.cgImage else {
        Logger.warn("Could not retrieve CGImage from input.")
        return nil
      }

      /* iOS 26+: Use RecognizeDocumentsRequest for V2 — native document structure, no heuristics needed */
      if version == 2, #available(iOS 26.0, *) {
          return await recognizeWithDocumentRequest(cgImage: cgImage)
      }

      /* Configure the Vision Request */
      let request = VNRecognizeTextRequest()
      request.recognitionLevel = .accurate

      /*
       V1 (Raw) uses standard language correction for general text.
       V2 (Heuristic) disables it to preserve document layout and prevent over-merging.
       */
      request.usesLanguageCorrection = (version == 1)

      /* Filter out noise and tiny text artifacts */
      request.minimumTextHeight = 0.01

      /* Enable automatic language detection for multilingual documents (iOS 16+) */
      if #available(iOS 16.0, *) {
          request.automaticallyDetectsLanguage = true
      }

      let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

      do {
        /* Perform text recognition — blocking CPU-bound call, safe on background task */
        try handler.perform([request])

        guard let observations = request.results else {
          Logger.info("No text found in image.")
          return nil
        }

        if version == 1 {
            return TextRecognizerV1.recognize(observations)
        } else {
            return TextRecognizerV2.recognize(observations)
        }

      } catch {
        Logger.error("Text recognition request failed: \(error.localizedDescription)")
        return nil
      }
  }

  /**
   Returns the name of the OCR engine that will be used for the given version on the current OS.
   Used by ImageProcessor to populate ScanResult metadata.
   */
  public static func engineName(for version: Int) -> String {
      if version == 2, #available(iOS 26.0, *) {
          return "RecognizeDocumentsRequest"
      }
      return "VNRecognizeTextRequest"
  }

  /**
   iOS 26+ fast path using RecognizeDocumentsRequest.
   Returns native document structure (paragraphs) mapped to the same
   (text, blocks) format used by the heuristic path, so callers see no difference.
   One block per paragraph — for structured documents each paragraph is typically one visual line.
   */
  @available(iOS 26.0, *)
  private static func recognizeWithDocumentRequest(cgImage: CGImage) async -> (text: String, blocks: [TextBlock])? {
      do {
          let request = RecognizeDocumentsRequest()
          let observations = try await request.perform(on: cgImage)

          guard let document = observations.first?.document else {
              Logger.info("No document structure found in image.")
              return nil
          }

          var lines: [String] = []
          var blocks: [TextBlock] = []

          for paragraph in document.paragraphs {
              let paragraphText = paragraph.transcript
              lines.append(paragraphText)

              /* Map bounding region to normalised top-left origin coordinates.
                 boundingRegion is NormalizedRegion (Contour) → .boundingBox gives NormalizedRect → .cgRect gives CGRect.
                 Vision uses bottom-left origin — convert to top-left: 1 - y - height */
              let box = paragraph.boundingRegion.boundingBox.cgRect
              let androidStyleY = 1.0 - box.origin.y - box.size.height
              let frame = Frame(
                  x: Double(box.origin.x),
                  y: Double(androidStyleY),
                  width: Double(box.size.width),
                  height: Double(box.size.height)
              )

              blocks.append(TextBlock(text: paragraphText, frame: frame, confidence: nil))
          }

          let text = lines.isEmpty ? "" : lines.joined(separator: "\n") + "\n"
          return (text: text, blocks: blocks)

      } catch {
          Logger.error("RecognizeDocumentsRequest failed: \(error.localizedDescription)")
          return nil
      }
  }
}
