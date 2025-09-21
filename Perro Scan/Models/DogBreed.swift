//
//  DogBreed.swift
//  PerroScan
//

import Foundation

struct BreedClassification: Codable {
    let breedGroup: String
    let sizeCategory: String
    let typicalHeight: String
    let typicalWeight: String
    
    enum CodingKeys: String, CodingKey {
        case breedGroup = "breed_group"
        case sizeCategory = "size_category"
        case typicalHeight = "typical_height"
        case typicalWeight = "typical_weight"
    }
}

struct DogBreed: Codable, Identifiable, Hashable {
    var id: String { name }
    let name: String
    let overviewAndIntroduction: String
    let breedClassification: BreedClassification
    let historicalBackground: String
    let physicalCharacteristics: String
    let temperamentAndPersonality: String
    let careAndMaintenance: String
    let healthAndLongevity: String
    let trainingAndBehavior: String
    let livingWithTheBreed: String
    let breedSelectionGuidance: String
    let specialConsiderations: String
    let interestingFacts: [String]
    
    enum CodingKeys: String, CodingKey {
        case name
        case overviewAndIntroduction = "overview_and_introduction"
        case breedClassification = "breed_classification"
        case historicalBackground = "historical_background"
        case physicalCharacteristics = "physical_characteristics"
        case temperamentAndPersonality = "temperament_and_personality"
        case careAndMaintenance = "care_and_maintenance"
        case healthAndLongevity = "health_and_longevity"
        case trainingAndBehavior = "training_and_behavior"
        case livingWithTheBreed = "living_with_the_breed"
        case breedSelectionGuidance = "breed_selection_guidance"
        case specialConsiderations = "special_considerations"
        case interestingFacts = "interesting_facts"
    }
    
    // Computed properties for backward compatibility
    var overview: String {
        overviewAndIntroduction
    }
    
    var traits: [String] {
        // Extract traits from temperament text or provide defaults based on breed group
        switch breedClassification.breedGroup {
        case "Sporting Group":
            return ["Active", "Friendly", "Intelligent", "Trainable"]
        case "Herding Group":
            return ["Intelligent", "Alert", "Loyal", "Energetic"]
        case "Working Group":
            return ["Strong", "Confident", "Loyal", "Protective"]
        case "Terrier Group":
            return ["Bold", "Determined", "Energetic", "Alert"]
        case "Toy Group":
            return ["Affectionate", "Alert", "Companionable", "Lively"]
        case "Hound Group":
            return ["Independent", "Gentle", "Determined", "Patient"]
        default:
            return ["Friendly", "Intelligent", "Loyal", "Adaptable"]
        }
    }
    
    var funFact: String {
        interestingFacts.first ?? "This breed has a rich history and unique characteristics."
    }
    
    // MARK: - Hashable Conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    static func == (lhs: DogBreed, rhs: DogBreed) -> Bool {
        lhs.name == rhs.name
    }
}

typealias DogBreedDictionary = [String: DogBreed]

/// Loads Enhanced_DogBreeds.json from the main bundle and returns a dictionary keyed by breed name.
enum DogBreedStore {
    static func loadBreeds() -> DogBreedDictionary {
        guard
            let url = Bundle.main.url(forResource: "DogBreeds", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let breeds = try? JSONDecoder().decode(DogBreedDictionary.self, from: data)
        else {
            print("⚠️ Enhanced_DogBreeds.json missing or malformed")
            return [:]
        }
        return breeds
    }
    
    static func loadBreedsArray() -> [DogBreed] {
        return Array(loadBreeds().values).sorted { $0.name < $1.name }
    }
    
    static func getBreed(named: String) -> DogBreed? {
        return loadBreeds()[named]
    }
}

