//
//  DeleteHostUseCase.swift
//  Alethia
//
//  Created by Angelo Carasig on 9/5/2025.
//

import Foundation

protocol DeleteHostUseCase {
    func execute(_ host: Host) throws -> Void
}

final class DeleteHostUseCaseImpl: DeleteHostUseCase {
    private var repository: SourcesRepository
    
    init(repository: SourcesRepository) {
        self.repository = repository
    }
    
    func execute(_ host: Host) throws -> Void {
        try repository.deleteHost(host: host)
    }
}
