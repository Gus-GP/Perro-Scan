//
//  ClassificationViewModel.swift
//  PerroScan
//

import SwiftUI
import UIKit
import Combine

@MainActor
class ClassificationViewModel: ObservableObject {
    @Published var result = ClassificationResult(
        prediction: "",
        confidence: 0,
        probabilities: [:],
        userImage: nil,
        sampleImage: nil
    )
    
    @Published var isLoading = false
    @Published var loadingMessage = "Running AI model..."
    
    private let classificationService = DogBreedClassificationService()
    private let minimumLoadingDuration: TimeInterval = 2.0 // 2 seconds minimum
    
    // Computed property to check if we have results
    var hasResults: Bool {
        !result.isEmpty && !isLoading
    }
    
    var predictedBreed: DogBreed? {
        guard !result.prediction.isEmpty else { return nil }
        return DogBreedStore.getBreed(named: result.prediction)
    }
    
    func classifyImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        
        // Start loading
        isLoading = true
        loadingMessage = "Running AI model..."
        let startTime = Date()
        
        // Clear previous results
        result = ClassificationResult(
            prediction: "",
            confidence: 0,
            probabilities: [:],
            userImage: image,
            sampleImage: nil
        )
        
        classificationService.classify(cgImage: cgImage) { [weak self] prediction, confidence, probabilities in
            guard let self = self else { return }
            
            self.result = ClassificationResult(
                prediction: prediction,
                confidence: confidence,
                probabilities: probabilities,
                userImage: image,
                sampleImage: nil
            )
            
            Task {
                // Load sample image
                let sampleImage = await self.classificationService.loadSampleImage(for: prediction)
                
                await MainActor.run {
                    self.result = ClassificationResult(
                        prediction: self.result.prediction,
                        confidence: self.result.confidence,
                        probabilities: self.result.probabilities,
                        userImage: self.result.userImage,
                        sampleImage: sampleImage
                    )
                }
                
                // Enforce minimum duration
                let elapsedTime = Date().timeIntervalSince(startTime)
                let remainingTime = max(0, self.minimumLoadingDuration - elapsedTime)
                
                if remainingTime > 0 {
                    // Keep the same message during the wait
                    try? await Task.sleep(nanoseconds: UInt64(remainingTime * 1_000_000_000))
                }
                
                // End loading
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    // Reset function to clear all results
    func reset() {
        withAnimation(.easeInOut(duration: 0.5)) {
            result = ClassificationResult(
                prediction: "",
                confidence: 0,
                probabilities: [:],
                userImage: nil,
                sampleImage: nil
            )
            isLoading = false
            loadingMessage = "Running AI model..."
        }
    }
}

