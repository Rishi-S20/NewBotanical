//
//  HomeView.swift
//  Botanical
//
//  Created by Rishi Suryavanshi on 4/2/25.
//

import SwiftUI

struct HomeView: View {
    @State private var showMenu = false
    @StateObject private var viewModel = HomeViewModel()
    @State private var rootViewId = UUID()

    
    var body: some View {
        ZStack(alignment: .leading) {
            // Side menu
            if showMenu {
                SideMenuView(viewModel: viewModel, showMenu: $showMenu)
                    .frame(width: 270)
                    .transition(.move(edge: .leading))
            }
            
            // Main content
            NavigationView {
                ZStack(alignment: .top) {
                    // Scrolling content
                    ScrollView(.vertical) {
                        VStack(alignment: .leading) {
                            Spacer()
                                .frame(height: 100)
                            
                            // Welcome section
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Welcome to Botanical")
                                    .font(.custom("Satoshi Variable", size: 26))
                                    .fontWeight(.bold)
                                    .foregroundColor(Color(hex: "#111E0D"))
                                
                                Text("Your digital garden companion")
                                    .font(.custom("Satoshi Variable", size: 16))
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal)
                            .padding(.top, 20)
                            
                            // Quick actions
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Quick Actions")
                                    .font(.custom("Satoshi Variable", size: 18))
                                    .fontWeight(.bold)
                                    .foregroundColor(Color(hex: "#111E0D"))
                                    .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        QuickActionCard(
                                            title: "Identify Plant",
                                            iconName: "camera.fill",
                                            backgroundColor: Color(hex: "#C6F6D5"),
                                            destination: AnyView(PlantScannerView())
                                        )
                                        
                                        QuickActionCard(
                                            title: "My Garden",
                                            iconName: "leaf.fill",
                                            backgroundColor: Color(hex: "#E6FFFA"),
                                            destination: AnyView(GardenView())
                                        )
                                        
                                        QuickActionCard(
                                            title: "New Plant",
                                            iconName: "plus",
                                            backgroundColor: Color(hex: "#FEEBC8"),
                                            destination: AnyView(NewPlantView())
                                        )
                                        
                                        QuickActionCard(
                                            title: "Calendar",
                                            iconName: "calendar",
                                            backgroundColor: Color(hex: "#E6FFFA"),
                                            destination: AnyView(WateringCalendarView())
                                        )
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.top, 30)
                            
                            // Recent plants section
                            if !viewModel.recentPlants.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Recently Added Plants")
                                        .font(.custom("Satoshi Variable", size: 18))
                                        .fontWeight(.bold)
                                        .foregroundColor(Color(hex: "#111E0D"))
                                        .padding(.horizontal)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 16) {
                                            ForEach(viewModel.recentPlants) { plant in
                                                RecentPlantCard(plant: plant)
                                                    .onTapGesture {
                                                        viewModel.selectedPlant = plant
                                                        viewModel.showPlantProfile = true
                                                    }
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                                .padding(.top, 30)
                            }
                            
                            // Plant care tips
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Plant Care Tips")
                                    .font(.custom("Satoshi Variable", size: 18))
                                    .fontWeight(.bold)
                                    .foregroundColor(Color(hex: "#111E0D"))
                                    .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(viewModel.plantCareTips) { tip in
                                            PlantCareTipCard(tip: tip)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.top, 30)
                            
                        }
                        .padding(.bottom, 50)
                    }
                    
                    // Floating header with GeometryReader
                    GeometryReader { geometry in
                        HStack(spacing: 0) {
                            // Menu Button
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showMenu.toggle()
                                }
                            }) {
                                Image(systemName: "text.justify")
                                    .foregroundColor(Color(hex: "#111E0D"))
                                    .font(.system(size: 20))
                                    .frame(width: 40)
                                    .contentShape(Rectangle())
                                    .bold()
                            }
                            
                            Spacer()
                            
                            // Botanical logo and text
                            HStack(spacing: 8) {
                                Text("Botanical")
                                    .font(.custom("Satoshi Variable", size: 30)).bold()
                                    .foregroundColor(Color(hex: "#111E0D"))
                                    .minimumScaleFactor(0.5)
                                    .lineLimit(1)
                                
                                // Added LogoClear image
                                Image("LogoClear")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 60)
                            }
                            .frame(maxWidth: geometry.size.width * 0.5)
                            
