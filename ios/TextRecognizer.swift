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
        /* Step 2: Layout Preservation Heuristic */
        /* Reconstruct spatial layout by bunching text into lines and spacing columns. */
        /* ------------------------------------------------------------- */
        
        /* Sort by Y descending. In Vision, (0,0) is bottom-left, so higher Y means higher up on the page. */
        /* We want to process top-lines first. */
        let sortedObservations = observations.sorted { $0.boundingBox.origin.y > $1.boundingBox.origin.y }
        
        var lines: [[VNRecognizedTextObservation]] = []
        
        for obs in sortedObservations {
            var added = false
            /* Iterate existing lines to find a vertical match */
            for i in 0..<lines.count {
                if let ref = lines[i].first {
                    /* Calculate vertical centers */
                    let center1 = ref.boundingBox.origin.y + ref.boundingBox.height / 2
                    let center2 = obs.boundingBox.origin.y + obs.boundingBox.height / 2
                    let heightAvg = (ref.boundingBox.height + obs.boundingBox.height) / 2
                    
                    /* HEURISTIC: If centers are within threshold, consider them the same line. */
                    if abs(center1 - center2) < heightAvg / OCRConfiguration.verticalMergeDivisor {
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
        /* Step 3: Column Reconstruction */
        /* Sort each line horizontally and insert spacing. */
        /* ------------------------------------------------------------- */
        var structuredText = ""
        
        for var line in lines {
            /* Sort line elements left-to-right (X ascending) */
            line.sort { $0.boundingBox.origin.x < $1.boundingBox.origin.x }
            
            var lineString = ""
            var lastXEnd: CGFloat = 0.0
            
            for obs in line {
                guard let candidate = obs.topCandidates(1).first else { continue }
                let string = candidate.string
                let xStart = obs.boundingBox.origin.x
                
                /* Calculate gap between previous word end and current word start */
                let gap = xStart - lastXEnd
                
                /* HEURISTIC: If gap > threshold, insert proportional spaces. */
                /* This mimics "tab" stops in a plain text format. */
                if gap > OCRConfiguration.horizontalSpacingThreshold && !lineString.isEmpty {
                     /* Scale factor converts normalized width to character spaces */
                     let spaces = max(1, Int(gap * OCRConfiguration.spaceScalingFactor))
                     let cap = OCRConfiguration.maxSpaces
                     lineString += String(repeating: " ", count: min(spaces, cap))
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
