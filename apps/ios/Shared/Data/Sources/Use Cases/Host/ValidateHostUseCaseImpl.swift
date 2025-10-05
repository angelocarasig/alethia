//
//  ValidateHostURLUseCaseImpl.swift
//  Data
//
//  Created by Angelo Carasig on 4/10/2025.
//

import Foundation
import Domain

public final class ValidateHostURLUseCaseImpl: ValidateHostURLUseCase {
    private let repository: HostRepository
    
    public init(repository: HostRepository) {
        self.repository = repository
    }
    
    public func execute(url: URL) async throws -> HostDTO {
        // business rule: validate url format before passing to repository
        guard url.scheme == "https" || url.scheme == "http" else {
            throw UseCaseError.invalidURLScheme
        }
        
        return try await repository.validateHost(url: url)
    }
}
