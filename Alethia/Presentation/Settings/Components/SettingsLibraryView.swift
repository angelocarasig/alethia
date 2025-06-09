//
//  SettingsLibraryView.swift
//  Alethia
//
//  Created by Angelo Carasig on 9/6/2025.
//

import SwiftUI
import Combine

struct SettingsLibraryView: View {
    @StateObject private var viewModel = SettingsLibraryViewModel()
    @State private var editMode: EditMode = .inactive
    
    var body: some View {
        List {
            collectionsSection
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Library Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
                    .disabled(viewModel.collections.isEmpty)
            }
        }
        .environment(\.editMode, $editMode)
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                withAnimation {
                    viewModel.errorMessage = nil
                }
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    private var collectionsSection: some View {
        Section {
            if viewModel.collections.isEmpty {
                ContentUnavailableView("No Collections",
                                       systemImage: "folder",
                                       description: Text("Create collections to organize your manga"))
            } else {
                ForEach(viewModel.collections, id: \.collection.id) { extendedCollection in
                    CollectionRow(
                        collection: extendedCollection.collection,
                        itemCount: extendedCollection.itemCount
                    )
                }
                .onMove(perform: viewModel.moveCollections)
            }
        } header: {
            Text("Collections")
        } footer: {
            if !viewModel.collections.isEmpty {
                Text("Drag to reorder collections. This will affect how they appear throughout the app.")
                    .foregroundColor(.secondary)
                    .font(.footnote)
            }
        }
    }
}

private struct CollectionRow: View {
    let collection: Collection
    let itemCount: Int
    
    var body: some View {
        HStack(spacing: Constants.Spacing.large) {
            Image(systemName: collection.icon)
                .font(.title3)
                .foregroundColor(Color(hex: collection.color))
                .frame(width: 28, height: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(collection.name)
                    .font(.body)
                
                Text("^[\(itemCount) item](inflect: true)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, Constants.Padding.minimal)
    }
}

@MainActor
final class SettingsLibraryViewModel: ObservableObject {
    @Published var collections: [CollectionExtended] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let getAllCollectionsUseCase: GetAllCollectionsUseCase
    private let updateCollectionOrderUseCase: UpdateCollectionOrderUseCase
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.getAllCollectionsUseCase = DependencyInjector.shared.makeGetAllCollectionsUseCase()
        self.updateCollectionOrderUseCase = DependencyInjector.shared.makeUpdateCollectionOrderUseCase()
        
        observeCollections()
    }
    
    func moveCollections(from source: IndexSet, to destination: Int) {
        withAnimation {
            collections.move(fromOffsets: source, toOffset: destination)
        }
        
        let orderingMap = collections.enumerated().reduce(into: [Int64: Int]()) { result, item in
            if let id = item.element.collection.id {
                result[id] = item.offset
            }
        }
        
        Task {
            do {
                try updateCollectionOrderUseCase.execute(collections: orderingMap)
            } catch {
                withAnimation {
                    errorMessage = "Failed to update collection order: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func observeCollections() {
        getAllCollectionsUseCase.execute()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] collectionsExtended in
                withAnimation {
                    self?.collections = collectionsExtended.sorted { $0.collection.ordering < $1.collection.ordering }
                }
            }
            .store(in: &cancellables)
    }
}
