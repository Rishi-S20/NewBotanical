//
//  HomeView.swift
//  Quizify
//
//  Created by Rishi Suryavanshi on 4/2/25.
//

import SwiftUI

struct HomeView: View {
    @State private var showMenu = false
    
    var body: some View {
        ZStack(alignment: .leading) {
            
            
            // Main content
            NavigationView {
                ZStack(alignment: .top) {
                    // Scrolling content
                    ScrollView(.vertical) {
                        VStack(alignment: .leading) {
                            Spacer()
                                .frame(height: 100)
                            
                            // Your content will go here
                            
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
                            
                            // Quizify logo and text
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .ignoresSafeArea()
        .preferredColorScheme(.light)
    }
}

// Extension for hex color support
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
