//
//  GardenView.swift
//  Botanical
//
//  Created on 4/4/25.
//

import SwiftUI
import Foundation
import SwiftUI
import Combine



struct GardenView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = GardenViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom navigation bar
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: "#111E0D"))
                        .padding()
                }
                
                Spacer()
                
                Text("My Garden")
                    .font(.custom("Satoshi Variable", size: 20))
                    .bold()
                    .foregroundColor(Color(hex: "#111E0D"))
                
                Spacer()
                
                // Empty space to balance the back button
                Image(systemName: "arrow.left")
                    .font(.system(size: 20))
                    .foregroundColor(.clear)
                    .padding()
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            if viewModel.plants.isEmpty {
                // Empty state view
                Spacer()
                VStack(spacing: 20) {
                    Image(systemName: "leaf")
                        .font(.system(size: 64))
                        .foregroundColor(Color(hex: "#C6F6D5"))
                    
                    Text("Your Garden is Empty")
                        .font(.custom("Satoshi Variable", size: 22))
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "#111E0D"))
                    
                    Text("Add plants to your garden by identifying them with the camera or searching our database.")
                        .font(.custom("Satoshi Variable", size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    NavigationLink(destination: NewPlantView()) {
                        Text("Add Your First Plant")
                            .font(.custom("Satoshi Variable", size: 16))
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 30)
                            .background(Color(hex: "#2D3B26"))
                            .cornerRadius(30)
                    }
                    .padding(.top, 10)
                }
                Spacer()
            } else {
                // Grid of plants
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        ForEach(viewModel.plants) { plant in
                            GardenPlantCard(plant: plant)
                                .onTapGesture {
                                    viewModel.selectedPlant = plant
                                    viewModel.showPlantProfile = true
                                }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.loadPlants()
        }
        .sheet(isPresented: $viewModel.showPlantProfile) {
            if let plant = viewModel.selectedPlant {
                PlantProfileView(
                    plantName: plant.name,
                    confidence: plant.confidenceScore,
                    plantImage: plant.image
                )
            }
        }
    }
}

// Garden plant card
struct GardenPlantCard: View {
    let plant: Plant
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Plant image
            if let image = plant.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                Rectangle()
                    .fill(Color(hex: "#C6F6D5"))
                    .frame(height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            
            // Plant name
            Text(plant.name)
                .font(.custom("Satoshi Variable", size: 16))
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "#111E0D"))
                .lineLimit(1)
            
            // Scientific name
            if let scientificName = plant.scientificName {
                Text(scientificName)
                    .font(.custom("Satoshi Variable", size: 12))
                    .italic()
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    NavigationView {
        GardenView()
    }
}
