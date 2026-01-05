import Foundation
import Vision

/**
 Version 1: Raw Output (Standard Vision Behavior)
 */
@available(iOS 13.0, *)
public class TextRecognizerV1 {
    
    /**
     Performs raw text recognition from Vision observations.
     - Parameter observations: Raw results from VNRecognizeTextRequest.
     - Returns: Concatenated text and structured blocks.
     */
    public static func recognize(_ observations: [VNRecognizedTextObservation]) -> (text: String, blocks: [TextBlock]) {
        var fullText = ""
        
        var blocks: [TextBlock] = []

        for obs in observations {
            guard let candidate = obs.topCandidates(1).first else { continue }
            
            let box = obs.boundingBox
            
            /* 
             Vision uses bottom-left origin. 
             Convert to Android-style top-left origin: 1.0 - y - height 
             */
            let androidStyleY = 1.0 - box.origin.y - box.size.height
            
            let frame = Frame(
                x: box.origin.x,
                y: androidStyleY,
                width: box.size.width,
                height: box.size.height
            )
            
            blocks.append(TextBlock(
                text: candidate.string,
                frame: frame,
                confidence: Double(candidate.confidence)
            ))
        }
        
        /* 
         Sort top-to-bottom using the converted Y (top-left origin).
         Smaller Y values are higher on the page.
         */
        let sortedBlocks = blocks.sorted { $0.frame.y < $1.frame.y }
        
        /* Concatenate text based on reading order sort */
        fullText = sortedBlocks.map { $0.text }.joined(separator: "\n")
        
        return (text: fullText, blocks: sortedBlocks)
    }
}
