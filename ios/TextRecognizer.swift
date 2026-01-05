import Foundation
import Vision
import UIKit

/**
 A robust utility class for performing Optical Character Recognition (OCR)
 using Apple's Vision framework.

 This class handles:
 1. Text Recognition request configuration.
 2. Bounding box extraction/normalization.
 3. Heuristic layout preservation (grouping text into lines/columns).
 */
@available(iOS 13.0, *)
public class TextRecognizer {

  /**
   Extracts text from a list of images using Apple's Vision Framework.

   - Parameter images: Array of `UIImage` objects to process.
   - Returns: A tuple containing the structured text and raw blocks for the *first* image.
     (Currently optimized for single page processing within the loop).
     Returns nil if recognition fails.
   */
  public static func recognizeText(from image: UIImage) -> (text: String, blocks: [TextBlock])? {

      /* guard statement ensures we don't process invalid image data */
      guard let cgImage = image.cgImage else {
        Logger.warn("Could not retrieve CGImage from input.")
        return nil
      }

      /* Configure the Vision Request */
      let request = VNRecognizeTextRequest()
      request.recognitionLevel = .accurate /* Prioritize accuracy over speed */
      request.usesLanguageCorrection = true /* Use coreml language models to correct typos */

      /* Create the request handler */
      let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

      do {
        /* Perform the request (synchronous) */
        try handler.perform([request])

        /* Validate results */
        guard let observations = request.results else {
          Logger.info("No text found in image.")
          return nil
        }

        /* ------------------------------------------------------------- */
        /* Step 1: Metadata Extraction */
        /* Extract raw bounding box data for downstream processing (e.g., LLMs). */
        /* ------------------------------------------------------------- */
        let blocks = observations.compactMap { obs -> TextBlock? in
            /* Get the top candidate string */
            guard let candidate = obs.topCandidates(1).first else { return nil }

            let frame = Frame(
                x: obs.boundingBox.origin.x,
                y: obs.boundingBox.origin.y,
                width: obs.boundingBox.size.width,
                height: obs.boundingBox.size.height
            )

            /* Extract confidence score (0.0 - 1.0) from the candidate */
            let confidence = Double(candidate.confidence)

            return TextBlock(text: candidate.string, frame: frame, confidence: confidence)
        }

        /* ------------------------------------------------------------- */
        /* Step 2: Layout Preservation Heuristic (Vertical Overlap) */
        /* ------------------------------------------------------------- */

        /* Sort by Y descending. Vision (0,0) is bottom-left. */
        let sortedObservations = observations.sorted { $0.boundingBox.origin.y > $1.boundingBox.origin.y }

        var lines: [[VNRecognizedTextObservation]] = []

        for obs in sortedObservations {
            var added = false
            /* Iterate existing lines to find a vertical match */
            for i in 0..<lines.count {
                if let ref = lines[i].first {
                    /*
                     * HEURISTIC: Vertical Overlap & Height Similarity
                     *
                     * Research: O'Gorman (1993) Docstrum & Breuel (2002).
                     * We use geometric clustering based on vertical overlap.
                     */

                    let y1_bottom = ref.boundingBox.origin.y
                    let y1_top = ref.boundingBox.origin.y + ref.boundingBox.height

                    let y2_bottom = obs.boundingBox.origin.y
                    let y2_top = obs.boundingBox.origin.y + obs.boundingBox.height

                    /* Calculate vertical intersection */
                    let intersectionBottom = max(y1_bottom, y2_bottom)
                    let intersectionTop = min(y1_top, y2_top)
                    let intersectionHeight = max(0, intersectionTop - intersectionBottom)

                    let minHeight = min(ref.boundingBox.height, obs.boundingBox.height)
                    let maxHeight = max(ref.boundingBox.height, obs.boundingBox.height)

                    /*
                     * Condition 1: Significant Vertical Overlap (> 50% of the smaller height)
                     * Ensures items are on the same "visual line".
                     */
                    let isVerticallyAligned = (intersectionHeight / minHeight) > 0.5

                    /*
                     * Condition 2: Height Similarity (> 50% ratio)
                     * Prevents merging distinct semantic references like small footer text with large headers.
                     */
                    let isSimilarHeight = (minHeight / maxHeight) > 0.5

                    if isVerticallyAligned && isSimilarHeight {
                        lines[i].append(obs)
                        added = true
                        break
                    }
                }
            }
            /* If no match found, start a new line */
            if !added {
                lines.append([obs])
            }
        }

        /* ------------------------------------------------------------- */
        /* Step 3: Column Reconstruction (Adaptive Spacing) */
        /* ------------------------------------------------------------- */
        var structuredText = ""

        for var line in lines {
            /* Sort line elements left-to-right (X ascending) */
            line.sort { $0.boundingBox.origin.x < $1.boundingBox.origin.x }

            /* Calculate average height of the line to determining spacing */
            let avgLineHeight = line.reduce(0.0) { $0 + $1.boundingBox.height } / CGFloat(line.count)

            var lineString = ""
            var lastXEnd: CGFloat = 0.0

            for (index, obs) in line.enumerated() {
                guard let candidate = obs.topCandidates(1).first else { continue }
                let string = candidate.string
                let xStart = obs.boundingBox.origin.x

                if index > 0 {
                    /* Calculate gap between previous word end and current word start */
                    let gap = xStart - lastXEnd

                    /*
                     * HEURISTIC: Adaptive Horizontal Spacing
                     * Research: Kshetry (2021) - Adaptive thresholding.
                     *
                     * Instead of fixed page width %, use line height as proxy for em-space.
                     * If gap > 0.5 * height, it's likely a visible space/column separation.
                     */
                    if gap > (avgLineHeight * 0.5) {
                         /*
                          * Scale spaces.
                          * We assume 1 "space" char is roughly 0.25-0.3 of height (narrow char).
                          * So spaces = gap / (height * 0.3) approx.
                          */
                         let estimatedSpaceWidth = avgLineHeight * 0.3
                         let spaces = max(1, Int(gap / estimatedSpaceWidth))
                         let cap = OCRConfiguration.maxSpaces
                         lineString += String(repeating: " ", count: min(spaces, cap))
                    } else if gap > 0 {
                        // Regular space between words if small positive gap
                        lineString += " "
                    }
                }

                lineString += string
                lastXEnd = xStart + obs.boundingBox.size.width
            }
            structuredText += lineString + "\n"
        }

        return (text: structuredText, blocks: blocks)
      } catch {
        Logger.error("Text recognition request failed: \(error.localizedDescription)")
        return nil
      }
  }
}
