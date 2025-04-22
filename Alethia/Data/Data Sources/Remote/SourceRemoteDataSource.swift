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
    
    func getSourceRouteContent(sourceRouteId: Int64, page: Int) async throws -> [Entry] {
        let sourceFetching: SourceFetching = try await DatabaseProvider.shared.reader.read { db in
            guard let route = try SourceRoute.filter(id: sourceRouteId).fetchOne(db),
                  let source = try Source.filter(id: route.sourceId).fetchOne(db),
                  let host = try Host.filter(id: source.hostId).fetchOne(db)
            else { throw ApplicationError.internalError }
            
            return SourceFetching(host: host, source: source, route: route)
        }
        
        guard var urlComponents = URLComponents(string: sourceFetching.fetchUrl) else { throw NetworkError.missingURL }
        
        urlComponents.queryItems = [URLQueryItem(name: "page", value: String(page))]
        
        guard let url = urlComponents.url else {
            throw NetworkError.missingURL
        }
        
        let dto: [EntryDTO] = try await networkService.request(url: url)
        
        return dto.map { item in
            Entry(
                mangaId: nil,
                sourceId: sourceFetching.source.id,
                title: item.title,
                cover: item.cover,
                fetchUrl: sourceFetching.itemUrl(item.slug),
                unread: nil
            )
        }
    }
}
