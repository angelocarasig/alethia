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
    
    private var pinned: [SourceMetadata] {
        vm.sources.filter { $0.source.pinned }
    }
    
    private var active: [SourceMetadata] {
        vm.sources.filter { !$0.source.pinned && !$0.source.disabled }
    }
    
    private var disabled: [SourceMetadata] {
        vm.sources.filter { $0.source.disabled }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Pinned - \(pinned.count) Source\(pinned.count == 1 ? "" : "s")")) {
                    ForEach(pinned, id: \.source.id) { source in
                        SourceRow(source: source)
                    }
                }
                
                Section(header: Text("Active - \(active.count) Source\(active.count == 1 ? "" : "s")")) {
                    ForEach(active, id: \.source.id) { source in
                        SourceRow(source: source)
                    }
                }
                
                Section(header: Text("Disabled - \(disabled.count) Source\(disabled.count == 1 ? "" : "s")")) {
                    ForEach(disabled, id: \.source.id) { source in
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
    let source: SourceMetadata
    
    enum PingStatus {
        case idle
        case loading
        case success
        case failed
        
        var color: Color {
            switch self {
            case .idle, .loading:
                return .gray
            case .success:
                return .green
            case .failed:
                return .red
            }
        }
    }
    
    private var pingText: String {
        switch pingStatus {
        case .idle:
            return "Idle"
        case .loading:
            return "..."
        case .success:
            return pingTime
        case .failed:
            return "Error"
        }
    }
    
    @State private var pingStatus: PingStatus = .idle
    @State private var pingTime: String = ""
    
    var body: some View {
        NavigationLink(destination: SourceHomeScreen(source: source.source)) {
            HStack {
                KFImage(URL(filePath: source.source.icon))
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
                    Text(source.source.name)
                        .lineLimit(1)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text("@\(source.hostAuthor)/\(source.hostName)")
                        .lineLimit(1)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .textCase(.lowercase)
                }
                
                Spacer()
                
                PingSection()
            }
            .contextMenu {
                // Pin
                let pinned = source.source.pinned
                Button {
                    // TODO: Drops for if failed
                    try? vm.togglePinned(source: source.source)
                } label: {
                    Text(pinned ? "Unpin Source" : "Pin Source")
                    Image(systemName: pinned ? "pin.fill" : "pin")
                }
                
                // Disabled
                let disabled = source.source.disabled
                Button {
                    // TODO: Drops for if failed
                    try? vm.toggleDisabled(source: source.source)
                } label: {
                    Text(disabled ? "Enable Source" : "Disable Source")
                    Image(systemName: disabled ? "slash.circle.fill" : "slash.circle")
                }
            }
        }
    }
    
    @ViewBuilder
    private func PingSection() -> some View {
        VStack(spacing: 8) {
            Circle()
                .fill(pingStatus.color)
                .frame(width: 12, height: 12)
            
            Text(pingText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .task {
            await performPing()
        }
    }
    
    private func performPing() async {
        pingStatus = .loading
        
        do {
            let result = try await vm.pingSource(source)
            pingTime = result
            pingStatus = .success
        } catch {
            pingStatus = .failed
        }
    }
}

private final class SourcesViewModel: ObservableObject {
    @Published var sources: [SourceMetadata] = []
    @Published var openAddSourceSheet: Bool = false
    
    @Published private(set) var testResponse: NewHostPayload? = nil
    @Published private(set) var loading: Bool = false
    @Published private(set) var error: String? = nil
    
    private var cancellables = Set<AnyCancellable>()
    private let ns = NetworkService() // for pinging
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
    
    func pingSource(_ source: SourceMetadata) async throws -> String {
        let result = try await ns.ping(url: URL(string: source.pingUrl)!)
        
        return String(format: "%.0f ms", result * 1000)
    }
}
