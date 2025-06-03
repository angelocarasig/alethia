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
    @State private var headerArtwork: [String] = []
    @State private var showNavTitle = false
    @StateObject private var headerViewModel = HeaderViewModel()
    
    var source: Source
    
    // TODO: Convert to use-case
    var routes: [SourceRoute] {
        (try? DatabaseProvider.shared.reader.read { db in
            try source.routes.fetchAll(db)
        }) ?? []
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack {  // Negative spacing to overlap
                SourceHeaderView(source: source, artworkUrls: headerViewModel.artworkUrls)
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .onChange(of: geo.frame(in: .global).minY) { _, newValue in
                                    // Show nav title when header is scrolled up
                                    withAnimation {
                                        showNavTitle = newValue < -100
                                    }
                                }
                        }
                    )
                
                VStack {
                    ForEach(routes) { route in
                        RowView(
                            source: source,
                            route: route,
                            headerViewModel: headerViewModel
                        )
                    }
                }
            }
        }
        .navigationBarTitle(source.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(source.name)
                    .font(.headline)
                    .opacity(showNavTitle ? 1 : 0)
            }
            
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
        .edgesIgnoringSafeArea(.top)
        .scrollBounceBehavior(.basedOnSize)
    }
}

// Shared ViewModel for collecting artwork
private final class HeaderViewModel: ObservableObject {
    @Published var artworkUrls: [String] = []
    private var maxArtwork = 10
    
    func addArtwork(from entries: [Entry]) {
        guard artworkUrls.count < maxArtwork else { return }
        
        // Add random artwork from entries that have covers
        let availableCovers = entries.compactMap { $0.cover }.filter { !artworkUrls.contains($0) }
        if let randomCover = availableCovers.randomElement() {
            withAnimation {
                artworkUrls.append(randomCover)
            }
        }
    }
}

private struct RowView: View {
    @Namespace private var namespace
    @StateObject private var vm = ViewModel()
    
    var source: Source
    var route: SourceRoute
    var headerViewModel: HeaderViewModel
    
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
            headerViewModel.addArtwork(from: items)
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
        withAnimation {
            loading = true
        }
        
        do {
            let results = try await getSourceRouteContentUseCase.execute(sourceRouteId: id)
            raw = results
            
            if results.isEmpty {
                // If no results, we can set loading = false immediately
                withAnimation {
                    loading = false
                    firstLoad = false
                }
            } else {
                // If we have results, don't set loading = false yet
                // Let the bind() method handle it when matched entries arrive
                firstLoad = false
                bind()
            }
        } catch {
            withAnimation {
                loading = false
                firstLoad = false
            }
        }
    }
    
    private func bind() {
        guard !raw.isEmpty else {
            return
        }
        
        cancellables.removeAll()
        
        observeMatchEntriesUseCase
            .execute(entries: raw)
            .receive(on: RunLoop.main)
            .sink { [weak self] updated in
                withAnimation {
                    self?.items = updated
                    self?.loading = false
                }
            }
            .store(in: &cancellables)
    }
}
