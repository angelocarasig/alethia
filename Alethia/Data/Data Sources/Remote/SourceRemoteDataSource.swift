//
//  SourceRemoteDataSource.swift
//  Alethia
//
//  Created by Angelo Carasig on 18/4/2025.
//

import Foundation
import GRDB

final class SourceRemoteDataSource {
    private let networkService: NetworkService
    
    init() {
        self.networkService = NetworkService()
    }
    
    func testHost(url: String) async throws -> NewHostPayload {
        guard let request = URL(string: url) else {
            throw ApplicationError.urlBuildingFailed("Could not build URL from string: \(url)")
        }
        
        let host: HostDTO = try await networkService.request(url: request)
        
        var payload: NewHostPayload = NewHostPayload(name: host.name, baseUrl: request.absoluteString)
        
        for source in host.sources {
            guard let sourceURL = URL.appendingPaths(request.absoluteString, source.path) else {
                throw ApplicationError.urlBuildingFailed("Could not build URL parts: \(request.absoluteString) | \(source.path)")
            }
            
            guard let iconURL = URL.appendingPaths(request.absoluteString, "icons", source.icon) else {
                throw ApplicationError.urlBuildingFailed("Could not build URL parts: \(request.absoluteString) | icons | \(source.icon)")
            }
            
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
    
    func searchSource(source: Source, query: String, page: Int) async throws -> [Entry] {
        let (host, url): (Host, URL) = try await DatabaseProvider.shared.reader.read { db in
            guard let host = try Host.filter(id: source.hostId).fetchOne(db) else {
                throw HostError.notFound
            }
            
            guard let requestUrl: URL = URL.appendingPaths(
                host.baseUrl,
                source.path,
                "search"
            )
            else { throw ApplicationError.urlBuildingFailed("Could not build URL parts: \(host.baseUrl) | \(source.path) | search") }
            
            // this part shouldn't fail ever ideally
            guard var urlComponents = URLComponents(string: requestUrl.absoluteString) else { throw ApplicationError.internalError }
            
            urlComponents.queryItems = [
                URLQueryItem(name: "query", value: query),
                URLQueryItem(name: "page", value: String(page)),
            ]
            
            guard let url = urlComponents.url else { throw ApplicationError.internalError }
            
            return (host, url)
        }
        
        let dto: [EntryDTO] = try await networkService.request(url: url)
        
        return dto.map { item in
            Entry(
                mangaId: nil,
                sourceId: source.id,
                title: item.title,
                cover: item.cover,
                fetchUrl: URL.appendingPaths(
                    host.baseUrl,
                    source.path,
                    "manga",
                    item.slug
                )!.absoluteString
            )
        }
    }
    
    func getSourceRouteContent(sourceRouteId: Int64, page: Int) async throws -> [Entry] {
        let sourceFetching: SourceFetching = try await DatabaseProvider.shared.reader.read { db in
            guard let route = try SourceRoute.filter(id: sourceRouteId).fetchOne(db) else {
                throw SourceError.routeNotFound(id: sourceRouteId)
            }
            
            guard let source = try Source.filter(id: route.sourceId).fetchOne(db) else {
                throw SourceError.notFound
            }
            
            guard let host = try Host.filter(id: source.hostId).fetchOne(db) else {
                throw HostError.notFound
            }
            
            return SourceFetching(host: host, source: source, route: route)
        }
        
        // Should not happen ever, ideally
        guard var urlComponents = URLComponents(string: sourceFetching.fetchUrl) else { throw ApplicationError.internalError }
        
        urlComponents.queryItems = [URLQueryItem(name: "page", value: String(page))]
        
        guard let url = urlComponents.url else {
            throw ApplicationError.internalError
        }
        
        let dto: [EntryDTO] = try await networkService.request(url: url)
        
        return dto.map { item in
            Entry(
                mangaId: nil,
                sourceId: sourceFetching.source.id,
                title: item.title,
                cover: item.cover,
                fetchUrl: sourceFetching.itemUrl(item.slug)
            )
        }
    }
}

