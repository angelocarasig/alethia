//
//  SourceRemoteDataSource.swift
//  Alethia
//
//  Created by Angelo Carasig on 18/4/2025.
//

import Foundation

final class SourceRemoteDataSource {
    private let networkService: NetworkService
    
    init() {
        self.networkService = NetworkService()
    }
    
    func testHost(url: String) async throws -> NewHostPayload {
        guard let request = URL(string: url) else { throw NetworkError.invalidURL(url: url) }
        
        let host: HostDTO = try await networkService.request(url: request)
        
        var payload: NewHostPayload = NewHostPayload(name: host.name, baseUrl: request.absoluteString)
        
        for source in host.sources {
            guard let sourceURL = URL.appendingPaths(request.absoluteString, source.path),
                  let iconURL = URL.appendingPaths(request.absoluteString, "icons", source.icon)
            else { throw NetworkError.invalidURL(url: url) }
            
            let routeResponse: [SourceRouteDTO] = try await networkService.request(url: sourceURL)
            
            payload.sources.append(NewHostPayload.Source(
                name: source.name,
                path: source.path,
                icon: iconURL.absoluteString,
                paths: routeResponse.map { route in
                    NewHostPayload.SourceRoute(name: route.name, path: route.path)
                }
            ))
        }
        
        return payload
    }
}
