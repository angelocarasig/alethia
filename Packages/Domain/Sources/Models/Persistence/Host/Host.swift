//
//  Host.swift
//  Domain
//
//  Created by Angelo Carasig on 14/6/2025.
//

import Foundation

public extension Domain.Models.Persistence {
    /// represents a content host provider in the system
    struct Host: Identifiable, Codable, Sendable {
        // MARK: - Properties
        
        /// unique database identifier
        public var id: Int64?
        
        /// display name of the host provider
        public var name: String
        
        /// creator/maintainer of this host
        public var author: String
        
        /// url to the source code repository
        public var repository: String
        
        /// base url for api requests
        public var baseUrl: String
        
        /// creates a new host with validation
        ///
        /// throwable init for validation with following rules:
        /// - name/author don't contain url-unsafe characters
        /// - url properties are properly formatted
        public init(
            id: Int64? = nil,
            name: String,
            author: String,
            repository: String,
            baseUrl: String
        ) throws {
            self.id = id
            self.name = name.lowercased()
            self.author = author.lowercased()
            self.repository = repository
            self.baseUrl = baseUrl
            
            try validate()
        }
        
        // MARK: - Coding Keys
        public enum CodingKeys: String, CodingKey {
            case id
            case name
            case author
            case repository
            case baseUrl
        }
    }
}

// MARK: - Validators
private extension Domain.Models.Persistence.Host {
    static let invalidatingSet = CharacterSet(charactersIn: "/\\?#@!$&'()*+,;=:")
    
    func validate() throws {
        try validateName()
        try validateAuthor()
        try validateRepository()
        try validateBaseUrl()
    }
    
    func validateName() throws {
        try validateRequired(name, parameter: "name")
        try validateCharacters(name, parameter: "name") { error in
            Domain.Models.Persistence.HostError.invalidName(error)
        }
    }
    
    func validateAuthor() throws {
        try validateRequired(author, parameter: "author")
        try validateCharacters(author, parameter: "author") { error in
            Domain.Models.Persistence.HostError.invalidAuthor(error)
        }
    }
    
    func validateRepository() throws {
        try validateRequired(repository, parameter: "repository")
        
        guard let url = URL(string: repository) else {
            throw Domain.Models.Persistence.HostError.invalidRepository(URL(string: "invalid://")!, reason: "Invalid URL format")
        }
        
        guard url.scheme != nil else {
            throw Domain.Models.Persistence.HostError.invalidRepository(url, reason: "Missing URL scheme")
        }
        
        guard url.host != nil else {
            throw Domain.Models.Persistence.HostError.invalidRepository(url, reason: "Missing host domain")
        }
    }
    
    func validateBaseUrl() throws {
        try validateRequired(baseUrl, parameter: "baseUrl")
        
        guard let url = URL(string: baseUrl) else {
            throw HostError.invalidURL(URL(string: "invalid://")!, reason: "Invalid URL format")
        }
        
        guard let scheme = url.scheme, ["http", "https"].contains(scheme) else {
            throw HostError.invalidURL(url, reason: "Must use http or https")
        }
        
        guard url.host != nil else {
            throw HostError.invalidURL(url, reason: "Missing host domain")
        }
    }
    
    func validateRequired(_ value: String, parameter: String) throws {
        guard !value.isEmpty else {
            throw HostError.emptyValue("", parameter: parameter)
        }
    }
    
    func validateCharacters(_ value: String, parameter: String, errorBuilder: (String) -> HostError) throws {
        if value.rangeOfCharacter(from: Self.invalidatingSet) != nil {
            throw errorBuilder(value)
        }
    }
}
