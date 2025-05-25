//
//  SourceHomeScreen.swift
//  Alethia
//
//  Created by Angelo Carasig on 18/4/2025.
//

import SwiftUI
import Combine
import Kingfisher

struct SourceHomeScreen: View {
    @State private var headerEntries: [Entry] = []
    
    var source: Source
    
    // TODO: Convert to use-case
    var routes: [SourceRoute] {
        (try? DatabaseProvider.shared.reader.read { db in
            try source.routes.fetchAll(db)
        }) ?? []
    }
    
    var images: [String] {
        headerEntries
            .filter { $0.cover != nil }
            .map { $0.cover! }
    }
    
    var body: some View {
        ScrollView {
            SourceHeaderView(source: source, images: images)

            ForEach(routes) { route in
                RowView(
                    source: source,
                    route: route,
                    onRandom: { entry in
                        headerEntries.append(entry)
                    }
                )
            }
            .offset(y: -69)
        }
        .navigationBarTitle(source.name)
        .navigationBarTitleDisplayMode(.inline)
        .edgesIgnoringSafeArea(.top)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: Constants.Spacing.toolbar) {
                    NavigationLink(destination: SearchSourceView(source: source)) {
                        Image(systemName: "magnifyingglass")
                    }
                    
                    Button(action: {}) {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
        }
    }
}

private struct RowView: View {
    @Namespace private var namespace
    @StateObject private var vm = ViewModel()
    @State private var didSend: Lock = .unlocked
    
    var source: Source
    var route: SourceRoute
    let onRandom: (Entry) -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            HeaderView(title: route.name)
            
            if vm.loading {
                SkeletonView()
            }
            else {
                ContentView(content: vm.items)
            }
        }
        .padding(.horizontal, 10)
        .onReceive(vm.$items) { items in
            guard !items.isEmpty, !didSend else { return }
            didSend = .locked
            onRandom(items.randomElement()!)
        }
        .task {
            guard vm.firstLoad else { return }
            await vm.load(with: route.id!)
        }
    }
    
    @ViewBuilder
    private func HeaderView(title: String) -> some View {
        NavigationLink(destination: SourceRouteScreen(source: source, route: route)) {
            HStack {
                Text(route.name)
                    .font(.title)
                    .fontWeight(.semibold)
                Image(systemName: "arrow.right")
            }
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func ContentView(content: [Entry]) -> some View {
        if content.isEmpty {
            EmptyContent()
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: Constants.Spacing.minimal) {
                    ForEach(content, id: \.id) { entry in
                        SourceCardView(namespace: namespace, source: source, entry: entry)
                            .frame(width: 150)
                            .id("\(route.path)/\(entry.id)")
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func SkeletonView() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack {
                ForEach(0..<10, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: 10) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 150, height: 150 * 16 / 11)
                            .shimmer()
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 130, height: 14)
                            .shimmer()
                        
                        Spacer()
                    }
                    .padding(.horizontal, Constants.Padding.minimal)
                    .cornerRadius(6)
                    .frame(width: 150)
                }
            }
        }
    }
    
    @ViewBuilder
    private func EmptyContent() -> some View {
        VStack(alignment: .center, spacing: Constants.Spacing.large) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
                .font(.largeTitle)
            
            Text("Failed to Fetch")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Please check your connection or try again later.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                Task { await vm.load(with: route.id!) }
            }) {
                Text("Retry")
                    .fontWeight(.semibold)
                    .padding(.horizontal, Constants.Padding.regular)
                    .padding(.vertical, Constants.Padding.minimal)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding()
        .background(Color.tint)
        .cornerRadius(Constants.Corner.Radius.regular)
        .padding(.horizontal)
    }
}

private final class ViewModel: ObservableObject {
    @Published private(set) var loading: Bool = true
    @Published private(set) var firstLoad: Bool = true
    @Published var items: [Entry] = []
    
    /**
     Seperating raw with the `matched` objects which if not done:
     - Lose the original entries (can't reapply match logic)
     - Have to refetch them every time the library changes (wasted effort)
     */
    private var raw: [Entry] = []
    private var cancellables = Set<AnyCancellable>()
    
    private let getSourceRouteContentUseCase: GetSourceRouteContentUseCase
    private let observeMatchEntriesUseCase: ObserveMatchEntriesUseCase
    
    init() {
        self.getSourceRouteContentUseCase = DependencyInjector.shared.makeGetSourceRouteContentUseCase()
        self.observeMatchEntriesUseCase = DependencyInjector.shared.makeObserveMatchEntriesUseCase()
    }
    
    @MainActor
    func load(with id: Int64) async {
        withAnimation { loading = true }
        
        do {
            let results = try await getSourceRouteContentUseCase.execute(sourceRouteId: id)
            raw = results
            bind()
        } catch {
            print("Error: \(error)")
        }
        
        withAnimation {
            loading = false
            firstLoad = false
        }
    }
    
    private func bind() {
        guard !raw.isEmpty else { return }
        
        cancellables.removeAll()
        
        observeMatchEntriesUseCase
            .execute(entries: raw)
            .receive(on: RunLoop.main)
            .sink { [weak self] updated in
                self?.items = updated
            }
            .store(in: &cancellables)
    }
}
