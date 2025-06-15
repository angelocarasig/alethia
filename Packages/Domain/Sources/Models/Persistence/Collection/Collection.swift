//
//  Collection.swift
//  Domain
//
//  Created by Angelo Carasig on 14/6/2025.
//

import Foundation

public extension Domain.Models.Persistence {
    /// acts as a way to group manga with some extra metadata (mainly visual)
    struct Collection: Identifiable, Codable, Sendable, Equatable {
        // MARK: - Properties
        
        public static let minimumNameLength = 3
        public static let maximumNameLength = 20
        
        /// unique database identifier
        public var id: Int64?
        
        /// name of the collection
        public var name: String
        
        /// hex color string (e.g., "#FF0000")
        public var color: String
        
        /// sf symbol icon
        public var icon: String
        
        /// display ordering for collections
        public var ordering: Int = 0
        
        /// creates a new collection with validation
        ///
        /// throwable init for validation with following rules:
        /// - name must be within length constraints
        /// - color must be valid hex format
        /// - icon must not be empty
        public init(
            id: Int64? = nil,
            name: String,
            color: String,
            icon: String,
            ordering: Int = 0
        ) throws {
            self.id = id
            self.name = name
            self.color = color
            self.icon = icon
            self.ordering = ordering
            
            try validate()
        }
        
        // MARK: - Coding Keys
        public enum CodingKeys: String, CodingKey {
            case id
            case name
            case color
            case icon
            case ordering
        }
    }
}

// MARK: - Validators
extension Domain.Models.Persistence.Collection {
    static let hexColorPattern = "^#[0-9A-Fa-f]{6}$"
    
    func validate() throws {
        try validateName()
        try validateColor()
        try validateIcon()
    }
    
    func validateName() throws {
        try validateRequired(name, parameter: "name")
        
        guard name.count >= Self.minimumNameLength else {
            throw Domain.Models.Persistence.CollectionError.minimumLengthNotReached(name.count)
        }
        
        guard name.count <= Self.maximumNameLength else {
            throw Domain.Models.Persistence.CollectionError.maximumLengthReached(name.count)
        }
        
        // check for reserved names if needed
        let reservedNames = ["all", "default", "new", "none"]
        if reservedNames.contains(name.lowercased()) {
            throw Domain.Models.Persistence.CollectionError.badName(name)
        }
    }
    
    func validateColor() throws {
        try validateRequired(color, parameter: "color")
        
        // validate hex color format
        let colorRegex = try NSRegularExpression(pattern: Self.hexColorPattern)
        let range = NSRange(location: 0, length: color.utf16.count)
        
        guard colorRegex.firstMatch(in: color, options: [], range: range) != nil else {
            throw Domain.Models.Persistence.CollectionError.invalidColor(color, reason: "Must be hex format (#RRGGBB)")
        }
    }
    
    func validateIcon() throws {
        try validateRequired(icon, parameter: "icon")
    }
    
    func validateRequired(_ value: String, parameter: String) throws {
        guard !value.isEmpty else {
            throw Domain.Models.Persistence.CollectionError.emptyValue("", parameter: parameter)
        }
    }
}
