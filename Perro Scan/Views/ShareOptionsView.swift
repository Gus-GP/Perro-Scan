//
//  ShareOptionsView.swift
//  PerroScan
//

import SwiftUI

struct ShareOptionsView: View {
    let breedName: String
    let confidence: Float
    let userImage: UIImage?
    let sampleImage: UIImage?
    let chartData: [ChartSlice]
    let allProbabilities: [ChartSlice] // Add this line
    
    @Environment(\.dismiss) private var dismiss
    @State private var isGeneratingImage = false
    @State private var isGeneratingPDF = false
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?
    @State private var sharePDFURL: URL?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header section
                headerSection
                
                Divider()
                
                // Options section
                VStack(spacing: 24) {
                    shareOptionsGrid
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
                
                Spacer()
            }
            .navigationTitle("Share Result")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .overlay {
                if isGeneratingImage || isGeneratingPDF {
                    generatingOverlay
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            shareImage = nil
            sharePDFURL = nil
        } content: {
            if let shareImage = shareImage {
                ShareSheet(items: [shareImage])
            } else if let pdfURL = sharePDFURL {
                ShareSheet(items: [pdfURL])
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            if let userImage = userImage {
                Image(uiImage: userImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            }
            
            VStack(spacing: 4) {
                Text("Identified as")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(breedName)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("\(Int(confidence * 100))% confidence")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 24)
    }
    
    private var shareOptionsGrid: some View {
        VStack(spacing: 20) {
            Text("Choose sharing format")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 16) {
                // Image option
                shareOptionButton(
                    title: "Social Media Image",
                    subtitle: "Perfect for Instagram, Twitter, etc.",
                    icon: "photo.on.rectangle.angled",
                    color: .blue,
                    isLoading: isGeneratingImage,
                    action: {
                        generateSocialMediaImage()
                    }
                )
                
                // Report option
                shareOptionButton(
                    title: "Detailed Report",
                    subtitle: "PDF with breed information & analysis",
                    icon: "doc.text.fill",
                    color: .red,
                    isLoading: isGeneratingPDF,
                    action: {
                        generatePDFReport()
                    }
                )
            }
        }
    }
    
    private func shareOptionButton(
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon or loading indicator
                ZStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 50, height: 50)
                .background(color.opacity(isLoading ? 0.6 : 1.0))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Chevron (hidden when loading)
                if !isLoading {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(.gray.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isGeneratingImage || isGeneratingPDF)
    }
    
    private var generatingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea(.all)
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.blue)
                
                Text(isGeneratingImage ? "Generating share image..." : "Generating PDF report...")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            .padding(32)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }
    
    private func generateSocialMediaImage() {
        guard let userImage = userImage else { return }
        
        isGeneratingImage = true
        
        Task {
            let generatedImage = await SocialShareImageGenerator.generateShareImage(
                userImage: userImage,
                sampleImage: sampleImage,
                breedName: breedName,
                confidence: confidence,
                chartData: chartData
            )
            
            await MainActor.run {
                isGeneratingImage = false
                
                if let image = generatedImage {
                    shareImage = image
                    showShareSheet = true
                } else {
                    print("Failed to generate share image")
                }
            }
        }
    }
    
    private func generatePDFReport() {
        guard let userImage = userImage else { return }
        
        isGeneratingPDF = true
        
        Task {
            let breedDetails = DogBreedStore.getBreed(named: breedName)
            
            let pdfURL = await PDFReportGenerator.generateDetailedReport(
                userImage: userImage,
                sampleImage: sampleImage,
                breedName: breedName,
                confidence: confidence,
                chartData: chartData,
                allProbabilities: allProbabilities, // Now uses the parameter
                breedDetails: breedDetails
            )
            
            await MainActor.run {
                isGeneratingPDF = false
                
                if let url = pdfURL {
                    sharePDFURL = url
                    showShareSheet = true
                } else {
                    print("Failed to generate PDF report")
                }
            }
        }
    }
}

#Preview {
    ShareOptionsView(
        breedName: "Golden Retriever",
        confidence: 0.87,
        userImage: UIImage(systemName: "photo"),
        sampleImage: UIImage(systemName: "photo"),
        chartData: [
            ChartSlice(label: "Golden Retriever", value: 0.87, isTop: true),
            ChartSlice(label: "Labrador", value: 0.08, isTop: false),
            ChartSlice(label: "Other", value: 0.05, isTop: false)
        ],
        allProbabilities: [] // Add empty array for preview
    )
}

