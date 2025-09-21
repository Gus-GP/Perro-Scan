//
//  SocialShareImageGenerator.swift
//  PerroScan
//

import SwiftUI
import UIKit
import Charts

class SocialShareImageGenerator {
    
    static func generateShareImage(
        userImage: UIImage,
        sampleImage: UIImage?,
        breedName: String,
        confidence: Float,
        chartData: [ChartSlice]
    ) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                print("🎨 Starting image generation for \(breedName)")
                
                // Create the SwiftUI view
                let shareView = SimpleShareImageView(
                    userImage: userImage,
                    sampleImage: sampleImage,
                    breedName: breedName,
                    confidence: confidence,
                    chartData: chartData
                )
                
                // Render it properly
                let image = renderView(shareView)
                
                print("🎨 Generated image size: \(image?.size ?? CGSize.zero)")
                continuation.resume(returning: image)
            }
        }
    }
    
    private static func renderView<V: View>(_ view: V) -> UIImage? {
        let hostingController = UIHostingController(rootView: view)
        let targetSize = CGSize(width: 380, height: 741)
        
        // Set up the hosting controller
        hostingController.view.frame = CGRect(origin: .zero, size: targetSize)
        hostingController.view.backgroundColor = UIColor.clear
        
        // Create a window and add the hosting controller
        let window = UIWindow(frame: CGRect(origin: .zero, size: targetSize))
        window.rootViewController = hostingController
        window.makeKeyAndVisible()
        
        // Force layout
        hostingController.view.setNeedsLayout()
        hostingController.view.layoutIfNeeded()
        
        // Wait a moment for Chart to render
        Thread.sleep(forTimeInterval: 0.1)
        
        // Render to image
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let image = renderer.image { context in
            hostingController.view.layer.render(in: context.cgContext)
        }
        
        // Clean up
        window.isHidden = true
        
        return image
    }
}

struct SimpleShareImageView: View {
    let userImage: UIImage
    let sampleImage: UIImage?
    let breedName: String
    let confidence: Float
    let chartData: [ChartSlice]
    
    // Updated colors to match SwiftUI Chart's exact default palette
    private let chartColors: [Color] = [
        Color(red: 0.0, green: 0.48, blue: 1.0),        // Blue
        Color(red: 0.2, green: 0.78, blue: 0.35),       // Green
        Color(red: 1.0, green: 0.58, blue: 0.0),        // Orange
        Color(red: 0.69, green: 0.32, blue: 0.87),      // Purple
        Color(red: 0.96, green: 0.26, blue: 0.21),      // Red
        Color(red: 0.35, green: 0.91, blue: 0.91)       // Light Blue/Cyan (matches "Other" in chart)
    ]
    
    // Helper function matching ResultsView logic
    private func getOtherLabel(confidence: Float) -> (label: String, description: String, color: Color) {
        if confidence > 0.4 {
            return ("Not a Dog", "Nice try but... not a dog", .gray)
        } else {
            return ("Other", "Multiple traits detected", .orange)
        }
    }
    
    var body: some View {
        VStack(spacing: 12) { // Reduced spacing from 14 to 12
            // Header with app branding
            headerSection
            
            // Images section with labels
            imagesSection
            
            // Analysis result
            resultSection
            
            // Chart section with center overlay
            chartSection
            
            // Chart legend
            legendSection
            
            // Footer
            footerSection
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16) // Separate bottom padding
        .frame(width: 380, height: 741)
        .background(.white)
    }
    
    private var headerSection: some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                // Direct SwiftUI Image approach
                Image("Light_Logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .onAppear {
                        print("🖼️ Attempting to load Light_Logo from assets")
                    }
                
