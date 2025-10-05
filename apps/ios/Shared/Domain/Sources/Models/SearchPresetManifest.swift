//
//  SearchPresetManifest.swift
//  Domain
//
//  Created by Angelo Carasig on 5/10/2025.
//

import Foundation

public struct SearchPresetManifest: Codable, Sendable {
    public let name: String
    public let description: String?
    public let request: PresetRequest
}

/// The request portion of a search preset
public struct PresetRequest: Codable, Sendable {
    public let query: String
    public let page: Int
    public let limit: Int
    public let sort: String
    public let direction: String
    public let filters: [FilterOption: FilterValue]?
    
    public init(
        query: String,
        page: Int,
        limit: Int,
        sort: String,
        direction: String,
        filters: [FilterOption: FilterValue]?
    ) {
        self.query = query
        self.page = page
        self.limit = limit
        self.sort = sort
        self.direction = direction
        self.filters = filters
    }
    
    // custom coding keys
    private enum CodingKeys: String, CodingKey {
        case query, page, limit, sort, direction, filters
    }
    
    // custom decoding to handle dictionary with enum keys and heterogeneous values
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // decode simple fields
        query = try container.decode(String.self, forKey: .query)
        page = try container.decode(Int.self, forKey: .page)
        limit = try container.decode(Int.self, forKey: .limit)
        sort = try container.decode(String.self, forKey: .sort)
        direction = try container.decode(String.self, forKey: .direction)
        
        // decode filters if present
        if try container.contains(.filters) && !(try container.decodeNil(forKey: .filters)) {
            // first decode as a generic json structure
            let rawFilters = try container.decode([String: Any].self, forKey: .filters)
            var typedFilters = [FilterOption: FilterValue]()
            
            for (key, value) in rawFilters {
                // convert string key to FilterOption enum
                guard let filterOption = FilterOption(rawValue: key) else {
                    throw DecodingError.dataCorrupted(
                        DecodingError.Context(
                            codingPath: decoder.codingPath + [CodingKeys.filters],
                            debugDescription: "Unknown filter option: '\(key)'"
                        )
                    )
                }
                
                // convert the value to FilterValue based on its type
                let filterValue: FilterValue
                
                if let stringValue = value as? String {
                    filterValue = .string(stringValue)
                } else if let numberValue = value as? Int {
                    filterValue = .number(numberValue)
                } else if let boolValue = value as? Bool {
                    filterValue = .boolean(boolValue)
                } else if let arrayValue = value as? [Any] {
                    // check if array contains strings
                    if let stringArray = arrayValue as? [String] {
                        filterValue = .stringArray(stringArray)
                    } else {
                        throw DecodingError.typeMismatch(
                            FilterValue.self,
                            DecodingError.Context(
                                codingPath: decoder.codingPath + [CodingKeys.filters],
                                debugDescription: "Filter '\(key)' has unsupported array type"
                            )
                        )
                    }
                } else {
                    throw DecodingError.typeMismatch(
                        FilterValue.self,
                        DecodingError.Context(
                            codingPath: decoder.codingPath + [CodingKeys.filters],
                            debugDescription: "Filter '\(key)' has unsupported value type: \(type(of: value))"
                        )
                    )
                }
                
                typedFilters[filterOption] = filterValue
            }
            
            filters = typedFilters.isEmpty ? nil : typedFilters
        } else {
            filters = nil
        }
    }
    
    // custom encoding to handle dictionary with enum keys
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // encode simple fields
        try container.encode(query, forKey: .query)
        try container.encode(page, forKey: .page)
        try container.encode(limit, forKey: .limit)
        try container.encode(sort, forKey: .sort)
        try container.encode(direction, forKey: .direction)
        
        // encode filters with enum keys converted to strings
        if let filters = filters {
            var stringKeyedFilters = [String: Any]()
            
            for (filterOption, filterValue) in filters {
                let key = filterOption.rawValue
                
                switch filterValue {
                case .string(let value):
                    stringKeyedFilters[key] = value
                case .stringArray(let values):
                    stringKeyedFilters[key] = values
                case .number(let value):
                    stringKeyedFilters[key] = value
                case .boolean(let value):
                    stringKeyedFilters[key] = value
                }
            }
            
            try container.encode(stringKeyedFilters, forKey: .filters)
        } else {
            try container.encodeNil(forKey: .filters)
        }
    }
}

