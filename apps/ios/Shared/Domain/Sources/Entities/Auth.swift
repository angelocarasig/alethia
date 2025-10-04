//
//  Auth.swift
//  Domain
//
//  Created by Angelo Carasig on 27/9/2025.
//

import Foundation

public enum Auth: Equatable, Sendable {
    case none
    case basic(fields: BasicAuthFields)
    case session(fields: SessionAuthFields)
    case apiKey(fields: ApiKeyAuthFields)
    case bearer(fields: BearerAuthFields)
    case cookie(fields: CookieAuthFields)
}

public enum AuthType: String, Codable, Sendable {
    case none = "none"
    case basic = "basic"
    case session = "session"
    case apiKey = "apiKey"
    case bearer = "bearer"
    case cookie = "cookie"
    
    public var displayText: String {
        switch self {
        case .none: return "No Auth"
        case .apiKey: return "Token Auth"
        case .basic: return "Basic Auth"
        case .bearer: return "Bearer Auth"
        case .cookie: return "Cookie Auth"
        case .session: return "Session Auth"
        }
    }
}

public struct BasicAuthFields: Equatable, Sendable {
    public let username: String
    public let password: String
    
    public init(username: String, password: String) {
        self.username = username
        self.password = password
    }
}

public struct SessionAuthFields: Equatable, Sendable {
    public let username: String
    public let password: String
    
    public init(username: String, password: String) {
        self.username = username
        self.password = password
    }
}

public struct ApiKeyAuthFields: Equatable, Sendable {
    public let apiKey: String
    
    public init(apiKey: String) {
        self.apiKey = apiKey
    }
}

public struct BearerAuthFields: Equatable, Sendable {
    public let token: String
    
    public init(token: String) {
        self.token = token
    }
}

public struct CookieAuthFields: Equatable, Sendable {
    public let cookie: String
    
    public init(cookie: String) {
        self.cookie = cookie
    }
}
