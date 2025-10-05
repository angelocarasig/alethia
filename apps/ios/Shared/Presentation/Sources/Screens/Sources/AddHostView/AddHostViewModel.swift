//
//  AddHostViewModel.swift
//  Presentation
//
//  Created by Angelo Carasig on 4/10/2025.
//

import SwiftUI
import Composition
import Domain

@MainActor
@Observable
final class AddHostViewModel {
    var hostURL: String = "https://api.alethia.moe" {
        didSet {
            if oldValue != hostURL && validatedHost != nil {
                errorMessage = nil
                validatedHost = nil
                validatedHostURL = nil
            }
        }
    }
    
    private(set) var isLoading: Bool = false
    private(set) var isSaving: Bool = false
    private(set) var errorMessage: String?
    private(set) var validatedHost: HostDTO?
    
    @ObservationIgnored
    private var validatedHostURL: URL?
    
    @ObservationIgnored
    private let validateHostUseCase: ValidateHostURLUseCase
    @ObservationIgnored
    private let saveHostUseCase: SaveHostUseCase
    
    init() {
        self.validateHostUseCase = Injector.makeValidateHostURLUseCase()
        self.saveHostUseCase = Injector.makeSaveHostUseCase()
    }
    
    func testConnection() async {
        guard !hostURL.isEmpty,
              let url = URL(string: hostURL) else {
            errorMessage = "Please enter a valid URL"
            validatedHost = nil
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let dto = try await validateHostUseCase.execute(url: url)
            validatedHost = dto
            validatedHostURL = url
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func saveHost() async -> Bool {
        guard let dto = validatedHost,
              let hostURL = validatedHostURL else { return false }
        
        isSaving = true
        errorMessage = nil
        
        do {
            _ = try await saveHostUseCase.execute(dto, hostURL: hostURL)
            isSaving = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            validatedHost = nil
            isSaving = false
            return false
        }
    }
    
    func clearError() -> Void {
        errorMessage = nil
    }
}
