//
//  SourcesScreen.swift
//  Alethia
//
//  Created by Angelo Carasig on 18/4/2025.
//

import SwiftUI
import Kingfisher
import Combine

struct SourcesScreen: View {
    @StateObject private var vm = SourcesViewModel()
    
    private var pinned: [Source] {
        vm.sources.filter { $0.pinned }
    }
    
    private var active: [Source] {
        vm.sources.filter { !$0.pinned && !$0.disabled }
    }
    
    private var disabled: [Source] {
        vm.sources.filter { $0.disabled }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Pinned - \(pinned.count) Source\(pinned.count == 1 ? "" : "s")")) {
                    ForEach(pinned, id: \.id) { source in
                        SourceRow(source: source)
                    }
                }
                
                Section(header: Text("Active - \(active.count) Source\(active.count == 1 ? "" : "s")")) {
                    ForEach(active, id: \.id) { source in
                        SourceRow(source: source)
                    }
                }
                
                Section(header: Text("Disabled - \(disabled.count) Source\(disabled.count == 1 ? "" : "s")")) {
                    ForEach(disabled, id: \.id) { source in
                        SourceRow(source: source)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Sources")
            .environmentObject(vm)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: Constants.Spacing.toolbar) {
                        NavigationLink(destination: SearchHomeView()) {
                            Image(systemName: "magnifyingglass")
                        }
                        .disabled(vm.sources.isEmpty)
                        
                        Button(action: {
                            vm.openAddSourceSheet = true
                        }) {
                            Image(systemName: "plus")
                        }
                        
                        Button(action: {}) {
                            Image(systemName: "gearshape.fill")
                        }
                    }
                }
            }
            .sheet(isPresented: $vm.openAddSourceSheet) {
                AddSourceSheet()
                    .onAppear {
                        vm.clearResponse()
                    }
                    .environmentObject(vm)
            }
            .task {
                vm.bind()
            }
        }
    }
}

private struct AddSourceSheet: View {
    @EnvironmentObject private var vm: SourcesViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var textfieldUrl: String = "https://fortune.alethia.workers.dev"
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Enter URL", text: $textfieldUrl)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .clearButton(text: $textfieldUrl)
                        .onChange(of: textfieldUrl) {
                            vm.clearResponse()
                        }
                } header: {
                    Text("Host URL")
                } footer: {
                    VStack(alignment: .leading) {
                        if let error = vm.error {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        
                        Text("Example: https://fortune.alethia-workers.dev")
                    }
                }
                
                if let host = vm.testResponse {
                    Section(host.name) {
                        ForEach(host.sources, id: \.path) { source in
                            DisplayRow(source: source)
                        }
                    }
                }
            }
            .navigationTitle("Add Host")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    ConfirmButton()
                }
            }
            .presentationDetents([.medium])
        }
    }
    
    @ViewBuilder
    private func ConfirmButton() -> some View {
        Group {
            if let payload = vm.testResponse {
                Button("Save") {
                    Task {
                        await vm.saveHost(payload)
                    }
                }
            }
            else {
                Button {
                    Task {
                        await vm.testUrl(textfieldUrl)
                    }
                } label: {
                    if vm.loading {
                        ProgressView()
                    }
                    else {
                        Text("Test")
                    }
                }
                .disabled(textfieldUrl.isEmpty)
            }
        }
    }
    
    @ViewBuilder
    private func DisplayRow(source: NewHostPayload.Source) -> some View {
        let iconSize: CGFloat = 40
        
        HStack {
            KFImage(URL(string: source.icon))
                .placeholder { Color.tint.shimmer() }
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
                .cornerRadius(Constants.Corner.Radius.regular)
                .padding(.trailing, Constants.Padding.regular)
            
            Text(source.name)
                .font(.headline)
                .foregroundColor(.primary)
        }
    }
}

private struct SourceRow: View {
    @EnvironmentObject private var vm: SourcesViewModel
    let source: Source
    
