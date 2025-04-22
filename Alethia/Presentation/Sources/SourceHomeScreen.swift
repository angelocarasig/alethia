//
//  SourceHomeScreen.swift
//  Alethia
//
//  Created by Angelo Carasig on 18/4/2025.
//

import SwiftUI
import Combine

struct SourceHomeScreen: View {
    var source: Source
    
    var routes: [SourceRoute] {
        (try? DatabaseProvider.shared.reader.read { db in
            try source.routes.fetchAll(db)
        }) ?? []
    }
    
    var body: some View {
        ScrollView {
            ForEach(routes) { route in
                RowView(route: route)
            }
        }
        .navigationTitle(source.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    Button(action: {}) {
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
    
    var route: SourceRoute
    
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
        .padding(.horizontal)
        .task {
            guard vm.firstLoad else { return }
            await vm.load(with: route.id!)
        }
    }
    
    @ViewBuilder
    private func HeaderView(title: String) -> some View {
        NavigationLink(destination: SourceRouteScreen(route: route)) {
            HStack {
                Text(route.name)
                    .font(.title)
                    .fontWeight(.semibold)
                Image(systemName: "arrow.right")
            }
            .foregroundStyle(.text)
        }
    }
    
    @ViewBuilder
    private func ContentView(content: [Entry]) -> some View {
        if content.isEmpty {
            EmptyContent()
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 4) {
                    ForEach(content, id: \.self) { entry in
                        SourceCardView(namespace: namespace, entry: entry)
                            .frame(width: 150)
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
                    .padding(.horizontal, 4)
                    .cornerRadius(6)
                    .frame(width: 150)
                }
            }
        }
    }
    
    @ViewBuilder
    private func EmptyContent() -> some View {
        VStack(alignment: .center, spacing: 12) {
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
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding()
        .background(Color.tint)
        .cornerRadius(8)
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
