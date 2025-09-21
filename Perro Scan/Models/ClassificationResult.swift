//
//  ClassificationResult.swift
//  PerroScan
//

import UIKit
import Charts

struct ClassificationResult {
    let prediction: String
    let confidence: Float
    let probabilities: [String: Double]
    let userImage: UIImage?
    let sampleImage: UIImage?
    
    var isEmpty: Bool {
        return prediction.isEmpty
    }
    
    var topFive: [ChartSlice] {
        let sortedProbabilities = probabilities.sorted { $0.value > $1.value }
        return sortedProbabilities.prefix(5).enumerated().map { index, pair in
            ChartSlice(label: pair.key, value: Double(pair.value), isTop: index == 0)
        }
    }
    
    var topFiveWithOther: [ChartSlice] {
        let sortedProbabilities = probabilities.sorted { $0.value > $1.value }
        let topFive = sortedProbabilities.prefix(5)
        let remainingSum = sortedProbabilities.dropFirst(5).reduce(0) { $0 + $1.value }
        
        var result = topFive.enumerated().map { index, pair in
            ChartSlice(label: pair.key, value: Double(pair.value), isTop: index == 0)
        }
        
        if remainingSum > 0 {
            result.append(ChartSlice(label: "Other", value: Double(remainingSum), isTop: false))
        }
        
        return result
    }
    
    // NEW: All probabilities for bar chart
    var allProbabilities: [ChartSlice] {
        let sortedProbabilities = probabilities.sorted { $0.value > $1.value }
        return sortedProbabilities.enumerated().map { index, pair in
            ChartSlice(label: pair.key, value: Double(pair.value), isTop: index == 0)
        }
    }
}

struct ChartSlice: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    let isTop: Bool
}

