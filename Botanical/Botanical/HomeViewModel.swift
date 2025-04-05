//
//  HomeViewModel.swift
//  Botanical
//
//  Created by Rishi Suryavanshi on 4/4/25.
//

//
//  HomeViewModel.swift
//  Botanical
//
//  Created on 4/4/25.
//

import Foundation
import SwiftUI
import Combine

// Menu item model
struct MenuItem: Identifiable {
    let id = UUID()
    let title: String
    let iconName: String
    let destination: AnyView
}

// Plant care tip model
struct PlantCareTip: Identifiable {
    let id = UUID()
    let title: String
    let content: String
    let iconName: String
}

class HomeViewModel: ObservableObject {
    @Published var recentPlants: [Plant] = []
    @Published var plantCareTips: [PlantCareTip] = []
    @Published var menuItems: [MenuItem] = []
    @Published var selectedPlant: Plant?
    @Published var showPlantProfile = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupMenuItems()
        setupPlantCareTips()
        
        // Subscribe to plant changes
        PlantService.shared.plantPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] plant in
                self?.loadRecentPlants()
            }
            .store(in: &cancellables)
    }
    
    func loadRecentPlants() {
        // Get plants from the PlantService
        let allPlants = PlantService.shared.getSavedPlants()
        
        // Show only the 5 most recent plants
        recentPlants = Array(allPlants.prefix(5))
    }
    
    private func setupMenuItems() {
        menuItems = [
            MenuItem(
                title: "Home",
                iconName: "house.fill",
                destination: AnyView(HomeView())
            ),
            MenuItem(
                title: "My Garden",
                iconName: "leaf.fill",
                destination: AnyView(GardenView())
            ),
            MenuItem(
                title: "Identify Plant",
                iconName: "camera.fill",
                destination: AnyView(PlantScannerView())
            ),
            MenuItem(
                title: "Add New Plant",
                iconName: "plus.circle.fill",
                destination: AnyView(NewPlantView())
            ),
            MenuItem(
                title: "Plant Care Calendar",
                iconName: "calendar",
                destination: AnyView(Text("Plant Care Calendar").padding())
            ),
            MenuItem(
                title: "Plant Encyclopedia",
                iconName: "book.fill",
                destination: AnyView(Text("Plant Encyclopedia").padding())
            )
        ]
    }
    
    private func setupPlantCareTips() {
        plantCareTips = [
            PlantCareTip(
                title: "Watering Tips",
                content: "Water your plants early in the morning to reduce evaporation and fungal growth.",
                iconName: "drop.fill"
            ),
            PlantCareTip(
                title: "Light Requirements",
                content: "Most houseplants prefer bright, indirect light. Direct sunlight can scorch leaves.",
                iconName: "sun.max.fill"
            ),
            PlantCareTip(
                title: "Pruning Guide",
                content: "Regular pruning encourages bushier growth and removes unhealthy parts.",
                iconName: "scissors"
            ),
            PlantCareTip(
                title: "Soil Health",
                content: "Refresh potting soil annually to replenish nutrients and improve drainage.",
                iconName: "leaf.fill"
            )
        ]
    }
}
