//
//  Source.swift
//  Domain
//
//  Created by Angelo Carasig on 27/9/2025.
//

import Foundation

public struct Source {
    public let id: Int64
    
    public let slug: String
    
    public let name: String
    
    /// Local path to the icon, which should be a .png for transparency support
    public let icon: URL
    
    public let pinned: Bool
    
    public let disabled: Bool
    
    /// Host details styled to @hostAuthor/hostName
    public let host: String
    
    /// The specified auth config for this source
    public let auth: Auth
    
    /// The specified search config for this source
    public let search: Search
}