                Text("Perro Scan")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                Spacer()
            }
            
            HStack {
                Text("Dog Breed Identification Service")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
            }
        }
    }
    
    private var imagesSection: some View {
        HStack(spacing: 16) {
            // User image with label
            VStack(spacing: 8) {
                Text("Your Photo")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.gray)
                
                Image(uiImage: userImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.gray.opacity(0.3), lineWidth: 1)
                    )
            }
            
            // Arrow with label
            VStack(spacing: 4) {
                Text("AI Analysis")
                    .font(.caption2)
                    .foregroundColor(.blue)
                    .fontWeight(.medium)
                
                Image(systemName: "arrow.right")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            
            // Sample image with label
            VStack(spacing: 8) {
                Text("Best Match")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.gray)
                
                if let sampleImage = sampleImage {
                    Image(uiImage: sampleImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.blue, lineWidth: 2)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.gray.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.title)
                                .foregroundColor(.gray)
                        )
                }
            }
        }
    }
    
    private var resultSection: some View {
        VStack(spacing: 8) {
            Text("Identified as:")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Text(breedName)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 4) {
                // Smart confidence indicator based on percentage
                if confidence > 0.5 {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("\(Int(confidence * 100))% Strong Match")
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.blue)
                    Text("\(Int(confidence * 100))% Match")
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
            }
            .font(.headline)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background((confidence > 0.5 ? Color.green : Color.blue).opacity(0.1))
            .clipShape(Capsule())
        }
        .padding(.vertical, 6)
    }
    
    private var chartSection: some View {
        VStack(spacing: 10) {
            Text("Breed Analysis Results")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.black)
            
            Chart(chartData) { slice in
                SectorMark(
                    angle: .value("Probability", slice.value),
                    innerRadius: .ratio(0.65), // Increased from 0.5 to 0.65 for more center space
                    outerRadius: slice.value == chartData.max(by: { $0.value < $1.value })?.value ? .ratio(0.95) : .ratio(0.9)
                )
                .foregroundStyle(by: .value("Breed", slice.label))
                .opacity(slice.value == chartData.max(by: { $0.value < $1.value })?.value ? 1.0 : 0.7)
            }
            .frame(width: 160, height: 160)
            .chartLegend(.hidden)
            .overlay(alignment: .center) {
                // Center label matching ResultsView logic
                VStack(spacing: 0) { // Reduced spacing from 1 to 0
                    if let highest = chartData.max(by: { $0.value < $1.value }) {
                        if highest.label == "Other" {
                            let otherInfo = getOtherLabel(confidence: Float(highest.value))
                            Text(otherInfo.label)
                                .font(.caption2) // Reduced from .caption
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.primary)
                            
                            Text("\(String(format: "%.1f", highest.value * 100))%")
                                .font(.caption) // Reduced from .subheadline
                                .fontWeight(.bold)
                                .foregroundColor(otherInfo.color)
                            
                            Text(otherInfo.description)
                                .font(.caption2)
                                .foregroundColor(otherInfo.color)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        } else {
                            Text(highest.label)
                                .font(.caption2) // Reduced from .caption
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.primary)
                                .lineLimit(2)
                            
                            Text("\(String(format: "%.1f", highest.value * 100))%")
                                .font(.caption) // Reduced from .subheadline
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            
                            // Only show "Strong Match" if probability > 50%
                            if highest.value > 0.5 {
                                Text("Strong Match")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                            } else {
                                Text("Top Match")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .frame(maxWidth: 80) // Reduced from 90
            }
        }
    }
    
    private var legendSection: some View {
        VStack(spacing: 6) { // Reduced from 8 to 6
            Text("All Matches:")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.gray)
            
            VStack(alignment: .leading, spacing: 2) { // Reduced from 3 to 2
                ForEach(Array(chartData.enumerated()), id: \.element.id) { index, slice in
                    let isHighest = slice.value == chartData.max(by: { $0.value < $1.value })?.value
                    
                    HStack(spacing: 8) {
                        // Color-coded circle that matches chart colors exactly
                        Circle()
                            .fill(chartColors[index % chartColors.count])
                            .frame(width: 10, height: 10)
                        
                        // Smart labeling for "Other"
                        if slice.label == "Other" {
                            let otherInfo = getOtherLabel(confidence: Float(slice.value))
                            Text(otherInfo.label)
                                .font(.caption)
                                .fontWeight(isHighest ? .semibold : .regular)
                                .foregroundColor(isHighest ? otherInfo.color : .black)
                        } else {
                            Text(slice.label)
                                .font(.caption)
                                .fontWeight(isHighest ? .semibold : .regular)
                                .foregroundColor(.black)
                        }
                        
                        Spacer()
                        
                        Text("\(Int(slice.value * 100))%")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 8)
        }
    }
    
    private var footerSection: some View {
        VStack(spacing: 4) {
            Text("Generated by Perro Scan")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.gray)
            
            Text("AI-powered dog breed identification")
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }
}

