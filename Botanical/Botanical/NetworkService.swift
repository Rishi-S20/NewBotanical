//
//  NetworkService.swift
//  Botanical
//
//  Created on 4/4/25.
//

import Foundation
import Combine

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case requestFailed(Error)
    case decodingFailed(Error)
    case serverError(Int)
    case noData
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .requestFailed(let error):
            return "Request failed: \(error.localizedDescription)"
        case .decodingFailed(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .serverError(let code):
            return "Server error (HTTP \(code))"
        case .noData:
            return "No data received from server"
        }
    }
}

class NetworkService {
    static let shared = NetworkService()
    
    private init() {}
    
    func fetchData<T: Decodable>(url: URL, headers: [String: String]? = nil) -> AnyPublisher<T, NetworkError> {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add headers if provided
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    throw NetworkError.serverError(httpResponse.statusCode)
                }
                
                return data
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .mapError { error in
                if let urlError = error as? URLError {
                    return NetworkError.requestFailed(urlError)
                } else if let decodingError = error as? DecodingError {
                    return NetworkError.decodingFailed(decodingError)
                } else if let networkError = error as? NetworkError {
                    return networkError
                } else {
                    return NetworkError.requestFailed(error)
                }
            }
            .eraseToAnyPublisher()
    }
    
    func postData<T: Decodable>(url: URL, body: Data, headers: [String: String]? = nil) -> AnyPublisher<T, NetworkError> {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        
        // Set default content type if not provided
        if headers?["Content-Type"] == nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        // Add headers if provided
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    throw NetworkError.serverError(httpResponse.statusCode)
                }
                
                return data
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .mapError { error in
                if let urlError = error as? URLError {
                    return NetworkError.requestFailed(urlError)
                } else if let decodingError = error as? DecodingError {
                    return NetworkError.decodingFailed(decodingError)
                } else if let networkError = error as? NetworkError {
                    return networkError
                } else {
                    return NetworkError.requestFailed(error)
                }
            }
            .eraseToAnyPublisher()
    }
    
    // Custom method for handling Gemini API requests that may return text rather than structured JSON
    func postToGeminiAPI(url: URL, body: Data) -> AnyPublisher<Data, NetworkError> {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    throw NetworkError.serverError(httpResponse.statusCode)
                }
                
                guard !data.isEmpty else {
                    throw NetworkError.noData
                }
                
                return data
            }
            .mapError { error in
                if let urlError = error as? URLError {
                    return NetworkError.requestFailed(urlError)
                } else if let networkError = error as? NetworkError {
                    return networkError
                } else {
                    return NetworkError.requestFailed(error)
                }
            }
            .eraseToAnyPublisher()
    }
}
