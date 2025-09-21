//
//  ScannerView.swift
//  PerroScan
//

import SwiftUI
import PhotosUI

struct ScannerView: View {
    @EnvironmentObject private var viewModel: ClassificationViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var pickedItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var showingCameraAlert = false
    @State private var selectedBreed: DogBreed?
    @State private var showShareOptions = false // NEW: State for share view
    @State private var showInfo = false // Info sheet
    
    var body: some View {
        ZStack {
            NavigationStack {
                VStack(spacing: 16) {
                    headerText
                    
                    imageDisplaySection
                    
                    learnMoreSection
                    
                    actionButtons
                }
                .padding()
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        HStack(spacing: 8) {
                            Image(colorScheme == .dark ? "Dark_Logo" : "Light_Logo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 28)
                            
                            Text("Perro Scan")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showInfo = true
                        } label: {
                            Image(systemName: "info.circle")
                        }
                        .accessibilityLabel("About & Tips")
                    }
                }
            }
            
            // Full screen loading overlay
            if viewModel.isLoading {
                LoadingView(message: viewModel.loadingMessage)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.isLoading)
        .fullScreenCover(item: $selectedBreed) { breed in
            DogBreedDetailView(breed: breed)
        }
        .fullScreenCover(isPresented: $showShareOptions) {
            if viewModel.hasResults {
                ShareOptionsView(
                    breedName: viewModel.result.prediction,
                    confidence: viewModel.result.confidence,
                    userImage: viewModel.result.userImage,
                    sampleImage: viewModel.result.sampleImage,
                    chartData: viewModel.result.topFiveWithOther,
                    allProbabilities: viewModel.result.allProbabilities
                )
            }
        }
        .sheet(isPresented: $showCamera) {
            SafeImagePicker(sourceType: .camera) { pickedImage in
                viewModel.classifyImage(pickedImage)
            }
        }
        .alert("Camera Unavailable", isPresented: $showingCameraAlert) {
            Button("OK") { }
        } message: {
            Text("Camera is not available on this device.")
        }
        .sheet(isPresented: $showInfo) {
            AppInfoView()
        }
        .onChange(of: pickedItem) { _, newValue in
            Task { await loadAndClassify(item: newValue) }
        }
    }
    
    private var headerText: some View {
        Text(viewModel.result.isEmpty ? "Select a photo to scan" : "Looks Like: \(viewModel.result.prediction)!")
            .font(.headline)
            .animation(.easeInOut(duration: 0.5), value: viewModel.result.prediction)
    }
    
    private var imageDisplaySection: some View {
        VStack(spacing: 10) {
            if let userImage = viewModel.result.userImage {
                VStack {
                    Text("Your Image")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Image(uiImage: userImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            
            if let sampleImage = viewModel.result.sampleImage {
                VStack {
                    Text("\(viewModel.result.prediction)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Image(uiImage: sampleImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .animation(.easeInOut(duration: 0.5), value: viewModel.result.userImage != nil)
        .animation(.easeInOut(duration: 0.5), value: viewModel.result.sampleImage != nil)
    }
    
    private var learnMoreSection: some View {
        Group {
            if let breed = viewModel.predictedBreed {
                Button {
                    selectedBreed = breed
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Learn about \(breed.name)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            Text("Tap for breed information")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                    .padding()
                    .background(.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.5), value: viewModel.predictedBreed != nil)
    }
    
    private var actionButtons: some View {
        Group {
            if viewModel.hasResults {
                resultActionButtons
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                initialActionButtons
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.5), value: viewModel.hasResults)
    }
    
    private var resultActionButtons: some View {
        VStack(spacing: 16) {
            // Two buttons side by side
            HStack(spacing: 12) {
                // Reset button
                Button {
                    viewModel.reset()
                    pickedItem = nil
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                        Text("Scan Again")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .font(.subheadline)
                    .fontWeight(.medium)
                }
                .buttonStyle(.plain)
                
                // Share button - UPDATED
                Button {
                    showShareOptions = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up.fill")
                        Text("Share")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .font(.subheadline)
                    .fontWeight(.medium)
                }
                .buttonStyle(.plain)
            }
            
            Text("Tap to analyze a different photo or share your result")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var initialActionButtons: some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                PhotosPicker(selection: $pickedItem, matching: .images) {
                    Label("Choose Photo", systemImage: "photo")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                Button {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        showCamera = true
                    } else {
                        showingCameraAlert = true
                    }
                } label: {
                    Label("Take Photo", systemImage: "camera")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            
            Button {
                loadSampleImage()
            } label: {
                Label("Use Sample", systemImage: "photo.stack")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private func loadAndClassify(item: PhotosPickerItem?) async {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self),
              let uiImage = UIImage(  data: data) else { return }
        
        await MainActor.run {
            viewModel.classifyImage(uiImage)
        }
    }
    
    private func loadSampleImage() {
        if let url = Bundle.main.url(forResource: "sample", withExtension: "heic"),
           let data = try? Data(contentsOf: url),
           let uiImage = UIImage(  data: data) {
            viewModel.classifyImage(uiImage)
        } else {
            print("Failed to load sample.heic from bundle")
        }
    }
}

#Preview {
    ScannerView()
        .environmentObject(ClassificationViewModel())
}

