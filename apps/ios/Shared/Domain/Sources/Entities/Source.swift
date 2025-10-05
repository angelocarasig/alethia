//
//  Source.swift
//  Domain
//
//  Created by Angelo Carasig on 27/9/2025.
//

import Foundation

public struct Source: Sendable {
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
    
    public let presets: [SearchPreset]
    
    public init(
        id: Int64,
        slug: String,
        name: String,
        icon: URL,
        pinned: Bool,
        disabled: Bool,
        host: String,
        auth: Auth,
        search: Search,
        presets: [SearchPreset]
    ) {
        self.id = id
        self.slug = slug
        self.name = name
        self.icon = icon
        self.pinned = pinned
        self.disabled = disabled
        self.host = host
        self.auth = auth
        self.search = search
        self.presets = presets
    }
}
