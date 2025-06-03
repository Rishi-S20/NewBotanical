//
//  PlantProfileView.swift
//  Botanical
//
//  Created by Rishi Suryavanshi on 4/4/25.
//
import SwiftUI

// Updates for PlantProfileView.swift to make information more digestible

struct PlantProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel: PlantViewModel
    @State private var selectedTab = 0
    @State private var showingFullImage = false
    
    init(plantName: String, confidence: Float, plantImage: UIImage?) {
        _viewModel = StateObject(wrappedValue: PlantViewModel(
            plantName: plantName,
            confidence: confidence,
            plantImage: plantImage
        ))
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color(hex: "#F7F7F7").ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with plant image and name
                plantHeader
                
                // Tab selection
                tabSelectionView
                
                // Content based on selected tab
                if viewModel.isLoading {
                    loadingView
                } else if let error = viewModel.errorMessage {
                    errorView(message: error)
                } else if let plant = viewModel.plant {
                    TabView(selection: $selectedTab) {
                        // Basic Info Tab
                        ScrollView {
                            basicInfoContent(plant: plant)
                                .padding(.bottom, 100)
                        }
                        .tag(0)
                        
                        // Care Tab
                        ScrollView {
                            careInfoContent(plant: plant)
                                .padding(.bottom, 100)
                        }
                        .tag(1)
                        
                        // Additional Info Tab
                        ScrollView {
                            additionalInfoContent(plant: plant)
                                .padding(.bottom, 100)
                        }
                        .tag(2)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            
            // Bottom navigation bar
            VStack {
                Spacer()
                
                HStack {
                    // Back button
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 20))
                            Text("Back")
                                .font(.custom("Satoshi Variable", size: 12))
                        }
                        .foregroundColor(Color(hex: "#2D3B26"))
                        .frame(width: 70)
                    }
                    
                    Spacer()
                    
                    // Home button
                    Button(action: {
                        // Reset to HomeView by setting the root view
                        UIApplication.shared.windows.first?.rootViewController = UIHostingController(rootView: HomeView())
                        UIApplication.shared.windows.first?.makeKeyAndVisible()
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "house.fill")
                                .font(.system(size: 20))
                            Text("Home")
                                .font(.custom("Satoshi Variable", size: 12))
                        }
                        .foregroundColor(Color(hex: "#2D3B26"))
                        .frame(width: 70)
                    }                    // Home button
                   
                    
                    Spacer()
                    
                    // Add to garden button
                    Button(action: {
                        viewModel.toggleGarden()
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: viewModel.isInGarden ? "minus.circle.fill" : "plus.circle.fill")
                                .font(.system(size: 20))
                            Text(viewModel.isInGarden ? "Remove" : "Add")
                                .font(.custom("Satoshi Variable", size: 12))
                        }
                        .foregroundColor(viewModel.isInGarden ? .red : Color(hex: "#2D3B26"))
                        .frame(width: 70)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 15)
                .background(Color.white)
                .cornerRadius(30, corners: [.topLeft, .topRight])
                .shadow(color: Color.black.opacity(0.1), radius: 4, y: -2)
            }
        }
        .edgesIgnoringSafeArea(.vertical)
        .navigationBarHidden(true)
        .sheet(isPresented: $showingFullImage) {
            if let image = viewModel.plant?.image {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black)
                    
                    Button(action: {
                        showingFullImage = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                .ignoresSafeArea()
            }
        }
        .onAppear {
            viewModel.fetchPlantDetails()
        }
    }
    
    // MARK: - Header Views
    
    private var plantHeader: some View {
        ZStack(alignment: .bottom) {
            // Plant image
            if let plantImage = viewModel.plant?.image {
                Button(action: {
                    showingFullImage = true
                }) {
                    Image(uiImage: plantImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 240)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .overlay(
                            LinearGradient(
                                gradient: Gradient(colors: [.clear, Color.black.opacity(0.7)]),
                                startPoint: .center,
                                endPoint: .bottom
                            )
                        )
                }
            } else {
                Rectangle()
                    .fill(Color(hex: "#C6F6D5"))
                    .frame(height: 240)
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(colors: [.clear, Color.black.opacity(0.7)]),
                            startPoint: .center,
                            endPoint: .bottom
                        )
                    )
            }
            
            // Plant name and badge
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.plant?.name ?? "")
                            .font(.custom("Satoshi Variable", size: 28))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        if let scientificName = viewModel.plant?.scientificName {
                            Text(scientificName)
                                .font(.custom("Satoshi Variable", size: 16))
                                .italic()
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    
                    Spacer()
                    
                    if let confidence = viewModel.plant?.confidenceScore {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 50, height: 50)
                            
                            VStack(spacing: 2) {
                                Text("\(Int(confidence * 100))%")
                                    .font(.custom("Satoshi Variable", size: 18))
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text("Match")
                                    .font(.custom("Satoshi Variable", size: 10))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
    }
    
    private var tabSelectionView: some View {
        HStack(spacing: 0) {
            ForEach(["Overview", "Care Guide", "Details"].indices, id: \.self) { index in
                Button(action: {
                    withAnimation {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 8) {
                        Text(["Overview", "Care Guide", "Details"][index])
                            .font(.custom("Satoshi Variable", size: 16))
                            .fontWeight(selectedTab == index ? .bold : .regular)
                            .foregroundColor(selectedTab == index ? Color(hex: "#2D3B26") : .gray)
                        
                        Rectangle()
                            .fill(selectedTab == index ? Color(hex: "#2D3B26") : Color.clear)
                            .frame(height: 3)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.top, 12)
        .background(Color.white)
    }
    
    // MARK: - Content Views with Bullet Points
    
    private func basicInfoContent(plant: Plant) -> some View {
        VStack(spacing: 20) {
            // Basic botanical info with bullet points
            InfoCardBullets(title: "Botanical Details", items: [
                BulletItem(icon: "folder.fill", title: "Family", value: plant.family ?? "Unknown"),
                BulletItem(icon: "tag.fill", title: "Family Common Name", value: plant.familyCommonName ?? "N/A"),
                BulletItem(icon: "doc.text.magnifyingglass", title: "Scientific Name", value: plant.scientificName ?? "Unknown"),
                BulletItem(icon: "calendar", title: "First Documented", value: plant.yearDiscovered ?? "Unknown")
            ])
            
            // Quick care summary
            QuickCareCard(plant: plant)
            
            // Is it safe?
            if let isEdible = plant.isEdible, let toxicity = plant.toxicity {
                SafetyInfoCard(isEdible: isEdible, toxicity: toxicity)
            }
        }
        .padding(.horizontal)
        .padding(.top, 12)
    }
    
    private func careInfoContent(plant: Plant) -> some View {
        VStack(spacing: 20) {
            // Growing conditions with bullet points
            InfoCardBullets(title: "Growing Conditions", items: [
                BulletItem(icon: "sun.max.fill", title: "Light", value: plant.lightRequirements ?? "Medium light"),
                BulletItem(icon: "drop.fill", title: "Soil Moisture", value: plant.soilHumidity ?? "Keep moderately moist"),
                BulletItem(icon: "humidity.fill", title: "Air Humidity", value: plant.airHumidity ?? "Average humidity"),
                BulletItem(icon: "thermometer", title: "Temperature", value: plant.temperatureRange ?? "65-80°F (18-27°C)"),
                BulletItem(icon: "drop.triangle.fill", title: "Soil pH", value: plant.soilPH ?? "6.0-7.0")
            ])
            
            // Care guides
            if let wateringInfo = plant.wateringInfo {
                BulletCareGuideCard(
                    title: "Watering Guide",
                    icon: "drop.fill",
                    color: Color(hex: "#6082C9"),
                    content: createBulletPoints(from: wateringInfo)
                )
            }
            
            if let fertilizerInfo = plant.fertilizerInfo {
                BulletCareGuideCard(
                    title: "Fertilizer Guide",
                    icon: "leaf.fill",
                    color: Color(hex: "#60C97D"),
                    content: createBulletPoints(from: fertilizerInfo)
                )
            }
            
            if let pruningInfo = plant.pruningInfo {
                BulletCareGuideCard(
                    title: "Pruning Guide",
                    icon: "scissors",
                    color: Color(hex: "#C97D60"),
                    content: createBulletPoints(from: pruningInfo)
                )
            }
        }
        .padding(.horizontal)
        .padding(.top, 12)
    }
    
    // Helper method to create bullet points from a string
    func createBulletPoints(from text: String) -> [String] {
        // Split text by sentences or periods
        let sentences = text.components(separatedBy: ". ")
            .filter { !$0.isEmpty }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .map { $0.hasSuffix(".") ? $0 : $0 + "." }
        return sentences
    }
    
    // Helper function to combine additional details
    func combineAdditionalDetails(plant: Plant) -> String? {
        var details = [String]()
        
        // Add any contextual additional details
        if let scientificName = plant.scientificName {
            details.append("Scientific name is \(scientificName)")
        }
        
        if let yearDiscovered = plant.yearDiscovered {
            details.append("First documented in \(yearDiscovered)")
        }
        
        if let familyCommonName = plant.familyCommonName {
            details.append("Belongs to the \(familyCommonName) family")
        }
        
        if details.isEmpty {
            return nil
        } else {
            return details.joined(separator: ". ")
        }
    }
    
    private func additionalInfoContent(plant: Plant) -> some View {
        VStack(spacing: 20) {
            // Growth habit
            if let growthHabit = plant.growthHabit {
                BulletCareGuideCard(
                    title: "Growth Habit",
                    icon: "arrow.up.forward",
                    color: Color(hex: "#60C97D"),
                    content: createBulletPoints(from: growthHabit)
                )
            }
            
            // Watering schedule
            WateringScheduleCard(plant: plant) { frequency in
                // Update the watering frequency
                PlantService.shared.updatePlantWateringFrequency(withID: plant.id, frequency: frequency)
                // Need to refresh the view model to see changes
                viewModel.refreshPlant()
            }
            
            // Additional details
            if let description = combineAdditionalDetails(plant: plant) {
                BulletCareGuideCard(
                    title: "Additional Details",
                    icon: "info.circle",
                    color: Color(hex: "#6082C9"),
                    content: createBulletPoints(from: description)
                )
            }
        }
        .padding(.horizontal)
        .padding(.top, 12)
    }
    
    // MARK: - Helper Views
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading plant details...")
                .font(.custom("Satoshi Variable", size: 16))
                .foregroundColor(.gray)
                .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .padding()
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            
            Text(message)
                .font(.custom("Satoshi Variable", size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Button(action: {
                viewModel.fetchPlantDetails()
            }) {
                Text("Try Again")
                    .font(.custom("Satoshi Variable", size: 16))
                    .fontWeight(.medium)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(Color(hex: "#C6F6D5"))
                    .foregroundColor(Color(hex: "#111E0D"))
                    .cornerRadius(20)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .padding()
    }
    
 
}

// MARK: - Bullet Point Component Views

struct BulletItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let value: String
}

struct InfoCardBullets: View {
    let title: String
    let items: [BulletItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.custom("Satoshi Variable", size: 18))
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "#111E0D"))
            
            VStack(spacing: 12) {
                ForEach(items) { item in
                    BulletPointRow(icon: item.icon, title: item.title, value: item.value)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct BulletPointRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .frame(width: 24, height: 24)
                .foregroundColor(Color(hex: "#2D3B26"))
            
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("•")
                    .foregroundColor(Color(hex: "#2D3B26"))
                    .font(.headline)
                
                Text(title + ":")
                    .font(.custom("Satoshi Variable", size: 14))
                    .foregroundColor(Color.gray)
            }
            
            Text(value)
                .font(.custom("Satoshi Variable", size: 16))
                .foregroundColor(Color(hex: "#111E0D"))
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct BulletCareGuideCard: View {
    let title: String
    let icon: String
    let color: Color
    let content: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.custom("Satoshi Variable", size: 18))
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "#111E0D"))
            }
            
            VStack(alignment: .leading, spacing: 10) {
                ForEach(content, id: \.self) { point in
                    HStack(alignment: .top, spacing: 10) {
                        Text("•")
                            .font(.headline)
                            .foregroundColor(color)
                        
                        Text(point)
                            .font(.custom("Satoshi Variable", size: 16))
                            .foregroundColor(Color(hex: "#333333"))
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct QuickCareCard: View {
    
    let plant: Plant
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Care Guide")
                .font(.custom("Satoshi Variable", size: 18))
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "#111E0D"))
            
            HStack(spacing: 12) {
                // Light needs
                CareIndicatorView(
                    icon: "sun.max.fill",
                    title: "Light",
                    value: getLightLevel(from: plant.lightRequirements),
                    color: Color(hex: "#F6C6D5")
                )
                
                // Water needs
                CareIndicatorView(
                    icon: "drop.fill",
                    title: "Water",
                    value: getWaterLevel(from: plant.wateringInfo),
                    color: Color(hex: "#C6F6D5")
                )
                
                // Difficulty
                CareIndicatorView(
                    icon: "hand.thumbsup.fill",
                    title: "Ease",
                    value: getDifficultyLevel(plant: plant),
                    color: Color(hex: "#C6D5F6")
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    // Helper functions to determine care levels
    private func getLightLevel(from info: String?) -> String {
        guard let info = info?.lowercased() else { return "Medium" }
        
        if info.contains("low") || info.contains("shade") || info.contains("indirect") {
            return "Low"
        } else if info.contains("bright") || info.contains("direct") || info.contains("full sun") {
            return "High"
        } else {
            return "Medium"
        }
    }
    
    private func getWaterLevel(from info: String?) -> String {
        guard let info = info?.lowercased() else { return "Medium" }
        
        if info.contains("sparingly") || info.contains("dry") || info.contains("drought") {
            return "Low"
        } else if info.contains("frequent") || info.contains("moist") || info.contains("wet") {
            return "High"
        } else {
            return "Medium"
        }
    }
    
    private func getDifficultyLevel(plant: Plant) -> String {
        // This is a simplified algorithm - you could make this more sophisticated
        let factors = [
            getLightLevel(from: plant.lightRequirements) == "Medium",
            getWaterLevel(from: plant.wateringInfo) != "High",
            !(plant.toxicity?.lowercased().contains("toxic") ?? false)
        ]
        
        let trueCount = factors.filter { $0 }.count
        
        if trueCount >= 3 {
            return "Easy"
        } else if trueCount >= 1 {
            return "Medium"
        } else {
            return "Hard"
        }
    }
    
    
    
    // Helper method to create bullet points from a string
     func createBulletPoints(from text: String) -> [String] {
        // Split text by sentences or periods
        let sentences = text.components(separatedBy: ". ")
            .filter { !$0.isEmpty }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .map { $0.hasSuffix(".") ? $0 : $0 + "." }
        return sentences
    }
    
    // Helper function to combine additional details
     func combineAdditionalDetails(plant: Plant) -> String? {
        var details = [String]()
        
        // Add any contextual additional details
        if let scientificName = plant.scientificName {
            details.append("Scientific name is \(scientificName)")
        }
        
        if let yearDiscovered = plant.yearDiscovered {
            details.append("First documented in \(yearDiscovered)")
        }
        
        if let familyCommonName = plant.familyCommonName {
            details.append("Belongs to the \(familyCommonName) family")
        }
        
        if details.isEmpty {
            return nil
        } else {
            return details.joined(separator: ". ")
        }
    }
}

struct CareIndicatorView: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.custom("Satoshi Variable", size: 14))
                .foregroundColor(Color.gray)
            
            Text(value)
                .font(.custom("Satoshi Variable", size: 16))
                .fontWeight(.medium)
                .foregroundColor(Color(hex: "#111E0D"))
        }
        .frame(maxWidth: .infinity)
    }
}

struct SafetyInfoCard: View {
    let isEdible: Bool
    let toxicity: String
    
    var body: some View {
        HStack(spacing: 20) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(isEdible ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: isEdible ? "fork.knife" : "exclamationmark.triangle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(isEdible ? Color.green : Color.red)
                }
                
                Text(isEdible ? "Edible" : "Not Edible")
                    .font(.custom("Satoshi Variable", size: 16))
                    .fontWeight(.medium)
                    .foregroundColor(Color(hex: "#111E0D"))
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Toxicity")
                    .font(.custom("Satoshi Variable", size: 14))
                    .foregroundColor(Color.gray)
                
                let toxicityBullets = toxicity.components(separatedBy: ". ")
                    .filter { !$0.isEmpty }
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                
                if toxicityBullets.count > 1 {
                    // If we can split it into multiple points
                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(toxicityBullets, id: \.self) { point in
                            HStack(alignment: .top, spacing: 6) {
                                Text("•")
                                    .font(.headline)
                                    .foregroundColor(isEdible ? .green : .red)
                                
                                Text(point)
                                    .font(.custom("Satoshi Variable", size: 14))
                                    .foregroundColor(Color(hex: "#111E0D"))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                } else {
                    // Just show as a single text
                    Text(toxicity)
                        .font(.custom("Satoshi Variable", size: 14))
                        .foregroundColor(Color(hex: "#111E0D"))
                        .multilineTextAlignment(.leading)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// Extension for rounded corners on specific sides
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

struct WateringScheduleCard: View {
    
    let plant: Plant
    let onFrequencyChanged: (WateringFrequency) -> Void
    
    @State private var selectedFrequency: WateringFrequency
    @State private var showingFrequencyPicker = false
    
    init(plant: Plant, onFrequencyChanged: @escaping (WateringFrequency) -> Void) {
        self.plant = plant
        self.onFrequencyChanged = onFrequencyChanged
        _selectedFrequency = State(initialValue: plant.wateringFrequency ?? .weekly)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "drop.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "#6082C9"))
                
                Text("Watering Schedule")
                    .font(.custom("Satoshi Variable", size: 18))
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "#111E0D"))
            }
            
            VStack(alignment: .leading, spacing: 15) {
                // Next watering date
                HStack(alignment: .top) {
                    Image(systemName: "calendar")
                        .frame(width: 24)
                        .foregroundColor(Color(hex: "#6082C9"))
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Next watering")
                            .font(.custom("Satoshi Variable", size: 14))
                            .foregroundColor(.gray)
                        
                        Text(plant.daysUntilWatering)
                            .font(.custom("Satoshi Variable", size: 16))
                            .fontWeight(.medium)
                            .foregroundColor(Color(hex: "#111E0D"))
                    }
                    
                    Spacer()
                    
                    // Watered now button
                    Button(action: {
                        // Update last watered date to now
                        PlantService.shared.updatePlantWateringDate(withID: plant.id, date: Date())
                    }) {
                        Text("Water Now")
                            .font(.custom("Satoshi Variable", size: 14))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(hex: "#6082C9").opacity(0.2))
                            .foregroundColor(Color(hex: "#6082C9"))
                            .cornerRadius(15)
                    }
                }
                
                Divider()
                
                // Watering frequency selector
                Button(action: {
                    showingFrequencyPicker = true
                }) {
                    HStack {
                        Image(systemName: "clock")
                            .frame(width: 24)
                            .foregroundColor(Color(hex: "#6082C9"))
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Watering frequency")
                                .font(.custom("Satoshi Variable", size: 14))
                                .foregroundColor(.gray)
                            
                            Text(selectedFrequency.rawValue)
                                .font(.custom("Satoshi Variable", size: 16))
                                .fontWeight(.medium)
                                .foregroundColor(Color(hex: "#111E0D"))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                }
                .actionSheet(isPresented: $showingFrequencyPicker) {
                    ActionSheet(
                        title: Text("Watering Frequency"),
                        message: Text("How often does this plant need water?"),
                        buttons: WateringFrequency.allCases.map { frequency in
                                .default(Text(frequency.rawValue)) {
                                    selectedFrequency = frequency
                                    
                                    // Call the provided callback
                                    onFrequencyChanged(frequency)
                                    
                                    // Also update through PlantService directly
                                    PlantService.shared.updatePlantWateringFrequency(withID: plant.id, frequency: frequency)
                                }
                        } + [.cancel()]
                    )
                }
                
                // Last watered info
                if let lastWatered = plant.lastWateredDate {
                    HStack {
                        Image(systemName: "drop.circle")
                            .frame(width: 24)
                            .foregroundColor(Color(hex: "#6082C9"))
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Last watered")
                                .font(.custom("Satoshi Variable", size: 14))
                                .foregroundColor(.gray)
                            
                            Text(lastWatered, style: .date)
                                .font(.custom("Satoshi Variable", size: 16))
                                .fontWeight(.medium)
                                .foregroundColor(Color(hex: "#111E0D"))
                        }
                    }
                }
            }
            .padding(.top, 5)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}
