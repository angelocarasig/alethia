//
//  SourcePanel.swift
//  Domain
//
//  Created by Angelo Carasig on 14/6/2025.
//

import GRDB

internal typealias SourcePanel = Domain.Models.Presentation.SourcePanel

public extension Domain.Models.Presentation {
    /// db-fetching persistence model
    struct SourcePanelItem: Decodable, FetchableRecord {
        public let host: Domain.Models.Persistence.Host
        public let source: Domain.Models.Persistence.Source
        public let route: Domain.Models.Persistence.SourceRoute
    }
    
    /// presentation model to work with
    struct SourcePanel {
        public let hosts: [HostInfo]
        
        public struct HostInfo {
            public let host: Domain.Models.Persistence.Host
            public let sources: [SourceInfo]
        }
        
        public struct SourceInfo {
            public let source: Domain.Models.Persistence.Source
            public let routes: [Domain.Models.Persistence.SourceRoute]
        }
        
        init(items: [SourcePanelItem]) {
            let grouped = Dictionary(grouping: items, by: { $0.host.id })
            
            self.hosts = grouped.map { (hostId, items) in
                // Safe: grouping guarantees non-empty
                let host = items.first!.host
                let sourceGroups = Dictionary(grouping: items, by: { $0.source.id })
                
                let sources = sourceGroups.map { (sourceId, sourceItems) in
                    SourceInfo(
                        // Safe: grouping guarantees non-empty
                        source: sourceItems.first!.source,
                        routes: sourceItems.map { $0.route }
                    )
                }
                
                return HostInfo(host: host, sources: sources)
            }
        }
    }
}
