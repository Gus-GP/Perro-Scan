//
//  DogBreedDetailView.swift
//  PerroScan
//

import SwiftUI

struct DogBreedDetailView: View {
    let breed: DogBreed
    @State private var sampleImages: [UIImage] = []
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Multiline, large header title
                    Text(breed.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal)
                    
                    // Sample images section
                    if !sampleImages.isEmpty {
                        sampleImagesSection
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        // Breed classification section
                        breedClassificationSection
                        
                        Divider()
                        
                        // Overview section
                        overviewSection
                        
                        Divider()
                        
                        // Physical characteristics section
                        physicalCharacteristicsSection
                        
                        Divider()
                        
                        // Temperament section
                        temperamentSection
                        
                        Divider()
                        
                        // Care and maintenance section
                        careSection
                        
                        Divider()
                        
                        // Health section
                        healthSection
                        
                        Divider()
                        
                        // Training section
                        trainingSection
                        
                        Divider()
                        
                        // Living with breed section
                        livingSection
                        
                        Divider()
                        
                        // Interesting facts section
                        interestingFactsSection
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadSampleImages()
        }
    }
    
    private var breedClassificationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Breed Information")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 4) {
                InfoRow(label: "Group", value: breed.breedClassification.breedGroup)
                InfoRow(label: "Size", value: breed.breedClassification.sizeCategory)
                InfoRow(label: "Height", value: breed.breedClassification.typicalHeight)
                InfoRow(label: "Weight", value: breed.breedClassification.typicalWeight)
            }
        }
    }
    
    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Overview")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(breed.overviewAndIntroduction)
                .font(.body)
                .foregroundColor(.secondary)
                .lineSpacing(2)
        }
    }
    
    private var physicalCharacteristicsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Physical Characteristics")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(breed.physicalCharacteristics)
                .font(.body)
                .foregroundColor(.secondary)
                .lineSpacing(2)
        }
    }
    
    private var temperamentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Temperament & Personality")
                .font(.title2)
                .fontWeight(.bold)
            
            // Key traits display
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 100), spacing: 8)
            ], spacing: 8) {
                ForEach(breed.traits, id: \.self) { trait in
                    Text(trait)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                }
            }
            
            Text(breed.temperamentAndPersonality)
                .font(.body)
                .foregroundColor(.secondary)
                .lineSpacing(2)
        }
    }
    
    private var careSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Care & Maintenance")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(breed.careAndMaintenance)
                .font(.body)
                .foregroundColor(.secondary)
                .lineSpacing(2)
        }
    }
    
    private var healthSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Health & Longevity")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(breed.healthAndLongevity)
                .font(.body)
                .foregroundColor(.secondary)
                .lineSpacing(2)
        }
    }
    
    private var trainingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Training & Behavior")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(breed.trainingAndBehavior)
                .font(.body)
                .foregroundColor(.secondary)
                .lineSpacing(2)
        }
    }
    
    private var livingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Living with this Breed")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(breed.livingWithTheBreed)
                .font(.body)
                .foregroundColor(.secondary)
                .lineSpacing(2)
        }
    }
    
    private var interestingFactsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Interesting Facts")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(breed.interestingFacts.enumerated()), id: \.offset) { index, fact in
                    HStack(alignment: .top, spacing: 12) {
                        Text("•")
                            .font(.body)
                            .foregroundColor(.blue)
                        
                        Text(fact)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineSpacing(2)
                    }
                    .padding(.leading, 28)
                }
            }
        }
    }
    
    // Rest of your existing implementation stays the same...
    private var sampleImagesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if sampleImages.count == 1 {
                Image(uiImage: sampleImages[0])
                    .resizable()
                    .scaledToFill()
                    .frame(maxHeight: 300)
                    .clipped()
                    .cornerRadius(12)
                    .padding(.horizontal)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(sampleImages.enumerated()), id: \.offset) { index, image in
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 200, height: 150)
                                .clipped()
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private func loadSampleImages() {
        Task {
            let images = await loadBreedImages(for: breed.name)
            await MainActor.run {
                self.sampleImages = images
            }
        }
    }
    
    private func loadBreedImages(for breedName: String) async -> [UIImage] {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let searchKey = breedName.replacingOccurrences(of: " ", with: "_")
                
                guard let resourceURL = Bundle.main.resourceURL,
                      let files = try? FileManager.default.contentsOfDirectory(at: resourceURL, includingPropertiesForKeys: nil) else {
                    continuation.resume(returning: [])
                    return
                }
                
                let key = searchKey.lowercased()
                
                let imageFiles = files.filter { url in
                    let ext = url.pathExtension.lowercased()
                    let filenameNoExt = url.deletingPathExtension().lastPathComponent.lowercased()
                    guard ext == "heic" else { return false }
                    return filenameNoExt == key || filenameNoExt.hasPrefix("\(key)_")
                }
                
                let images = imageFiles
                    .shuffled()
                    .prefix(3)
                    .compactMap { UIImage(contentsOfFile: $0.path) }
                
                continuation.resume(returning: Array(images))
            }
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    DogBreedDetailView(breed: DogBreed(
        name: "Golden Retriever",
        overviewAndIntroduction: "A large sporting dog with a friendly nature and golden coat, bred for retrieving waterfowl. This beloved breed combines friendly temperament with intelligent personality traits, making them a popular choice for families worldwide.",
        breedClassification: BreedClassification(
            breedGroup: "Sporting Group",
            sizeCategory: "Large",
            typicalHeight: "22-24 inches",
            typicalWeight: "55-75 pounds"
        ),
        historicalBackground: "The Golden Retriever breed developed through centuries of selective breeding...",
        physicalCharacteristics: "The Golden Retriever presents a well-balanced appearance...",
        temperamentAndPersonality: "The Golden Retriever temperament perfectly embodies their reputation...",
        careAndMaintenance: "Daily care for a Golden Retriever involves meeting their physical, mental, and emotional needs...",
        healthAndLongevity: "With proper care, most Golden Retrievers enjoy healthy lives spanning 10-15 years...",
        trainingAndBehavior: "The Golden Retriever's intelligent nature typically makes them responsive...",
        livingWithTheBreed: "Successfully sharing your life with a Golden Retriever requires understanding...",
        breedSelectionGuidance: "The Golden Retriever is best suited for individuals or families...",
        specialConsiderations: "Each Golden Retriever is an individual with their own personality...",
        interestingFacts: [
            "Consistently ranked as one of America's most popular breeds for their versatility and temperament.",
            "The Golden Retriever breed has influenced the development of other breeds throughout history",
            "Many Golden Retrievers have gained fame through their achievements in various fields",
            "Their friendly nature has made them popular in media and literature",
            "The breed continues to excel in modern roles that utilize their natural abilities"
        ]
    ))
}