                            Spacer()
                            
                            // Plus button
                            NavigationLink(destination: NewPlantView()) {
                                Image(systemName: "plus")
                                    .foregroundColor(Color(hex: "#111E0D"))
                                    .font(.system(size: 25))
                                    .frame(width: 40)
                                    .bold()
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 15)
                        .background(
                            Color(.white)
                                .cornerRadius(30)
                        )
                        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 3)
                        .padding(.horizontal)
                    }
                    .frame(height: 100)
                }
            }
            .offset(x: showMenu ? 270 : 0)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .ignoresSafeArea()
        .preferredColorScheme(.light)
        .onAppear {
            viewModel.loadRecentPlants()
        }
    }
}

// Quick action card component
struct QuickActionCard: View {
    let title: String
    let iconName: String
    let backgroundColor: Color
    let destination: AnyView
    
    var body: some View {
        NavigationLink(destination: destination) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(backgroundColor)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: iconName)
                        .font(.system(size: 22))
                        .foregroundColor(Color(hex: "#111E0D"))
                }
                
                Text(title)
                    .font(.custom("Satoshi Variable", size: 14))
                    .fontWeight(.medium)
                    .foregroundColor(Color(hex: "#111E0D"))
            }
            .frame(width: 100, height: 120)
            .padding(.vertical, 16)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
    }
}

// Recent plant card component
struct RecentPlantCard: View {
    let plant: Plant
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Plant image
            if let image = plant.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 150, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                Rectangle()
                    .fill(Color(hex: "#F0FFF4"))
                    .frame(width: 150, height: 120)
                    .cornerRadius(12)
            }
            
            // Plant name
            Text(plant.name)
                .font(.custom("Satoshi Variable", size: 14))
                .bold()
                .foregroundColor(Color(hex: "#111E0D"))
                .lineLimit(1)
            
            // Scientific name if available
            if let scientificName = plant.scientificName {
                Text(scientificName)
                    .font(.custom("Satoshi Variable", size: 12))
                    .italic()
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
        }
        .frame(width: 150)
        .padding(12)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// Plant care tip card
struct PlantCareTipCard: View {
    let tip: PlantCareTip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon and title
            HStack {
                Image(systemName: tip.iconName)
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: "#2D3B26"))
                
                Text(tip.title)
                    .font(.custom("Satoshi Variable", size: 16))
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "#111E0D"))
            }
            
            // Tip content
            Text(tip.content)
                .font(.custom("Satoshi Variable", size: 14))
                .foregroundColor(.gray)
                .lineLimit(3)
        }
        .frame(width: 270)
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// Side menu view
struct SideMenuView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Binding var showMenu: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image("LogoClear")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 40)
                
                Text("Botanical")
                    .font(.custom("Satoshi Variable", size: 24))
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "#111E0D"))
            }
            .padding(.horizontal)
            .padding(.top, 60)
            .padding(.bottom, 40)
            
            // Menu items
            VStack(alignment: .leading, spacing: 24) {
                ForEach(viewModel.menuItems) { item in
                    MenuItemRow(item: item, showMenu: $showMenu)
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Settings button
            Button(action: {
                // Handle settings action
                showMenu = false
            }) {
                HStack {
                    Image(systemName: "gear")
                        .font(.system(size: 18))
                    
                    Text("Settings")
                        .font(.custom("Satoshi Variable", size: 16))
                }
                .foregroundColor(.gray)
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color(hex: "#F9FAF7"))
        .edgesIgnoringSafeArea(.all)
    }
}

// Menu item row
struct MenuItemRow: View {
    let item: MenuItem
    @Binding var showMenu: Bool
    
    var body: some View {
        NavigationLink(destination: item.destination) {
            HStack(spacing: 16) {
                Image(systemName: item.iconName)
                    .font(.system(size: 20))
                    .frame(width: 24)
                
                Text(item.title)
                    .font(.custom("Satoshi Variable", size: 16))
            }
            .foregroundColor(Color(hex: "#111E0D"))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
        }
        .simultaneousGesture(TapGesture().onEnded {
            showMenu = false
        })
    }
}


extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    HomeView()
}
