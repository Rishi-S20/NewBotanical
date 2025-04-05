//
//  GardenViewModel.swift
//  Botanical
//
//  Created by Rishi Suryavanshi on 4/4/25.
//


import Foundation
import SwiftUI
import Combine

class GardenViewModel: ObservableObject {
    @Published var plants: [Plant] = []
    @Published var selectedPlant: Plant?
    @Published var showPlantProfile = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Subscribe to plant changes
        PlantService.shared.plantPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] plant in
                self?.loadPlants()
            }
            .store(in: &cancellables)
    }
    
    func loadPlants() {
        // Get plants from the PlantService
        plants = PlantService.shared.getSavedPlants()
    }
    
    func deletePlant(_ plant: Plant) {
        PlantService.shared.removePlant(withID: plant.id)
        loadPlants()
    }
}
