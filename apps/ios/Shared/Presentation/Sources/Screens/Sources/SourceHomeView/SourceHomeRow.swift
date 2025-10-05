//
//  File.swift
//  Presentation
//
//  Created by Angelo Carasig on 5/10/2025.
//

import Foundation
import SwiftUI
import Composition
import Domain

@MainActor
@Observable
private final class SourceHomeRowViewModel {
    @ObservationIgnored
    private let searchWithPresetUseCase: SearchWithPresetUseCase
    
    private let source: Source
    private let preset: SearchPreset
    
    init(source: Source, preset: SearchPreset) {
        self.source = source
        self.preset = preset
        
        self.searchWithPresetUseCase = Injector.makeSearchWithPresetUseCase()
    }
    
    func search() {
        Task {
            do {
                let result = try await searchWithPresetUseCase.execute(source: source, preset: preset)
                
                print(result)
            }
            catch {
                print(error)
            }
        }
    }
}

struct SourceHomeRow: View {
    @State private var vm: SourceHomeRowViewModel
    
    let source: Source
    let preset: SearchPreset
    
    init(source: Source, preset: SearchPreset) {
        self.source = source
        self.preset = preset
        
        self.vm = SourceHomeRowViewModel(source: source, preset: preset)
    }
    
    var body: some View {
        Button {
            vm.search()
        } label: {
            Text("Search for \(source.name) (\(preset.name))")
        }
    }
}
