//
//  DatabaseModel.swift
//  Alethia
//
//  Created by Angelo Carasig on 9/4/2025.
//

import Foundation
import GRDB

protocol DatabaseModel: DatabaseMigratable {
    static var version: Version { get }
}
