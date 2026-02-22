import Foundation
import Vision
import UIKit

/**
 Version 2: Heuristic Enhanced (Line Clustering for Layout Preservation)
 */
@available(iOS 13.0, *)
public class TextRecognizerV2 {

    public static func recognize(_ observations: [VNRecognizedTextObservation]) -> (text: String, blocks: [TextBlock]) {

        /* 1. LineCluster Strategy */
        struct LineCluster {
            var observations: [VNRecognizedTextObservation]
            var unionBoundingBox: CGRect
            var heights: [CGFloat]
            var centerYs: [CGFloat]

            var medianHeight: CGFloat {
                let sorted = heights.sorted()
                if sorted.isEmpty { return 0 }
                let mid = sorted.count / 2
                return sorted.count % 2 == 0
                    ? (sorted[mid - 1] + sorted[mid]) / 2.0
                    : sorted[mid]
            }

            var medianCenterY: CGFloat {
                let sorted = centerYs.sorted()
                if sorted.isEmpty { return 0 }
                let mid = sorted.count / 2
                return sorted.count % 2 == 0
                    ? (sorted[mid - 1] + sorted[mid]) / 2.0
                    : sorted[mid]
            }
        }

        /*
         Sort observations top-to-bottom for clustering.
         In RAW Vision space, higher on page means BIGGER Y.
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

                /* Heuristic: Height Compatibility — use median height, not union bbox height */
                let minH = min(cluster.medianHeight, obsHeight)
                let maxH = max(cluster.medianHeight, obsHeight)
                if (minH / maxH) < OCRConfiguration.heightCompatibilityThreshold { continue }

                /* Heuristic: Overlap & Centerline — use median centerY, not union bbox midY */
                let intersection = clusterBox.intersection(obsBox)
                let overlapHeight = max(0, intersection.height)
                let overlapRatio = overlapHeight / minH

                let centerDistance = abs(cluster.medianCenterY - obsCenterY)
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
                clusters[idx].centerYs.append(obsCenterY)
            } else {
                clusters.append(LineCluster(
                    observations: [obs],
                    unionBoundingBox: obsBox,
                    heights: [obsHeight],
                    centerYs: [obsCenterY]
                ))
            }
        }

        /*
         Sort clusters top-to-bottom for final output.
         In RAW Vision space, higher on page means BIGGER Y.
         */
        clusters.sort { $0.unionBoundingBox.midY > $1.unionBoundingBox.midY }

        /* 2. Column Reconstruction (Adaptive Spacing) + Cluster-Based Blocks */
        var structuredText = ""
        var clusterBlocks: [TextBlock] = []

        for cluster in clusters {
            /* Sort line elements left-to-right */
            let lineObs = cluster.observations.sorted { $0.boundingBox.origin.x < $1.boundingBox.origin.x }
            let medianH = cluster.medianHeight

            var lineString = ""
            var lastXEnd: CGFloat = 0.0

            for (index, obs) in lineObs.enumerated() {
                guard let candidate = obs.topCandidates(1).first else { continue }
                let xStart = obs.boundingBox.origin.x

                if index > 0 {
                    let gap = xStart - lastXEnd
                    /* Spacing Heuristic */
                    if gap > (medianH * CGFloat(OCRConfiguration.adaptiveSpacingFactor)) {
                        let spaceWidth = medianH * CGFloat(OCRConfiguration.spaceWidthFactor)
                        let spaces = max(1, Int(gap / spaceWidth))
                        lineString += String(repeating: " ", count: min(spaces, OCRConfiguration.maxSpaces))
                    } else {
                        lineString += " "
                    }
                }

                lineString += candidate.string
                lastXEnd = xStart + obs.boundingBox.width
            }

            structuredText += lineString + "\n"

            /* Build one block per cluster (line-level, aligned with text output) */
            let unionBox = cluster.unionBoundingBox
            let androidStyleY = 1.0 - unionBox.origin.y - unionBox.size.height
            let frame = Frame(
                x: Double(unionBox.origin.x),
                y: Double(androidStyleY),
                width: Double(unionBox.size.width),
                height: Double(unionBox.size.height)
            )
            let confidences = cluster.observations.compactMap { obs -> Double? in
                obs.topCandidates(1).first.map { Double($0.confidence) }
            }
            let avgConfidence = confidences.isEmpty ? nil : confidences.reduce(0.0, +) / Double(confidences.count)
            clusterBlocks.append(TextBlock(text: lineString, frame: frame, confidence: avgConfidence))
        }

        return (text: structuredText, blocks: clusterBlocks)
    }
}
