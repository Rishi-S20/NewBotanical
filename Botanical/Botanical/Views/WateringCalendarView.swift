//
//  WateringCalendarView.swift
//  Botanical
//
//  Created by Rishi Suryavanshi on 4/4/25.
//

import SwiftUI

struct WateringCalendarView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var plants: [Plant] = []
    @State private var selectedDate: Date = Date()
    @State private var showingPlantDetail = false
    @State private var selectedPlant: Plant?
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter
    }()
    
    private let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()
    
    var body: some View {
        ZStack {
            Color(hex: "#F7F7F7").ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                ZStack {
                    Color(hex: "#2D3B26").ignoresSafeArea(edges: .top)
                    
                    VStack {
                        HStack {
                            Button(action: {
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Image(systemName: "arrow.left")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            Text("Watering Calendar")
                                .font(.custom("Satoshi Variable", size: 20))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button(action: {
                                // Refresh data
                                loadPlants()
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 50)
                        .padding(.bottom, 15)
                        
                        // Date picker
                        calendarView
                    }
                }
                .frame(height: 180)
                
                // Plants to water today
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Today's Watering Schedule")
                            .font(.custom("Satoshi Variable", size: 18))
                            .fontWeight(.bold)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                        
                        if plantsToWaterOnSelectedDate.isEmpty {
                            emptyStateView
                        } else {
                            ForEach(plantsToWaterOnSelectedDate) { plant in
                                WateringPlantCard(plant: plant) {
                                    // Mark as watered
                                    markAsWatered(plant)
                                } onTap: {
                                    selectedPlant = plant
                                    showingPlantDetail = true
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Upcoming section
                        Text("Upcoming Watering")
                            .font(.custom("Satoshi Variable", size: 18))
                            .fontWeight(.bold)
                            .padding(.horizontal, 20)
                            .padding(.top, 30)
                        
                        ForEach(upcomingWateringDays.keys.sorted(), id: \.self) { date in
                            if let plantsForDate = upcomingWateringDays[date] {
                                UpcomingWateringSection(date: date, plants: plantsForDate) { plant in
                                    selectedPlant = plant
                                    showingPlantDetail = true
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        Spacer(minLength: 60)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadPlants()
        }
        .sheet(isPresented: $showingPlantDetail) {
            if let plant = selectedPlant {
                PlantProfileView(
                    plantName: plant.name,
                    confidence: plant.confidenceScore,
                    plantImage: plant.image
                )
            }
        }
    }
    
    // Calendar date picker view
    private var calendarView: some View {
        ScrollViewReader { scrollView in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(-3...14, id: \.self) { offset in
                        if let date = calendar.date(byAdding: .day, value: offset, to: Date()) {
                            DateButton(
                                date: date,
                                isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                                hasEvents: hasWateringEvents(on: date)
                            ) {
                                withAnimation {
                                    selectedDate = date
                                }
                            }
                            .id(offset)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .onAppear {
                // Scroll to today
                scrollView.scrollTo(0, anchor: .center)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 15) {
            Image(systemName: "drop.fill")
                .font(.system(size: 40))
                .foregroundColor(Color(hex: "#C6F6D5"))
            
            Text("No plants to water")
                .font(.custom("Satoshi Variable", size: 18))
                .fontWeight(.medium)
                .foregroundColor(Color(hex: "#111E0D"))
            
            Text("Enjoy your day off from plant care!")
                .font(.custom("Satoshi Variable", size: 16))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // Computed property for plants that need watering on selected date
    private var plantsToWaterOnSelectedDate: [Plant] {
        return plants.filter { plant in
            if let nextWatering = plant.nextWateringDate {
                return calendar.isDate(nextWatering, inSameDayAs: selectedDate)
            }
            return false
        }
    }
    
    // Helper to organize upcoming watering by date
    private var upcomingWateringDays: [Date: [Plant]] {
        var result: [Date: [Plant]] = [:]
        
        // Get the next 7 days
        for plant in plants {
            if let nextWatering = plant.nextWateringDate,
               !calendar.isDate(nextWatering, inSameDayAs: selectedDate) {
                
                // Normalize the date to remove time
                let components = calendar.dateComponents([.year, .month, .day], from: nextWatering)
                if let normalizedDate = calendar.date(from: components) {
                    if result[normalizedDate] == nil {
                        result[normalizedDate] = []
                    }
                    result[normalizedDate]?.append(plant)
                }
            }
        }
        
        // Filter to keep only the next 7 days
        let nextWeek = calendar.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        return result.filter { date, _ in
            date <= nextWeek
        }
    }
    
    // Helper to check if a date has watering events
    private func hasWateringEvents(on date: Date) -> Bool {
        return plants.contains { plant in
            if let nextWatering = plant.nextWateringDate {
                return calendar.isDate(nextWatering, inSameDayAs: date)
            }
            return false
        }
    }
    
    // Load plants from PlantService
    private func loadPlants() {
        plants = PlantService.shared.getSavedPlants()
        
        // For plants without watering frequency, try to determine it from wateringInfo
        for (index, plant) in plants.enumerated() {
            if plant.wateringFrequency == nil {
                plants[index].wateringFrequency = WateringFrequency.fromDescription(plant.wateringInfo)
                
                // If the plant hasn't been watered before, set last watered date to now
                if plants[index].lastWateredDate == nil {
                    plants[index].lastWateredDate = Date()
                }
            }
        }
    }
    
    // Mark a plant as watered
    private func markAsWatered(_ plant: Plant) {
        guard let index = plants.firstIndex(where: { $0.id == plant.id }) else { return }
        
        // Update last watered date
        plants[index].lastWateredDate = Date()
        
        // Update in PlantService
        PlantService.shared.updatePlantWateringDate(withID: plant.id, date: Date())
    }
}

// Date button for calendar
struct DateButton: View {
    let date: Date
    let isSelected: Bool
    let hasEvents: Bool
    let action: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Day of week
                Text(date.formatted(.dateTime.weekday(.abbreviated)))
                    .font(.custom("Satoshi Variable", size: 12))
                    .foregroundColor(isSelected ? .white : Color(hex: "#111E0D"))
                
                // Day number
                Text("\(calendar.component(.day, from: date))")
                    .font(.custom("Satoshi Variable", size: 20))
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? .white : Color(hex: "#111E0D"))
                
                // Indicator for events
                Circle()
                    .fill(hasEvents ? (isSelected ? .white : Color(hex: "#2D3B26")) : .clear)
                    .frame(width: 5, height: 5)
            }
            .frame(width: 50, height: 80)
            .background(isSelected ? Color(hex: "#2D3B26") : Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
}

// Card for plants that need watering
struct WateringPlantCard: View {
    let plant: Plant
    let onWatered: () -> Void
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 15) {
                // Plant image
                if let image = plant.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 70, height: 70)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "#C6F6D5"))
                        .frame(width: 70, height: 70)
                }
                
                // Plant info
                VStack(alignment: .leading, spacing: 4) {
                    Text(plant.name)
                        .font(.custom("Satoshi Variable", size: 16))
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "#111E0D"))
                    
                    if let scientificName = plant.scientificName {
                        Text(scientificName)
                            .font(.custom("Satoshi Variable", size: 12))
                            .italic()
                            .foregroundColor(.gray)
                    }
                    
                    if let frequency = plant.wateringFrequency {
                        HStack {
                            Image(systemName: "drop.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "#6082C9"))
                            
                            Text(frequency.rawValue)
                                .font(.custom("Satoshi Variable", size: 12))
                                .foregroundColor(Color(hex: "#6082C9"))
                        }
                    }
                }
                
                Spacer()
                
                // Watered button
                Button(action: onWatered) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: "#60C97D"))
                        .frame(width: 44, height: 44)
                        .background(Color(hex: "#F0FFF4"))
                        .clipShape(Circle())
                }
            }
            .padding(15)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
    }
}

// Section for upcoming watering
struct UpcomingWateringSection: View {
    let date: Date
    let plants: [Plant]
    let onTap: (Plant) -> Void
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Date header
            Text(dateFormatter.string(from: date))
                .font(.custom("Satoshi Variable", size: 16))
                .fontWeight(.medium)
                .foregroundColor(Color(hex: "#111E0D"))
            
            // Plants list
            VStack(spacing: 10) {
                ForEach(plants) { plant in
                    Button(action: {
                        onTap(plant)
                    }) {
                        HStack {
                            if let image = plant.image {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color(hex: "#C6F6D5"))
                                    .frame(width: 40, height: 40)
                            }
                            
                            Text(plant.name)
                                .font(.custom("Satoshi Variable", size: 16))
                                .foregroundColor(Color(hex: "#111E0D"))
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .padding(15)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .padding(.vertical, 5)
    }
}
