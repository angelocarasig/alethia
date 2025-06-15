//
//  Details+GRDB.swift
//  Data
//
//  Created by Angelo Carasig on 15/6/2025.
//

import GRDB
import Domain

private typealias Details = Domain.Models.Virtual.Details

// MARK: - Database Conformance
extension Details: @retroactive FetchableRecord {}

