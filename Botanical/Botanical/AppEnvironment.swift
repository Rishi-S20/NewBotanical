//
//  AppEnvironment.swift
//  Botanical
//
//  Created on 4/4/25.
//

import Foundation

enum AppEnvironment {
    case development
    case production
    
    // Current environment
    static let current: AppEnvironment = {
#if DEBUG
        return .development
#else
        return .production
#endif
    }()
    
    // API Keys and URLs
    static var geminiAPIKey: String {
        switch current {
        case .development:
            return "AIzaSyBynDFI9V8QiVUubV_GSuyY9Sso2tWKMk8" // Directly use the API key
        case .production:
            return "AIzaSyBynDFI9V8QiVUubV_GSuyY9Sso2tWKMk8" // Directly use the API key
        }
    }
    
    static var geminiAPIEndpoint: String {
        return "https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent"
    }
    
 
    
    // App version
    static var appVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    // Build number
    static var buildNumber: String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    // App name
    static var appName: String {
        return Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "Botanical"
    }
    
    // User defaults keys
    struct UserDefaultsKeys {
        static let userID = "user_id"
        static let userToken = "user_token"
        static let onboardingCompleted = "onboarding_completed"
        static let lastSyncDate = "last_sync_date"
    }
    
    // Timeouts
    struct Timeouts {
        static let standard: TimeInterval = 30
        static let extended: TimeInterval = 60
        static let long: TimeInterval = 120
    }
    
    // Feature flags
    struct FeatureFlags {
        static let enablePlantSharing = true
        static let enableCommunityFeatures = false
        static let enablePremiumFeatures = true
    }
}

// MARK: - API Key Security
extension AppEnvironment {
    // Method to securely retrieve API keys from the keychain in a real app
    static func getSecureAPIKey(for service: String) -> String? {
        // In a real app, you would implement Keychain access here
        // For demo purposes, we'll just return the environment variable
        return ProcessInfo.processInfo.environment[service]
    }
    
    static func getGeminiEndpointWithKey() -> URL? {
        let baseURL = geminiAPIEndpoint
        let apiKey = geminiAPIKey
        
        guard let components = URLComponents(string: baseURL) else {
            print("Invalid base URL: \(baseURL)")
            return nil
        }
        
        var updatedComponents = components
        updatedComponents.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        
        let url = updatedComponents.url
        if url == nil {
            print("Failed to create URL with components: \(updatedComponents)")
        }
        
        return url
    }
    
    // Method to securely store API keys in the keychain
    static func storeSecureAPIKey(_ key: String, for service: String) -> Bool {
        // In a real app, you would implement Keychain storage here
        return true
    }
}
