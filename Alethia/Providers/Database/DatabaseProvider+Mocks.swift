//
//  DatabaseProvider+Mocks.swift
//  Alethia
//
//  Created by Angelo Carasig on 24/4/2025.
//

import Foundation
import GRDB

// TODO: Mocking

#if canImport(Testing)
//extension DatabaseProvider {
//    func createMocks() throws {
//        try writer.write { db in
//            _ = "some url"
//            let dto = mockHostDTO
//            
//            let hostId = try createMockHost(db)
//            _ = try createMockSources(db, dto: dto, hostId: hostId)
//            
//        }
//    }
//}
//
//// Returns mock host ID
//func createMockHost(_ db: Database) throws -> Int64 {
//    let url = "some url"
//    let dto = mockHostDTO
//    
//    let host: Host = try Host.findOrCreate(db, instance: Host(name: dto.name, baseUrl: url))
//    
//    return host.id!
//}
//
//func createMockSources(_ db: Database, dto: HostDTO, hostId: Int64) throws -> [Source] {
//    let sources: [Source] = dto.sources.map {
//        Source(
//            name: $0.name,
//            icon: $0.icon,
//            path: $0.path,
//            hostId: hostId
//        )
//    }
//    
//    for source in sources {
//        let inserted = try source.insertAndFetch(db)
//        
//        guard let sourceId = inserted.id else { fatalError("Was not able to properly create source") }
//        
//        // Mock a fetch to get source routes
//        let routesDTO = mockSourceRouteDTO
//        
//        for routeDTO in routesDTO {
//            let route = SourceRoute(
//                name: routeDTO.name,
//                path: routeDTO.path,
//                sourceId: sourceId
//            )
//            
//            try route.insert(db)
//        }
//    }
//    
//    return sources
//}
#endif
