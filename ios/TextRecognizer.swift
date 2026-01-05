import Foundation
import Vision
import UIKit

/**
 A robust utility class for performing Optical Character Recognition (OCR)
 using Apple's Vision framework.

 Acts as a Facade delegating to versioned implementations:
 - TextRecognizerV1 (Raw)
 - TextRecognizerV2 (Heuristic)
 */
@available(iOS 13.0, *)
public class TextRecognizer {

  /**
   Extracts text from an image using Apple's Vision Framework.

   - Parameter image: `UIImage` object to process.
   - Parameter version: OCR engine version (1 = Raw, 2 = Heuristic).
   - Returns: A tuple containing the structured text and raw blocks.
   */
  public static func recognizeText(from image: UIImage, version: Int = 2) -> (text: String, blocks: [TextBlock])? {

      /* Ensure valid image data is available */
      guard let cgImage = image.cgImage else {
        Logger.warn("Could not retrieve CGImage from input.")
        return nil
      }

      /* Configure the Vision Request */
      let request = VNRecognizeTextRequest()
      request.recognitionLevel = .accurate

      /*
       V1 (Raw) uses standard language correction for general text.
       V2 (Heuristic) disables it to preserve document layout and prevent over-merging.
       */
      request.usesLanguageCorrection = (version == 1)

      /* Create the request handler */
      let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

      do {
        /* Perform text recognition (blocking) */
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
}
