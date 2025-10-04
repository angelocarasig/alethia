//
//  Auth.swift
//  Domain
//
//  Created by Angelo Carasig on 27/9/2025.
//

import Foundation

public enum Auth: Equatable {
    case none
    case basic(fields: BasicAuthFields)
    case session(fields: SessionAuthFields)
    case apiKey(fields: ApiKeyAuthFields)
    case bearer(fields: BearerAuthFields)
    case cookie(fields: CookieAuthFields)
}

public enum AuthType: String, Codable {
    case none = "none"
    case basic = "basic"
    case session = "session"
    case apiKey = "apiKey"
    case bearer = "bearer"
    case cookie = "cookie"
}

public struct BasicAuthFields: Equatable {
    public let username: String
    public let password: String
}

public struct SessionAuthFields: Equatable {
    public let username: String
    public let password: String
}

public struct ApiKeyAuthFields: Equatable {
    public let apiKey: String
}

public struct BearerAuthFields: Equatable {
    public let token: String
}

public struct CookieAuthFields: Equatable {
    public let cookie: String
}
