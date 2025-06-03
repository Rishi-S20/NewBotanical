//
//  PlantViewModel.swift
//  Botanical
//
//  Created on 4/4/25.
//

import Foundation
import UIKit
import Combine

class PlantViewModel: ObservableObject {
    @Published var plant: Plant?
    @Published var isLoading = true
    @Published var errorMessage: String?
    @Published var isInGarden = false
    
    private var cancellables = Set<AnyCancellable>()
    private let geminiAPIKey = AppEnvironment.geminiAPIKey
    private let geminiEndpoint = AppEnvironment.geminiAPIEndpoint
    
    init(plantName: String, confidence: Float, plantImage: UIImage?) {
        plant = Plant(name: plantName, image: plantImage, confidenceScore: confidence)
        
        // Check if this plant is already in the user's garden
        checkIfInGarden()
    }
    
    func fetchPlantDetails() {
        guard let plantName = plant?.name else {
            self.errorMessage = "Plant name is missing"
            self.isLoading = false
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        PlantService.shared.getPlantDetails(
            name: plantName,
            confidence: plant?.confidenceScore ?? 0,
            image: plant?.image
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] completion in
            self?.isLoading = false
            
            if case .failure(let error) = completion {
                self?.errorMessage = "Error fetching plant details: \(error.localizedDescription)"
            }
        } receiveValue: { [weak self] updatedPlant in
            self?.plant = updatedPlant
        }
        .store(in: &cancellables)
    }
    
    func toggleGarden() {
        guard let plant = plant else { return }
        
        if isInGarden {
            PlantService.shared.removePlant(withID: plant.id)
        } else {
            PlantService.shared.savePlant(plant)
        }
        
        // Update status
        isInGarden.toggle()
    }
    
    private func checkIfInGarden() {
        guard let plant = plant else { return }
        
        // Get saved plants and check if our plant is in the list
        let savedPlants = PlantService.shared.getSavedPlants()
        isInGarden = savedPlants.contains { $0.id == plant.id }
    }
    
    func refreshPlant() {
        if let plantName = plant?.name {
            PlantService.shared.getPlantDetails(
                name: plantName,
                confidence: plant?.confidenceScore ?? 0,
                image: plant?.image
            )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                // Handle completion
            } receiveValue: { [weak self] updatedPlant in
                self?.plant = updatedPlant
                self?.checkIfInGarden()
            }
            .store(in: &cancellables)
        }
    }
    
    
    private func parseGeminiResponse(_ data: Data) {
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
                updatePlantDetails(with: plantInfo.plantDetails)
            } else {
                // Fall back to more forgiving parsing if structured JSON isn't found
                parseTextResponse(text)
            }
            
            self.isLoading = false
        } catch {
            self.isLoading = false
            self.errorMessage = "Failed to parse response: \(error.localizedDescription)"
        }
    }
    
    private func parseTextResponse(_ text: String) {
        // Simple parsing for when the model doesn't return proper JSON
        // This is a fallback method that looks for key phrases in the response
        
        // Update scientific name if present
        if let scientificNameRange = text.range(of: "Scientific Name: ", options: .caseInsensitive),
           let endOfLine = text[scientificNameRange.upperBound...].range(of: "\n") {
            let scientificName = String(text[scientificNameRange.upperBound..<endOfLine.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            plant?.scientificName = scientificName
        }
        
        // Similarly extract other fields...
        // For example: family, care instructions, etc.
        
        // For simplicity, let's just set some default values if we can't parse properly
        if plant?.scientificName == nil {
            plant?.scientificName = "Not available"
        }
        
        plant?.family = extractInfoFromText(text, fieldName: "Family:")
        plant?.wateringInfo = extractInfoFromText(text, fieldName: "Watering:")
        plant?.lightRequirements = extractInfoFromText(text, fieldName: "Light:")
        plant?.toxicity = extractInfoFromText(text, fieldName: "Toxicity:")
    }
    
    private func extractInfoFromText(_ text: String, fieldName: String) -> String? {
        if let range = text.range(of: fieldName, options: .caseInsensitive),
           let endOfLine = text[range.upperBound...].range(of: "\n") {
            return String(text[range.upperBound..<endOfLine.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return nil
    }
    
    private func updatePlantDetails(with info: GeminiResponse.PlantInfo) {
        // Update the plant object with the information from Gemini
        plant?.scientificName = info.scientificName
        plant?.family = info.family
        plant?.familyCommonName = info.familyCommonName
        plant?.yearDiscovered = info.yearDiscovered
        
        plant?.lightRequirements = info.lightRequirements
        plant?.soilHumidity = info.soilHumidity
        plant?.airHumidity = info.airHumidity
        plant?.temperatureRange = info.temperatureRange
        plant?.soilPH = info.soilPH
        
        plant?.wateringInfo = info.wateringInfo
        plant?.fertilizerInfo = info.fertilizerInfo
        plant?.pruningInfo = info.pruningInfo
        
        plant?.isEdible = info.isEdible
        plant?.toxicity = info.toxicity
        plant?.growthHabit = info.growthHabit
    }
    
    
    
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
}
