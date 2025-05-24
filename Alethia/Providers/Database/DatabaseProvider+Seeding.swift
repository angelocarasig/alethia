//
//  DatabaseProvider+Seeding.swift
//  Alethia
//
//  Created by Angelo Carasig on 10/4/2025.
//

import Foundation
import GRDB

extension DatabaseProvider {
    @available(*, deprecated, message: "Only use for testing purposes")
    func seed(_ writer: DatabaseWriter) throws {
//        try writer.write { db in
//            let url = "some url"
//            let dto = mockHostDTO
//            
//            let host: Host = try Host.findOrCreate(db, instance: Host(name: dto.name, baseUrl: url))
//            
//            guard let hostId = host.id else { fatalError("Was not able to properly create Host") }
//            
//            let sources: [Source] = dto.sources.map {
//                Source(
//                    name: $0.name,
//                    icon: $0.icon,
//                    path: $0.path,
//                    hostId: hostId
//                )
//            }
//            
//            for source in sources {
//                let inserted = try source.insertAndFetch(db)
//                
//                guard let sourceId = inserted.id else { fatalError("Was not able to properly create source") }
//                
//                // Mock a fetch to get source routes
//                let routesDTO = mockSourceRouteDTO
//                
//                for routeDTO in routesDTO {
//                    let route = SourceRoute(
//                        name: routeDTO.name,
//                        path: routeDTO.path,
//                        sourceId: sourceId
//                    )
//                    
//                    try route.insert(db)
//                }
//            }
//        }
    }
}
