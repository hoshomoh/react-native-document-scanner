import Foundation
import Vision
import UIKit

/**
 Version 2: Heuristic Enhanced (Line Clustering for Layout Preservation)
 */
@available(iOS 13.0, *)
public class TextRecognizerV2 {
    
    public static func recognize(_ observations: [VNRecognizedTextObservation]) -> (text: String, blocks: [TextBlock]) {
        
        /* 1. Extract Metadata (Blocks) */
        let blocks = observations.compactMap { obs -> TextBlock? in
            guard let candidate = obs.topCandidates(1).first else { return nil }

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

            return TextBlock(text: candidate.string, frame: frame, confidence: Double(candidate.confidence))
        }

        /* 2. LineCluster Strategy */
        struct LineCluster {
            var observations: [VNRecognizedTextObservation]
            var unionBoundingBox: CGRect
            var heights: [CGFloat]

            var medianHeight: CGFloat {
                let sorted = heights.sorted()
                if sorted.isEmpty { return 0 }
                let mid = sorted.count / 2
                if sorted.count % 2 == 0 {
                    return (sorted[mid - 1] + sorted[mid]) / 2.0
                } else {
                    return sorted[mid]
                }
            }
        }

        /* 
         Sort observations top-to-bottom for clustering.
         Smaller Y values are higher on the page in our converted coordinate space.
         However, the clustering loop below uses the RAW observations.boundingBox.
         In RAW Vision space, higher on page means BIGGER Y.
         We will keep the internal clustering on RAW Vision coordinates (midY > midY)
         but ensure the FINAL blocks and structured text are correctly sorted.
         */
        let sortedObservations = observations.sorted { $0.boundingBox.midY > $1.boundingBox.midY }
        var clusters: [LineCluster] = []

        for obs in sortedObservations {
            let obsBox = obs.boundingBox
            let obsHeight = obsBox.height
            let obsCenterY = obsBox.midY

            var bestClusterIndex: Int? = nil
            var bestOverlapRatio: CGFloat = 0.0
            var bestCenterDistance: CGFloat = .greatestFiniteMagnitude

            for (index, cluster) in clusters.enumerated() {
                let clusterBox = cluster.unionBoundingBox
                
                /* Heuristic: Height Compatibility */
                let minH = min(clusterBox.height, obsHeight)
                let maxH = max(clusterBox.height, obsHeight)
                if (minH / maxH) < OCRConfiguration.heightCompatibilityThreshold { continue }
                
                /* Heuristic: Overlap & Centerline */
                let intersection = clusterBox.intersection(obsBox)
                let overlapHeight = max(0, intersection.height)
                let overlapRatio = overlapHeight / minH
                
                let centerDistance = abs(clusterBox.midY - obsCenterY)
                let typicalLineHeight = max(cluster.medianHeight, obsHeight)
                
                let isOverlapGood = overlapRatio >= OCRConfiguration.overlapRatioThreshold
                let isCenterClose = centerDistance <= (OCRConfiguration.centerlineDistanceFactor * typicalLineHeight)
                
                if (isOverlapGood || isCenterClose) {
                    /* Heuristic: Adaptive Cluster Growth Constraint */
                    let intersectX = max(0, min(clusterBox.maxX, obsBox.maxX) - max(clusterBox.minX, obsBox.minX))
                    let isStacked = intersectX > 0
                    
                    let growthLimit = isStacked ? OCRConfiguration.stackedGrowthLimit : OCRConfiguration.skewedGrowthLimit
                    
                     let newUnion = clusterBox.union(obsBox)
                     if newUnion.height <= (CGFloat(growthLimit) * typicalLineHeight) {
                         /* Score this cluster */
                         if overlapRatio > bestOverlapRatio {
                             bestOverlapRatio = overlapRatio
                             bestCenterDistance = centerDistance
                             bestClusterIndex = index
                         } else if abs(overlapRatio - bestOverlapRatio) < 0.01 && centerDistance < bestCenterDistance {
                             bestCenterDistance = centerDistance
                             bestClusterIndex = index
                         }
                     }
                }
            }

            if let idx = bestClusterIndex {
                clusters[idx].observations.append(obs)
                clusters[idx].unionBoundingBox = clusters[idx].unionBoundingBox.union(obsBox)
                clusters[idx].heights.append(obsHeight)
            } else {
                clusters.append(LineCluster(
                    observations: [obs],
                    unionBoundingBox: obsBox,
                    heights: [obsHeight]
                ))
            }
        }
        
        /* 
         Sort clusters top-to-bottom for final output.
         In RAW Vision space (used in unionBoundingBox), higher on page means BIGGER Y.
         */
        clusters.sort { $0.unionBoundingBox.midY > $1.unionBoundingBox.midY }

        /* 3. Column Reconstruction (Adaptive Spacing) */
        var structuredText = ""

        for cluster in clusters {
            /* Sort line elements left-to-right */
            let lineObs = cluster.observations.sorted { $0.boundingBox.origin.x < $1.boundingBox.origin.x }
            let medianH = cluster.medianHeight

            var lineString = ""
            var lastXEnd: CGFloat = 0.0

            for (index, obs) in lineObs.enumerated() {
                guard let candidate = obs.topCandidates(1).first else { continue }
                let string = candidate.string
                let xStart = obs.boundingBox.origin.x

                if index > 0 {
                    let gap = xStart - lastXEnd
                    /* Spacing Heuristic */
                    if gap > (medianH * CGFloat(OCRConfiguration.adaptiveSpacingFactor)) {
                        let spaceWidth = medianH * CGFloat(OCRConfiguration.spaceWidthFactor)
                        let spaces = max(1, Int(gap / spaceWidth))
                        let cap = OCRConfiguration.maxSpaces
                        lineString += String(repeating: " ", count: min(spaces, cap))
                    } else if gap > 0 {
                        lineString += " "
                    }
                }

                lineString += string
                lastXEnd = xStart + obs.boundingBox.width
            }
            structuredText += lineString + "\n"
        }

        /* 
         Final Sort for Blocks:
         Ensure metadata blocks are also returned in top-to-bottom reading order.
         Since these were already converted to top-left origin, smaller Y is higher.
         */
        let sortedBlocks = blocks.sorted { $0.frame.y < $1.frame.y }

        return (text: structuredText, blocks: sortedBlocks)
    }
}
