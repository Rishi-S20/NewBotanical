//
//  NewPlantView.swift
//  Botanical
//
//  Created on 4/2/25.
//

import SwiftUI

struct NewPlantView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var searchText = ""
    @State private var showScanner = false
    
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
                
                Text("Add New Plant")
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
            
            ScrollView {
                VStack(spacing: 30) {
//                    // Search bar
//                    HStack {
//                        Image(systemName: "magnifyingglass")
//                            .foregroundColor(.gray)
//                        
//                        TextField("Search plants...", text: $searchText)
//                            .font(.system(size: 16))
//                        
//                        if !searchText.isEmpty {
//                            Button(action: {
//                                searchText = ""
//                            }) {
//                                Image(systemName: "xmark.circle.fill")
//                                    .foregroundColor(.gray)
//                            }
//                        }
//                    }
//                    .padding(10)
//                    .background(Color(.systemGray6))
//                    .cornerRadius(12)
//                    .padding(.horizontal)
//                    .padding(.top, 20)
                    
                    // Option cards
                    Spacer()
                    VStack(spacing: 20) {
                        // Scan option
                        Button(action: {
                            showScanner = true
                        }) {
                            OptionCardView(
                                title: "Scan Your Plant",
                                description: "Use your camera to identify the plant automatically",
                                iconName: "camera.fill",
                                backgroundColor: Color(hex: "#C6F6D5")
                            )
                        }
                        
                        // Search option
                        NavigationLink(destination: PlantSearchResultsView(searchText: searchText)) {
                            OptionCardView(
                                title: "Search Plant Database",
                                description: "Browse or search our extensive plant database",
                                iconName: "magnifyingglass",
                                backgroundColor: Color(hex: "#E6FFFA")
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Recent plants section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Popular Plants")
                            .font(.custom("Satoshi Variable", size: 18))
                            .bold()
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(1...5, id: \.self) { i in
                                    PopularPlantCardView(
                                        plantName: samplePlantNames[i-1],
                                        imageName: "plant\(i)"
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top, 10)
                    
                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showScanner) {
            PlantScannerView()
        }
    }
    
    // Sample data for demonstration
    private let samplePlantNames = ["Monstera", "Snake Plant", "Peace Lily", "Fiddle Leaf Fig", "Aloe Vera"]
}

// Component for option cards
struct OptionCardView: View {
    let title: String
    let description: String
    let iconName: String
    let backgroundColor: Color
    
    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 60, height: 60)
                
                Image(systemName: iconName)
                    .font(.system(size: 28))
                    .foregroundColor(Color(hex: "#111E0D"))
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.custom("Satoshi Variable", size: 16))
                    .bold()
                    .foregroundColor(Color(hex: "#111E0D"))
                
                Text(description)
                    .font(.custom("Satoshi Variable", size: 14))
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

// Component for popular plant cards
struct PopularPlantCardView: View {
    let plantName: String
    let imageName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // This would be your plant image
            // Replace with actual image when available
            ZStack {
                Rectangle()
                    .fill(Color(hex: "#F0FFF4"))
                    .frame(width: 150, height: 120)
                    .cornerRadius(12)
                
                Text(imageName)
                    .foregroundColor(Color(hex: "#111E0D"))
                    .font(.caption)
            }
            
            Text(plantName)
                .font(.custom("Satoshi Variable", size: 14))
                .bold()
                .foregroundColor(Color(hex: "#111E0D"))
        }
        .frame(width: 150)
    }
}

// Placeholder for the plant scanner view
struct PlantScannerView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                }
                
                Spacer()
            }
            
            Spacer()
            
            Text("Camera View Placeholder")
                .font(.title)
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: {
                // Handle capture action
            }) {
                Circle()
                    .fill(Color.white)
                    .frame(width: 70, height: 70)
                    .overlay(
                        Circle()
                            .stroke(Color.black, lineWidth: 3)
                            .padding(3)
                    )
            }
            .padding(.bottom, 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .edgesIgnoringSafeArea(.all)
    }
}

// Placeholder for search results view
struct PlantSearchResultsView: View {
    var searchText: String
    
    var body: some View {
        VStack {
            Text("Search Results for: \(searchText)")
                .font(.title2)
                .padding()
            
            Text("Results would be displayed here")
                .foregroundColor(.gray)
            
            Spacer()
        }
        .navigationBarTitle("Search Results", displayMode: .inline)
    }
}

#Preview {
    NavigationView {
        NewPlantView()
    }
}
