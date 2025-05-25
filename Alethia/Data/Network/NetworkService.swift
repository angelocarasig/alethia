//
//  NetworkService.swift
//  Alethia
//
//  Created by Angelo Carasig on 17/11/2024.
//

import Foundation

final class NetworkService {
    private let decoder: JSONDecoder
    
    init() {
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            let formatter = NetworkService.dateFormatter()
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string: \(dateString)")
        }
    }
    
    func request<Model: Decodable>(url: URL) async throws -> Model {
        let (data, response) = try await makeRequest(url: url)
        try handleResponse(response)
        
        do {
            let model = try decoder.decode(Model.self, from: data)
            return model
        } catch {
            print("Decoding Error: \(error)")
            print("Data: \(String(data: data, encoding: .utf8) ?? "No Data")")
            throw error
        }
    }
}

// MARK: Extensions

extension NetworkService {
    func makeRequest(url: URL) async throws -> (Data, URLResponse) {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            return try await URLSession.shared.data(for: request)
        } catch let urlError as URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                throw NetworkError.noInternetConnection
            case .timedOut:
                throw NetworkError.timeout
            case .cannotFindHost, .cannotConnectToHost:
                throw NetworkError.invalidURL(url: url.absoluteString)
            default:
                throw NetworkError.requestFailed(underlyingError: urlError)
            }
        } catch {
            throw NetworkError.requestFailed(underlyingError: URLError(.unknown))
        }
    }
    
    func handleResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else { return }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse(statusCode: httpResponse.statusCode, response: httpResponse)
        }
    }
    
    static func dateFormatter() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        return dateFormatter
    }
}

// MARK: Ping
extension NetworkService {
    func ping(url: URL) async throws -> TimeInterval {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        request.httpMethod = "HEAD" // Use HEAD for faster response
        request.timeoutInterval = 10.0 // 10 second timeout
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            try handleResponse(response)
            
            let endTime = CFAbsoluteTimeGetCurrent()
            return endTime - startTime
        } catch let urlError as URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                throw NetworkError.noInternetConnection
            case .timedOut:
                throw NetworkError.timeout
            case .cannotFindHost, .cannotConnectToHost:
                throw NetworkError.invalidURL(url: url.absoluteString)
            default:
                throw NetworkError.requestFailed(underlyingError: urlError)
            }
        } catch {
            throw NetworkError.requestFailed(underlyingError: URLError(.unknown))
        }
    }
    
    func pingMultiple(url: URL, count: Int = 3) async -> PingResult {
        var times: [TimeInterval] = []
        var errors: [Error] = []
        
        for _ in 0..<count {
            do {
                let pingTime = try await ping(url: url)
                times.append(pingTime)
            } catch {
                errors.append(error)
            }
            
            // Small delay between pings
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        return PingResult(
            url: url,
            times: times,
            errors: errors,
            averageTime: times.isEmpty ? nil : times.reduce(0, +) / Double(times.count),
            minTime: times.min(),
            maxTime: times.max()
        )
    }
}

struct PingResult {
    let url: URL
    let times: [TimeInterval]
    let errors: [Error]
    let averageTime: TimeInterval?
    let minTime: TimeInterval?
    let maxTime: TimeInterval?
    
    var successRate: Double {
        let totalAttempts = times.count + errors.count
        return totalAttempts > 0 ? Double(times.count) / Double(totalAttempts) : 0.0
    }
    
    var formattedAverageTime: String {
        guard let avgTime = averageTime else { return "N/A" }
        return String(format: "%.0f ms", avgTime * 1000)
    }
}
