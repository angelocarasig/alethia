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
            if oldValue != hostURL && validatedManifest != nil {
                errorMessage = nil
                validatedManifest = nil
                validatedHostURL = nil
            }
        }
    }
    
    private(set) var isLoading: Bool = false
    private(set) var isSaving: Bool = false
    private(set) var errorMessage: String?
    private(set) var validatedManifest: HostManifest?
    
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
            validatedManifest = nil
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let manifest = try await validateHostUseCase.execute(url: url)
            validatedManifest = manifest
            validatedHostURL = url
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func saveHost() async -> Bool {
        guard let manifest = validatedManifest,
              let hostURL = validatedHostURL else { return false }
        
        isSaving = true
        errorMessage = nil
        
        do {
            _ = try await saveHostUseCase.execute(manifest: manifest, hostURL: hostURL)
            isSaving = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            validatedManifest = nil
            isSaving = false
            return false
        }
    }
    
    func clearError() -> Void {
        errorMessage = nil
    }
}
