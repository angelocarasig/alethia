//
//  DefaultsProvider.swift
//  Alethia
//
//  Created by Angelo Carasig on 12/6/2025.
//

import Foundation
import Combine

final class DefaultsProvider: ObservableObject {
    static let shared = DefaultsProvider()
    
    private let userDefaults: UserDefaults
    
    // MARK: - Keys
    private enum Keys: String {
        case librarySortType = "library.sort.type"
        case librarySortDirection = "library.sort.direction"
    }
    
    // MARK: - Library Settings
    @Published var librarySortType: LibrarySortType {
        didSet {
            userDefaults.set(librarySortType.rawValue, forKey: Keys.librarySortType.rawValue)
        }
    }
    
    @Published var librarySortDirection: LibrarySortDirection {
        didSet {
            userDefaults.set(librarySortDirection.rawValue, forKey: Keys.librarySortDirection.rawValue)
        }
    }
    
    // MARK: - Initialization
    private init() {
        self.userDefaults = UserDefaults(suiteName: Constants.App.groupIdentifier) ?? .standard
        
        let savedSortType = userDefaults.string(forKey: Keys.librarySortType.rawValue)
        self.librarySortType = LibrarySortType(rawValue: savedSortType ?? "") ?? .title
        
        let savedSortDirection = userDefaults.string(forKey: Keys.librarySortDirection.rawValue)
        self.librarySortDirection = LibrarySortDirection(rawValue: savedSortDirection ?? "") ?? .descending
    }
}

// MARK: - Convenience Methods
extension DefaultsProvider {
    func resetLibrarySorting() {
        librarySortType = .title
        librarySortDirection = .descending
    }
    
    var libraryPublisher: AnyPublisher<(type: LibrarySortType, direction: LibrarySortDirection), Never> {
        Publishers.CombineLatest($librarySortType, $librarySortDirection)
            .map { (type: $0, direction: $1) }
            .eraseToAnyPublisher()
    }
}