// extension to decode [String: Any] dictionary
extension KeyedDecodingContainer {
    func decode(_ type: [String: Any].Type, forKey key: Key) throws -> [String: Any] {
        let container = try nestedContainer(keyedBy: JSONCodingKey.self, forKey: key)
        return try container.decode(type)
    }
    
    func decode(_ type: [String: Any].Type) throws -> [String: Any] {
        var dictionary = [String: Any]()
        
        for key in allKeys {
            if let boolValue = try? decode(Bool.self, forKey: key) {
                dictionary[key.stringValue] = boolValue
            } else if let intValue = try? decode(Int.self, forKey: key) {
                dictionary[key.stringValue] = intValue
            } else if let doubleValue = try? decode(Double.self, forKey: key) {
                dictionary[key.stringValue] = doubleValue
            } else if let stringValue = try? decode(String.self, forKey: key) {
                dictionary[key.stringValue] = stringValue
            } else if let arrayValue = try? decode([Any].self, forKey: key) {
                dictionary[key.stringValue] = arrayValue
            } else if let nestedDictionary = try? decode([String: Any].self, forKey: key) {
                dictionary[key.stringValue] = nestedDictionary
            }
        }
        
        return dictionary
    }
    
    func decode(_ type: [Any].Type, forKey key: Key) throws -> [Any] {
        var container = try nestedUnkeyedContainer(forKey: key)
        return try container.decode(type)
    }
}

extension UnkeyedDecodingContainer {
    mutating func decode(_ type: [Any].Type) throws -> [Any] {
        var array = [Any]()
        
        while !isAtEnd {
            if let boolValue = try? decode(Bool.self) {
                array.append(boolValue)
            } else if let intValue = try? decode(Int.self) {
                array.append(intValue)
            } else if let doubleValue = try? decode(Double.self) {
                array.append(doubleValue)
            } else if let stringValue = try? decode(String.self) {
                array.append(stringValue)
            } else if let nestedArray = try? decode([Any].self) {
                array.append(nestedArray)
            } else if let nestedDictionary = try? decode([String: Any].self) {
                array.append(nestedDictionary)
            }
        }
        
        return array
    }
    
    mutating func decode(_ type: [String: Any].Type) throws -> [String: Any] {
        let container = try nestedContainer(keyedBy: JSONCodingKey.self)
        return try container.decode(type)
    }
}

// helper for dynamic json keys
struct JSONCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }
    
    init(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
}

// extension for encoding [String: Any]
extension KeyedEncodingContainer {
    mutating func encode(_ value: [String: Any], forKey key: Key) throws {
        var container = nestedContainer(keyedBy: JSONCodingKey.self, forKey: key)
        try container.encode(value)
    }
    
    mutating func encode(_ value: [String: Any]) throws {
        for (k, v) in value {
            let key = JSONCodingKey(stringValue: k)
            
            if let boolValue = v as? Bool {
                try encode(boolValue, forKey: key as! K)
            } else if let intValue = v as? Int {
                try encode(intValue, forKey: key as! K)
            } else if let doubleValue = v as? Double {
                try encode(doubleValue, forKey: key as! K)
            } else if let stringValue = v as? String {
                try encode(stringValue, forKey: key as! K)
            } else if let arrayValue = v as? [Any] {
                try encode(arrayValue, forKey: key as! K)
            } else if let dictValue = v as? [String: Any] {
                try encode(dictValue, forKey: key as! K)
            }
        }
    }
    
    mutating func encode(_ value: [Any], forKey key: Key) throws {
        var container = nestedUnkeyedContainer(forKey: key)
        try container.encode(value)
    }
}

extension UnkeyedEncodingContainer {
    mutating func encode(_ value: [Any]) throws {
        for v in value {
            if let boolValue = v as? Bool {
                try encode(boolValue)
            } else if let intValue = v as? Int {
                try encode(intValue)
            } else if let doubleValue = v as? Double {
                try encode(doubleValue)
            } else if let stringValue = v as? String {
                try encode(stringValue)
            } else if let arrayValue = v as? [Any] {
                try encode(arrayValue)
            } else if let dictValue = v as? [String: Any] {
                try encode(dictValue)
            }
        }
    }
    
    mutating func encode(_ value: [String: Any]) throws {
        var container = nestedContainer(keyedBy: JSONCodingKey.self)
        try container.encode(value)
    }
}
