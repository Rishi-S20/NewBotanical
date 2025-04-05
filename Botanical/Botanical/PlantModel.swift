//
//  PlantModel.swift
//  Botanical
//
//  Created on 4/4/25.
//

import Foundation
import UIKit

// Plant model with all the details we need for the profile view
struct Plant: Identifiable {
    let id = UUID()
    let name: String
    var scientificName: String?
    let image: UIImage?
    let confidenceScore: Float
    
    // Basic information
    var family: String?
    var familyCommonName: String?
    var yearDiscovered: String?
    
    // Growing conditions
    var lightRequirements: String?
    var soilHumidity: String?
    var airHumidity: String?
    var temperatureRange: String?
    var soilPH: String?
    
    // Care information
    var wateringInfo: String?
    var fertilizerInfo: String?
    var pruningInfo: String?
    
    // Additional information
    var isEdible: Bool?
    var toxicity: String?
    var growthHabit: String?
    
    var wateringFrequency: WateringFrequency?
    var lastWateredDate: Date?
    
    // Helper computed property to get next watering date
    var nextWateringDate: Date? {
        guard let lastWatered = lastWateredDate,
                let frequency = wateringFrequency else {
            return nil
        }
        
        let calendar = Calendar.current
        switch frequency {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: lastWatered)
        case .twiceWeekly:
            return calendar.date(byAdding: .day, value: 3, to: lastWatered)
        case .weekly:
            return calendar.date(byAdding: .day, value: 7, to: lastWatered)
        case .biweekly:
            return calendar.date(byAdding: .day, value: 14, to: lastWatered)
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: lastWatered)
        }
    }
    
    // Format the days until next watering
    var daysUntilWatering: String {
        guard let nextWatering = nextWateringDate else {
            return "Set watering schedule"
        }
        
        let days = Calendar.current.dateComponents([.day], from: Date(), to: nextWatering).day ?? 0
        
        if days < 0 {
            return "Overdue"
        } else if days == 0 {
            return "Today"
        } else if days == 1 {
            return "Tomorrow"
        } else {
            return "In \(days) days"
        }
    }
    
    init(name: String, scientificName: String? = nil, image: UIImage? = nil, confidenceScore: Float) {
        self.name = name
        self.scientificName = scientificName
        self.image = image
        self.confidenceScore = confidenceScore
    }
}

enum WateringFrequency: String, Codable, CaseIterable {
    case daily = "Daily"
    case twiceWeekly = "Twice Weekly"
    case weekly = "Weekly"
    case biweekly = "Every 2 Weeks"
    case monthly = "Monthly"
    
    // Helper to extract watering frequency from text
    static func fromDescription(_ description: String?) -> WateringFrequency? {
        guard let description = description?.lowercased() else { return nil }
        
        if description.contains("daily") || description.contains("every day") {
            return .daily
        } else if description.contains("twice a week") || description.contains("every 3-4 days") {
            return .twiceWeekly
        } else if description.contains("weekly") || description.contains("once a week") {
            return .weekly
        } else if description.contains("every two weeks") || description.contains("biweekly") {
            return .biweekly
        } else if description.contains("monthly") || description.contains("once a month") {
            return .monthly
        }
        
        // Default to weekly if we can't determine
        return .weekly
    }
}

// Response structure for Gemini API
struct GeminiResponse: Codable {
    let plantDetails: PlantInfo
    
    struct PlantInfo: Codable {
        let scientificName: String?
        let family: String?
        let familyCommonName: String?
        let yearDiscovered: String?
        
        let lightRequirements: String?
        let soilHumidity: String?
        let airHumidity: String?
        let temperatureRange: String?
        let soilPH: String?
        
        let wateringInfo: String?
        let fertilizerInfo: String?
        let pruningInfo: String?
        
        let isEdible: Bool?
        let toxicity: String?
        let growthHabit: String?
    }
}
