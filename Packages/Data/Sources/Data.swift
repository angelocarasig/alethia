//
//  Data.swift
//  Data
//
//  Created by Angelo Carasig on 13/6/2025.
//

import Domain

typealias Database = Domain.Models.Database
typealias Persistence = Domain.Models.Persistence
typealias Virtual = Domain.Models.Virtual

public struct Data {
    public struct DataSources {}
    public struct Network {}
    public struct Repositories {}
    
    private init() {}
}
