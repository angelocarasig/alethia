//
//  Data.swift
//  Data
//
//  Created by Angelo Carasig on 13/6/2025.
//

import Domain

typealias Persistence = Domain.Models.Persistence
typealias Virtual = Domain.Models.Virtual

public struct Data {
    public struct Infrastructure {}
    public struct DataSources {}
    public struct Repositories {}
    public struct Database {}
    
    private init() {}
}