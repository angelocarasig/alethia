//
//  LanguageCode.swift
//  Domain
//
//  Created by Angelo Carasig on 28/9/2025.
//

/// Subject to changes as for now I listed common translation outputs for countries
public struct LanguageCode: Codable, Sendable, Hashable, RawRepresentable {
    public let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue.lowercased()
    }
    
    public init(_ value: String) {
        self.rawValue = value.lowercased()
    }
    
    public var flag: String {
        switch rawValue {
        case "en": return "🇬🇧"
        case "ja", "ja-ro": return "🇯🇵"
        case "ko": return "🇰🇷"
        case "zh-hans", "zh": return "🇨🇳"
        case "zh-hant": return "🇹🇼"
        case "es": return "🇪🇸"
        case "es-419", "es-la": return "🇲🇽"
        case "fr": return "🇫🇷"
        case "de": return "🇩🇪"
        case "it": return "🇮🇹"
        case "pt": return "🇵🇹"
        case "pt-br": return "🇧🇷"
        case "ru": return "🇷🇺"
        case "ar": return "🇸🇦"
        case "th": return "🇹🇭"
        case "vi": return "🇻🇳"
        case "id": return "🇮🇩"
        case "tr": return "🇹🇷"
        case "pl": return "🇵🇱"
        case "nl": return "🇳🇱"
        case "hu": return "🇭🇺"
        case "cs": return "🇨🇿"
        case "sv": return "🇸🇪"
        case "fil", "tl": return "🇵🇭"
        default: return "🌐"
        }
    }
}
