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
    public var urlText: String = "https://api.alethia.moe" {
        didSet {
            if oldValue != urlText && validatedManifest != nil {
                validatedManifest = nil
                validatedHostURL = nil
            }
        }
    }
    public private(set) var isLoading: Bool = false
    public private(set) var errorMessage: String?
    public private(set) var validatedManifest: HostManifest?
    
    @ObservationIgnored
    private var validatedHostURL: URL?
    
    @ObservationIgnored
    private let validateHostUseCase: ValidateHostURLUseCase
    @ObservationIgnored
    private let saveHostUseCase: SaveHostUseCase
    
    public init() {
        self.validateHostUseCase = Injector.makeValidateHostURLUseCase()
        self.saveHostUseCase = Injector.makeSaveHostUseCase()
    }
    
    public func validateURL() async {
        guard !urlText.isEmpty,
              let url = URL(string: urlText) else {
            errorMessage = "Please enter a valid URL"
            return
        }
        
        isLoading = true
        errorMessage = nil
        validatedManifest = nil
        validatedHostURL = nil
        
        do {
            let manifest = try await validateHostUseCase.execute(url: url)
            validatedManifest = manifest
            validatedHostURL = url
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    public func saveHost() async {
        guard let manifest = validatedManifest,
              let hostURL = validatedHostURL else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await saveHostUseCase.execute(manifest: manifest, hostURL: hostURL)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    public func clearError() {
        errorMessage = nil
    }
}
