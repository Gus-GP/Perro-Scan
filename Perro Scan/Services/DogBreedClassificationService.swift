//
//  DogBreedClassificationService.swift
//  Perro Scan
//
//  Created by Gustavo Grinsteins on 9/19/25.
//

//
//  DogBreedClassificationService.swift
//  PerroScan
//

import Vision
import CoreML
import UIKit



class DogBreedClassificationService {
    
    private lazy var coreMLRequest: VNCoreMLRequest = {
        do {
            let coreMLModel = try DogBreedClassifier_4bit_Quantized_iOS18(configuration: MLModelConfiguration()).model
            let vnModel = try VNCoreMLModel(for: coreMLModel)
            let request = VNCoreMLRequest(model: vnModel) { [weak self] request, _ in
                self?.processResults(request)
            }
            request.imageCropAndScaleOption = .centerCrop
            return request
        } catch {
            fatalError("Model load failed: \(error)")
        }
    }()
    
    private var completionHandler: ((String, Float, [String: Double]) -> Void)?
    
    func classify(cgImage: CGImage, completion: @escaping (String, Float, [String: Double]) -> Void) {
        self.completionHandler = completion
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([coreMLRequest])
        } catch {
            print("Vision request failed: \(error)")
        }
    }
    
    private func processResults(_ request: VNRequest) {
        guard let results = request.results as? [VNClassificationObservation],
              let topResult = results.first else { return }
        
        let labels = results.map { $0.identifier }
        let scores = results.map { Double($0.confidence) }
        let maxScore = scores.max() ?? 0
        let exps = scores.map { exp($0 - maxScore) }
        let sumExp = exps.reduce(0, +)
        let probsArr = exps.map { $0 / max(sumExp, 1e-12) }
        
        var probabilities: [String: Double] = [:]
        for (i, label) in labels.enumerated() {
            probabilities[label] = probsArr[i]
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.completionHandler?(
                topResult.identifier,
                Float(probsArr.first ?? 0),
                probabilities
            )
        }
    }
    
    func loadSampleImage(for breed: String) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let searchKey = breed.replacingOccurrences(of: " ", with: "_")
                
                guard let resourceURL = Bundle.main.resourceURL,
                      let files = try? FileManager.default.contentsOfDirectory(at: resourceURL, includingPropertiesForKeys: nil) else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let imageFiles = files.filter { url in
                    let ext = url.pathExtension.lowercased()
                    let filename = url.lastPathComponent.lowercased()
                    return (ext == "heic") && filename.contains(searchKey.lowercased())
                }
                
                guard let randomImageURL = imageFiles.randomElement(),
                      let image = UIImage(contentsOfFile: randomImageURL.path) else {
                    continuation.resume(returning: nil)
                    return
                }
                
                continuation.resume(returning: image)
            }
        }
    }
}
