//
//  LanguageCode.swift
//  Domain
//
//  Created by Angelo Carasig on 28/9/2025.
//

import Foundation

/// represents an iso 639-1 language code with regional variants
/// supports mapping to localized display names and flag emojis
public struct LanguageCode: Codable, Sendable, Hashable, RawRepresentable {
    public let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue.lowercased()
    }
    
    public init(_ value: String) {
        self.rawValue = value.lowercased()
    }
    
    /// emoji flag representing the primary region for this language
    public var flag: String {
        switch rawValue {
        // english
        case "en": return "🇬🇧"
        case "en-us": return "🇺🇸"
        case "en-gb": return "🇬🇧"
        case "en-au": return "🇦🇺"
        case "en-ca": return "🇨🇦"
        
        // japanese
        case "ja", "ja-ro": return "🇯🇵"
        
        // korean
        case "ko": return "🇰🇷"
        
        // chinese
        case "zh-hans", "zh", "zh-cn": return "🇨🇳"
        case "zh-hant", "zh-tw": return "🇹🇼"
        case "zh-hk": return "🇭🇰"
        
        // spanish
        case "es": return "🇪🇸"
        case "es-419", "es-la", "es-mx": return "🇲🇽"
        case "es-ar": return "🇦🇷"
        
        // portuguese
        case "pt": return "🇵🇹"
        case "pt-br": return "🇧🇷"
        
        // french
        case "fr": return "🇫🇷"
        case "fr-ca": return "🇨🇦"
        
        // german
        case "de": return "🇩🇪"
        case "de-at": return "🇦🇹"
        case "de-ch": return "🇨🇭"
        
        // italian
        case "it": return "🇮🇹"
        
        // russian
        case "ru": return "🇷🇺"
        
        // arabic
        case "ar": return "🇸🇦"
        case "ar-eg": return "🇪🇬"
        
        // southeast asian
        case "th": return "🇹🇭"
        case "vi": return "🇻🇳"
        case "id": return "🇮🇩"
        case "ms": return "🇲🇾"
        case "fil", "tl": return "🇵🇭"
        
        // european
        case "tr": return "🇹🇷"
        case "pl": return "🇵🇱"
        case "nl": return "🇳🇱"
        case "hu": return "🇭🇺"
        case "cs": return "🇨🇿"
        case "sv": return "🇸🇪"
        case "da": return "🇩🇰"
        case "no", "nb": return "🇳🇴"
        case "fi": return "🇫🇮"
        case "ro": return "🇷🇴"
        case "el": return "🇬🇷"
        case "bg": return "🇧🇬"
        case "uk": return "🇺🇦"
        
        // other asian
        case "hi": return "🇮🇳"
        case "bn": return "🇧🇩"
        case "ur": return "🇵🇰"
        case "fa": return "🇮🇷"
        case "he": return "🇮🇱"
        case "mn": return "🇲🇳"
        case "my": return "🇲🇲"
        
        // other
        case "ca": return "🇪🇸"  // catalan
        case "lt": return "🇱🇹"
        case "lv": return "🇱🇻"
        case "et": return "🇪🇪"
        case "sr": return "🇷🇸"
        case "hr": return "🇭🇷"
        case "sk": return "🇸🇰"
        case "sl": return "🇸🇮"
        
        default: return "🌐"
        }
    }
    
    /// localized display name for the language
    /// falls back to uppercase code if no locale match found
    public var displayName: String {
        let locale = Locale.current
        
        // try to get localized name from system
        if let localizedName = locale.localizedString(forLanguageCode: rawValue) {
            return localizedName.capitalized
        }
        
        // fallback to manual mappings for common codes
        switch rawValue {
        case "en": return "English"
        case "ja", "ja-ro": return "Japanese"
        case "ko": return "Korean"
        case "zh-hans", "zh": return "Chinese (Simplified)"
        case "zh-hant": return "Chinese (Traditional)"
        case "es": return "Spanish"
        case "es-419", "es-la": return "Spanish (Latin America)"
        case "pt": return "Portuguese"
        case "pt-br": return "Portuguese (Brazil)"
        case "fr": return "French"
        case "de": return "German"
        case "it": return "Italian"
        case "ru": return "Russian"
        case "ar": return "Arabic"
        case "th": return "Thai"
        case "vi": return "Vietnamese"
        case "id": return "Indonesian"
        case "tr": return "Turkish"
        case "pl": return "Polish"
        case "nl": return "Dutch"
        case "hu": return "Hungarian"
        case "cs": return "Czech"
        case "sv": return "Swedish"
        case "fil", "tl": return "Filipino"
        default: return rawValue.uppercased()
        }
    }
    
    /// combined flag and display name for ui presentation
    public var flagWithName: String {
        "\(flag) \(displayName)"
    }
}
