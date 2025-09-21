//
//  LibraryView.swift
//  PerroScan
//

import SwiftUI

struct LibraryView: View {
    @State private var breeds: [DogBreed] = []
    @State private var searchText = ""
    @State private var selectedBreed: DogBreed?
    
    var body: some View {
        NavigationStack {
            Group {
                if breeds.isEmpty {
                    ContentUnavailableView(
                        "No Breeds Available",
                        systemImage: "pawprint.fill",
                        description: Text("Unable to load dog breed database.")
                    )
                } else {
                    breedList
                }
            }
            .navigationTitle("Dog Breeds")
            .searchable(text: $searchText, prompt: "Search breeds...")
            .onAppear {
                loadBreeds()
            }
        }
        .fullScreenCover(item: $selectedBreed) { breed in
            DogBreedDetailView(breed: breed)
        }
    }
    
    private var breedList: some View {
        List(filteredBreeds) { breed in
            Button {
                selectedBreed = breed
            } label: {
                BreedRowView(breed: breed)
            }
            .buttonStyle(.plain)
        }
        .listStyle(.plain)
    }
    
    private var filteredBreeds: [DogBreed] {
        if searchText.isEmpty {
            return breeds
        } else {
            return breeds.filter { breed in
                breed.name.localizedCaseInsensitiveContains(searchText) ||
                breed.breedClassification.breedGroup.localizedCaseInsensitiveContains(searchText) ||
                breed.traits.joined(separator: " ").localizedCaseInsensitiveContains(searchText) ||
                breed.overviewAndIntroduction.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private func loadBreeds() {
        breeds = DogBreedStore.loadBreedsArray()
    }
}

struct BreedRowView: View {
    let breed: DogBreed
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(breed.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(breed.breedClassification.breedGroup)
                        .font(.caption2)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.blue.opacity(0.1))
                        .clipShape(Capsule())
                    
                    Text(breed.overviewAndIntroduction)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(breed.breedClassification.sizeCategory)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    ForEach(Array(breed.traits.prefix(2)), id: \.self) { trait in
                        Text(trait)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(.green.opacity(0.1))
                            .foregroundColor(.green)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    LibraryView()
}

