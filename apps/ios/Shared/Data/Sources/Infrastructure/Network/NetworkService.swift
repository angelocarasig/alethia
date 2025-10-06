//
//  NetworkService.swift
//  Data
//
//  Created by Angelo Carasig on 17/11/2024.
//

import Foundation

public final class NetworkService: Sendable {
    private let decoder: JSONDecoder
    
    init() {
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // try multiple date formats
            let formatters = [
                NetworkService.isoDateFormatter(),      // 2019-08-25T10:51:55+00:00
                NetworkService.millisecondDateFormatter() // 2019-08-25T10:51:55.123Z
            ]
            
            for formatter in formatters {
                if let date = formatter.date(from: dateString) {
                    return date
                }
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
    
    // iso 8601 with timezone offset (2019-08-25T10:51:55+00:00)
    static func isoDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }
    
    // iso 8601 with milliseconds (2019-08-25T10:51:55.123Z)
    static func millisecondDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }
}