    var body: some View {
        NavigationLink(destination: SourceHomeScreen(source: source)) {
            HStack {
                KFImage(URL(filePath: source.icon))
                    .placeholder { Color.tint.shimmer() }
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: Constants.Icon.Size.regular,
                        height: Constants.Icon.Size.regular
                    )
                    .cornerRadius(Constants.Corner.Radius.regular)
                    .padding(.trailing, Constants.Padding.regular)
                
                VStack(alignment: .leading) {
                    Text(source.name)
                        .lineLimit(1)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    // TODO: Enforce hosts to have this format
                    // maybe require author and name instead and format like so
                    Text("@alethia/fortune")
                        .lineLimit(1)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .contextMenu {
                // Pin
                let pinned = source.pinned
                Button {
                    // TODO: Drops for if failed
                    try? vm.togglePinned(source: source)
                } label: {
                    Text(pinned ? "Unpin Source" : "Pin Source")
                    Image(systemName: pinned ? "pin.fill" : "pin")
                }
                
                // Disabled
                let disabled = source.disabled
                Button {
                    // TODO: Drops for if failed
                    try? vm.toggleDisabled(source: source)
                } label: {
                    Text(disabled ? "Enable Source" : "Disable Source")
                    Image(systemName: disabled ? "slash.circle.fill" : "slash.circle")
                }
            }
        }
    }
}

private final class SourcesViewModel: ObservableObject {
    @Published var sources: [Source] = []
    @Published var openAddSourceSheet: Bool = false
    
    @Published private(set) var testResponse: NewHostPayload? = nil
    @Published private(set) var loading: Bool = false
    @Published private(set) var error: String? = nil
    
    private var cancellables = Set<AnyCancellable>()
    private let getSourcesUseCase: GetSourcesUseCase
    private let testHostUseCase: TestHostUseCase
    private let createHostUseCase: CreateHostUseCase
    private let toggleSourceDisabledUseCase: ToggleSourceDisabledUseCase
    private let toggleSourcePinnedUseCase: ToggleSourcePinnedUseCase
    
    init() {
        self.getSourcesUseCase = DependencyInjector.shared.makeGetSourcesUseCase()
        self.testHostUseCase = DependencyInjector.shared.makeTestHostUrlUseCase()
        self.createHostUseCase = DependencyInjector.shared.makeCreateHostUseCase()
        self.toggleSourcePinnedUseCase = DependencyInjector.shared.makeToggleSourcePinnedUseCase()
        self.toggleSourceDisabledUseCase = DependencyInjector.shared.makeToggleSourceDisabledUseCase()
    }
    
    func bind() {
        getSourcesUseCase.execute()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sources in
                withAnimation {
                    self?.sources = sources
                }
                print("Received \(sources.count) sources")
            }
            .store(in: &cancellables)
    }
    
    func clearResponse() -> Void {
        withAnimation {
            testResponse = nil
            loading = false
            error = nil
        }
    }
    
    @MainActor
    func testUrl(_ url: String) async -> Void {
        defer {
            withAnimation {
                loading = false
            }
        }
        
        do {
            withAnimation {
                loading = true
                error = nil
                testResponse = nil
            }
            
            let response = try await testHostUseCase.execute(url: url)
            
            withAnimation {
                testResponse = response
            }
        }
        catch {
            withAnimation {
                self.error = error.localizedDescription
            }
        }
    }
    
    @MainActor
    func saveHost(_ payload: NewHostPayload) async -> Void {
        do {
            withAnimation {
                loading = true
                error = nil
            }
            
            try await createHostUseCase.execute(payload)
            
            withAnimation {
                loading = false
                error = nil
            }
            openAddSourceSheet = false
        }
        catch {
            withAnimation {
                self.error = error.localizedDescription
            }
        }
    }
    
    func togglePinned(source: Source) throws -> Void {
        try withAnimation {
            try toggleSourcePinnedUseCase.execute(sourceId: source.id!, newValue: !source.pinned)
        }
    }
    
    func toggleDisabled(source: Source) throws -> Void {
        try withAnimation {
            try toggleSourceDisabledUseCase.execute(sourceId: source.id!, newValue: !source.disabled)
        }
    }
}
