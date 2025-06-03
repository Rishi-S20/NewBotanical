# 🌿 Botanical

**Your Digital Garden Companion**

A SwiftUI iOS app that identifies plants using AI and helps you manage your plant collection with smart watering reminders.

![iOS](https://img.shields.io/badge/iOS-15.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.0+-orange.svg)
![SwiftUI](https://img.shields.io/badge/SwiftUI-3.0+-green.svg)

## ✨ Features

- **🔍 Plant Identification**: Uses Custom Python/TF classification model to identify plants with your camera
- **🏡 Personal Garden**: Save and organize your plant collection
- **💧 Watering Calendar**: Track watering schedules with customizable frequencies
- **📚 Plant Care Guides**: Detailed care information powered by Google Gemini AI
- **🎨 Beautiful UI**: Modern SwiftUI interface with smooth animations

## 🚀 Quick Start

### Prerequisites
- Xcode 14.0+
- iOS 15.0+
- Google Gemini API Key

### Setup

1. **Clone the repo**
   ```bash
   git clone https://github.com/yourusername/NewBotanical.git
   cd NewBotanical
   ```

2. **Configure API Key**
   
   Create `APIKeys.swift` in the project:
   ```swift
   struct APIKeys {
       static let geminiAPIKey = "YOUR_GEMINI_API_KEY_HERE"
   }
   ```
   
   Get your API key from [Google AI Studio](https://makersuite.google.com/app/apikey)

3. **Build and Run**
   ```bash
   open Botanical.xcodeproj
   ```

## 🏗️ Architecture

Built with **MVVM pattern** using SwiftUI:

- **PlantService**: Manages plant data and API calls
- **Core ML**: On-device plant identification
- **UserDefaults**: Local plant storage
- **Combine**: Reactive data flow

## 🔧 Key Components

- `HomeView` - Main dashboard with quick actions
- `PlantScannerView` - Camera-based plant identification
- `PlantProfileView` - Detailed plant information with care tabs
- `GardenView` - Your saved plant collection
- `WateringCalendarView` - Watering schedule management

## 📱 Usage

1. **Identify**: Use the camera to scan and identify plants
2. **Save**: Add plants to your personal garden
3. **Care**: Set watering schedules and get care reminders
4. **Learn**: Browse detailed plant profiles and care guides

## 🔒 Security

- API keys are not tracked in version control
- Plant data stored locally on device
- Secure HTTPS API communication

## 🤝 Contributing

1. Fork the repo
2. Create a feature branch
3. Make your changes
4. Submit a pull request

**Note**: Never commit API keys to version control!


**Made with 💚 for plant enthusiasts**
