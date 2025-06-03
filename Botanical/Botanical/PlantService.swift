//
//  PlantService.swift
//  Botanical
//
//  Created by Rishi Suryavanshi on 4/4/25.
//
import GoogleGenerativeAI
import Foundation
import UIKit
import Combine
import GoogleGenerativeAI
// Service for handling plant-related operations
class PlantService {
    
    
    static let shared = PlantService()
    
    private init() {}
    
    // In-memory cache for plant details
    private var plantCache: [String: Plant] = [:]
    
    // User's saved plants
    private var savedPlants: [Plant] = []
    
    // Plants search history
    private var searchHistory: [String] = []
    
    // Event publisher for plant changes
    private let plantSubject = PassthroughSubject<Plant, Never>()
    var plantPublisher: AnyPublisher<Plant, Never> {
        return plantSubject.eraseToAnyPublisher()
    }
    
    // Get plant details from cache or fetch new if not available
    func getPlantDetails(name: String, confidence: Float, image: UIImage?) -> AnyPublisher<Plant, Error> {
        // Check cache first
        if let cachedPlant = plantCache[name.lowercased()] {
            return Just(cachedPlant)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        // Use the new Gemini API method
        return fetchPlantInfoWithGemini(for: name, confidence: confidence, image: image)
            .map { [weak self] updatedPlant in
                // Update cache
                self?.plantCache[name.lowercased()] = updatedPlant
                
                // Publish the updated plant
                self?.plantSubject.send(updatedPlant)
                
                return updatedPlant
            }
            .eraseToAnyPublisher()
    }
    
    // Save a plant to user's garden
    func savePlant(_ plant: Plant) {
        if !savedPlants.contains(where: { $0.id == plant.id }) {
            savedPlants.append(plant)
            
            // Save to persistent storage
            savePlantsToUserDefaults()
        }
    }
    
    // Remove a plant from user's garden
    func removePlant(withID id: UUID) {
        savedPlants.removeAll(where: { $0.id == id })
        
        // Update persistent storage
        savePlantsToUserDefaults()
    }
    
    // Get all saved plants
    func getSavedPlants() -> [Plant] {
        if savedPlants.isEmpty {
            // Load from persistent storage if empty
            loadPlantsFromUserDefaults()
        }
        return savedPlants
    }
    
    
    // Add this to PlantService.swift
    private func fetchPlantInfoWithGemini(for plantName: String, confidence: Float, image: UIImage?) -> AnyPublisher<Plant, Error> {
        // Create a new plant with basic info
        var plant = Plant(name: plantName, image: image, confidenceScore: confidence)
        
        return Future<Plant, Error> { promise in
            Task {
                do {
                    // Hardcode the API key that was working in your GeminiService
                    let apiKey = AppEnvironment.geminiAPIKey
                    
                    // Use the same model as in your working GeminiService
                    let model = GenerativeModel(
                        name: "gemini-2.0-flash",
                        apiKey: apiKey,
                        generationConfig: GenerationConfig(
                            temperature: 0.7,
                            topP: 0.95,
                            topK: 40,
                            maxOutputTokens: 8192,
                            responseMIMEType: "text/plain"
                        )
                    )
                    
                    // Create a chat instance
                    let chat = model.startChat()
                    
                    // Send the plant prompt
                    let response = try await chat.sendMessage(self.createGeminiPrompt(for: plantName))
                    
                    // Process the response
                    if let responseText = response.text {
                        // Try to extract JSON from the text response
                        if let jsonStart = responseText.range(of: "{"),
                           let jsonEnd = responseText.range(of: "}", options: .backwards) {
                            let jsonRange = jsonStart.lowerBound..<jsonEnd.upperBound
                            let jsonString = String(responseText[jsonRange])
                            
                            do {
                                let decoder = JSONDecoder()
                                let plantInfo = try decoder.decode(GeminiResponse.self, from: jsonString.data(using: .utf8) ?? Data())
                                
                                // Update the plant model with the parsed data
                                plant.scientificName = plantInfo.plantDetails.scientificName
                                plant.family = plantInfo.plantDetails.family
                                plant.familyCommonName = plantInfo.plantDetails.familyCommonName
                                plant.yearDiscovered = plantInfo.plantDetails.yearDiscovered
                                
                                plant.lightRequirements = plantInfo.plantDetails.lightRequirements
                                plant.soilHumidity = plantInfo.plantDetails.soilHumidity
                                plant.airHumidity = plantInfo.plantDetails.airHumidity
                                plant.temperatureRange = plantInfo.plantDetails.temperatureRange
                                plant.soilPH = plantInfo.plantDetails.soilPH
                                
                                plant.wateringInfo = plantInfo.plantDetails.wateringInfo
                                plant.fertilizerInfo = plantInfo.plantDetails.fertilizerInfo
                                plant.pruningInfo = plantInfo.plantDetails.pruningInfo
                                
                                plant.isEdible = plantInfo.plantDetails.isEdible
                                plant.toxicity = plantInfo.plantDetails.toxicity
                                plant.growthHabit = plantInfo.plantDetails.growthHabit
                            } catch {
                                // Fallback to simple text parsing if JSON parsing fails
                                self.parseTextResponse(responseText, plant: &plant)
                            }
                        } else {
                            // If no JSON structure is found, try text parsing
                            self.parseTextResponse(responseText, plant: &plant)
                        }
                        
                        // Return a success with the updated plant
                        promise(.success(plant))
                    } else {
                        promise(.failure(NSError(domain: "PlantService", code: 3, userInfo: [NSLocalizedDescriptionKey: "No response text"])))
                    }
                } catch {
                    print("Gemini API error: \(error)")
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    // Add an item to search history
    func addToSearchHistory(_ searchTerm: String) {
        // Remove if already exists to avoid duplicates
        searchHistory.removeAll(where: { $0.lowercased() == searchTerm.lowercased() })
        
        // Add to the beginning of the array
        searchHistory.insert(searchTerm, at: 0)
        
        // Keep only the most recent 10 searches
        if searchHistory.count > 10 {
            searchHistory = Array(searchHistory.prefix(10))
        }
        
        // Save to UserDefaults
        UserDefaults.standard.set(searchHistory, forKey: "plantSearchHistory")
    }
    
    // Get search history
    func getSearchHistory() -> [String] {
        if searchHistory.isEmpty {
            // Load from UserDefaults if empty
            searchHistory = UserDefaults.standard.stringArray(forKey: "plantSearchHistory") ?? []
        }
        return searchHistory
    }
    
    // Clear search history
    func clearSearchHistory() {
        searchHistory.removeAll()
        UserDefaults.standard.removeObject(forKey: "plantSearchHistory")
    }
    
    // MARK: - Private Helper Methods
    
    // Create prompt for Gemini API
    private func createGeminiPrompt(for plantName: String) -> String {
        return """
        I need detailed care information about the plant "\(plantName)" in JSON format.
        Please provide a response with the following structure:
        {
          "plantDetails": {
            "scientificName": "Latin name of the plant",
            "family": "Botanical family",
            "familyCommonName": "Common name of the family",
            "yearDiscovered": "Year first documented if known",
            
            "lightRequirements": "Detailed light requirements",
            "soilHumidity": "Soil moisture needs",
            "airHumidity": "Air humidity preferences",
            "temperatureRange": "Ideal temperature range in Celsius",
            "soilPH": "Ideal soil pH range",
            
            "wateringInfo": "Detailed watering instructions",
            "fertilizerInfo": "Fertilizer recommendations",
            "pruningInfo": "Pruning guidance",
            
            "isEdible": true/false,
            "toxicity": "Toxicity information",
            "growthHabit": "Growth habit description"
          }
        }
        
        The response should be scientifically accurate and provide practical care instructions.
        """
    }
    
    // Parse Gemini API response
    private func parseGeminiResponse(_ data: Data, plant: Plant) throws -> Plant {
        // Create a mutable copy of the plant
        var updatedPlant = plant
        
        do {
            // First, get the raw JSON to parse into our structure
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let candidates = json["candidates"] as? [[String: Any]],
                  let firstCandidate = candidates.first,
                  let content = firstCandidate["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]],
                  let firstPart = parts.first,
                  let text = firstPart["text"] as? String else {
                throw NSError(domain: "JSONParsing", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON structure"])
            }
            
            // Try to extract the JSON part from the text response
            if let jsonStart = text.range(of: "{"),
               let jsonEnd = text.range(of: "}", options: .backwards) {
                let jsonRange = jsonStart.lowerBound..<jsonEnd.upperBound
                let jsonString = String(text[jsonRange])
                
                let decoder = JSONDecoder()
                let plantInfo = try decoder.decode(GeminiResponse.self, from: jsonString.data(using: .utf8) ?? Data())
                
                // Update the plant model with the parsed data
                updatedPlant.scientificName = plantInfo.plantDetails.scientificName
                updatedPlant.family = plantInfo.plantDetails.family
                updatedPlant.familyCommonName = plantInfo.plantDetails.familyCommonName
                updatedPlant.yearDiscovered = plantInfo.plantDetails.yearDiscovered
                
                updatedPlant.lightRequirements = plantInfo.plantDetails.lightRequirements
                updatedPlant.soilHumidity = plantInfo.plantDetails.soilHumidity
                updatedPlant.airHumidity = plantInfo.plantDetails.airHumidity
                updatedPlant.temperatureRange = plantInfo.plantDetails.temperatureRange
                updatedPlant.soilPH = plantInfo.plantDetails.soilPH
                
                updatedPlant.wateringInfo = plantInfo.plantDetails.wateringInfo
                updatedPlant.fertilizerInfo = plantInfo.plantDetails.fertilizerInfo
                updatedPlant.pruningInfo = plantInfo.plantDetails.pruningInfo
                
                updatedPlant.isEdible = plantInfo.plantDetails.isEdible
                updatedPlant.toxicity = plantInfo.plantDetails.toxicity
                updatedPlant.growthHabit = plantInfo.plantDetails.growthHabit
            } else {
                // Fall back to more forgiving parsing if structured JSON isn't found
                parseTextResponse(text, plant: &updatedPlant)
            }
            
            return updatedPlant
        } catch {
            throw error
        }
    }
    
    // Parse text response from Gemini when it doesn't return proper JSON
    private func parseTextResponse(_ text: String, plant: inout Plant) {
        // Simple parsing for when the model doesn't return proper JSON
        // This is a fallback method that looks for key phrases in the response
        
        // Update scientific name if present
        if let scientificNameRange = text.range(of: "Scientific Name: ", options: .caseInsensitive),
           let endOfLine = text[scientificNameRange.upperBound...].range(of: "\n") {
            let scientificName = String(text[scientificNameRange.upperBound..<endOfLine.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            plant.scientificName = scientificName
        }
        
        // Similarly extract other fields
        plant.family = extractInfoFromText(text, fieldName: "Family:")
        plant.wateringInfo = extractInfoFromText(text, fieldName: "Watering:")
        plant.lightRequirements = extractInfoFromText(text, fieldName: "Light:")
        plant.toxicity = extractInfoFromText(text, fieldName: "Toxicity:")
    }
    
    // Helper method to extract information from text
    private func extractInfoFromText(_ text: String, fieldName: String) -> String? {
        if let range = text.range(of: fieldName, options: .caseInsensitive),
           let endOfLine = text[range.upperBound...].range(of: "\n") {
            return String(text[range.upperBound..<endOfLine.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return nil
    }
    


    
    
    func updatePlantWateringDate(withID id: UUID, date: Date) {
        if let index = savedPlants.firstIndex(where: { $0.id == id }) {
            savedPlants[index].lastWateredDate = date
            
            // Save to persistent storage
            savePlantsToUserDefaults()
        }
    }
    
    // Set watering frequency for a plant
    func updatePlantWateringFrequency(withID id: UUID, frequency: WateringFrequency) {
        if let index = savedPlants.firstIndex(where: { $0.id == id }) {
            savedPlants[index].wateringFrequency = frequency
            
            // If the plant hasn't been watered before, set initial watering date
            if savedPlants[index].lastWateredDate == nil {
                savedPlants[index].lastWateredDate = Date()
            }
            
            // Save to persistent storage
            savePlantsToUserDefaults()
        }
    }
    
    // Update savePlantsToUserDefaults to include watering data
    private func savePlantsToUserDefaults() {
        // Convert plants to dictionaries
        let plantDicts = savedPlants.map { plant -> [String: Any] in
            var dict: [String: Any] = [
                "id": plant.id.uuidString,
                "name": plant.name,
                "confidenceScore": plant.confidenceScore
            ]
            
            if let scientificName = plant.scientificName {
                dict["scientificName"] = scientificName
            }
            
            // Save watering data
            if let lastWateredDate = plant.lastWateredDate {
                dict["lastWateredDate"] = lastWateredDate
            }
            
            if let wateringFrequency = plant.wateringFrequency?.rawValue {
                dict["wateringFrequency"] = wateringFrequency
            }
            
            // Add other properties as needed
            
            return dict
        }
        
        UserDefaults.standard.set(plantDicts, forKey: "savedPlants")
    }
    
    // Update loadPlantsFromUserDefaults to include watering data
    private func loadPlantsFromUserDefaults() {
        guard let plantDicts = UserDefaults.standard.array(forKey: "savedPlants") as? [[String: Any]] else {
            return
        }
        
        // Convert dictionaries back to Plant objects
        savedPlants = plantDicts.compactMap { dict -> Plant? in
            guard let name = dict["name"] as? String,
                  let confidenceScore = dict["confidenceScore"] as? Float else {
                return nil
            }
            
            var plant = Plant(name: name, confidenceScore: confidenceScore)
            
            if let scientificName = dict["scientificName"] as? String {
                plant.scientificName = scientificName
            }
            
            // Load watering data
            if let lastWateredDateData = dict["lastWateredDate"] as? Date {
                plant.lastWateredDate = lastWateredDateData
            }
            
            if let wateringFrequencyString = dict["wateringFrequency"] as? String,
               let wateringFrequency = WateringFrequency(rawValue: wateringFrequencyString) {
                plant.wateringFrequency = wateringFrequency
            }
            
            // Set other properties as needed
            
            return plant
        }
    }
}
