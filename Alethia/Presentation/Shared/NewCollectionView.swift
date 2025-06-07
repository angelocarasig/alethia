//
//  NewCollectionView.swift
//  Alethia
//
//  Created by Angelo Carasig on 4/6/2025.
//

import SwiftUI

struct NewCollectionView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Callback for creating collection
    typealias CreateCollectionResult = Result<Void, Error>
    private let onCreateCollection: (String, String, String) -> CreateCollectionResult
    
    @State private var collectionName: String = ""
    @State private var selectedColor: Color = .blue
    @State private var selectedIcon: String = "folder.fill"
    @State private var isCreating: Bool = false
    @State private var showingIconPicker: Bool = false
    
    @State private var errorMessage: String? = nil
    
    // Popular icon options for quick selection
    private let popularIcons: [String] = [
        "folder.fill", "heart.fill", "star.fill", "bookmark.fill",
        "book.fill", "sparkles", "bolt.fill", "leaf.fill",
        "moon.fill", "sun.max.fill", "flame.fill", "crown.fill",
        "gamecontroller.fill", "music.note", "camera.fill", "paintbrush.fill"
    ]
    
    private var isFormValid: Bool {
        !collectionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    init(onCreateCollection: @escaping (String, String, String) -> CreateCollectionResult) {
        self.onCreateCollection = onCreateCollection
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    CollectionRowPreview(
                        name: collectionName,
                        itemCount: 0,
                        icon: selectedIcon,
                        color: selectedColor
                    )
                } header: {
                    Text("Preview")
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text(errorMessage)
                                .foregroundStyle(.red)
                                .font(.callout)
                        }
                        .padding(.vertical, Constants.Padding.minimal)
                    }
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: Constants.Corner.Radius.regular)
                            .fill(.red.opacity(0.1))
                    )
                }
                
                Section {
                    TextField("Enter collection name", text: $collectionName)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .submitLabel(.done)
                } header: {
                    Text("Collection Name")
                }
                
                Section {
                    ColorPickerRow()
                } header: {
                    Text("Color")
                }
                
                Section {
                    IconPickerGrid()
                    
                    Button {
                        showingIconPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            Text("Browse All Icons")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Icon")
                }
            }
            .listSectionSpacing(.compact)
            .navigationTitle("New Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createCollection()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isFormValid || isCreating)
                }
            }
            .sheet(isPresented: $showingIconPicker) {
                IconPickerSheet(selectedIcon: $selectedIcon, selectedColor: selectedColor)
            }
        }
    }
    
    private func createCollection() {
        guard isFormValid else { return }
        
        errorMessage = nil
        isCreating = true
        
        let result = onCreateCollection(collectionName, selectedColor.hex, selectedIcon)
        
        switch result {
        case .success:
            isCreating = false
            dismiss()
            
        case .failure(let error):
            withAnimation {
                isCreating = false
                errorMessage = error.localizedDescription
            }
        }
    }
    
    // MARK: - Form Rows
    
    private func ColorPickerRow() -> some View {
        HStack(spacing: Constants.Spacing.toolbar) {
            // Color preview circle
            Circle()
                .fill(selectedColor)
                .frame(width: 32, height: 32)
                .overlay(
                    Circle()
                        .stroke(.quaternary, lineWidth: 1)
                )
            
            Text("Collection Color")
            
            Spacer()
            
            // System color picker
            ColorPicker("", selection: $selectedColor, supportsOpacity: false)
                .labelsHidden()
                .scaleEffect(1.2)
        }
        .padding(Constants.Padding.minimal)
    }
    
    private func IconPickerGrid() -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Constants.Spacing.large), count: 4), spacing: Constants.Spacing.large) {
            ForEach(popularIcons, id: \.self) { icon in
                IconOption(icon: icon)
            }
        }
        .padding(.vertical, Constants.Padding.regular)
    }
    
    private func IconOption(icon: String) -> some View {
        let isSelected = selectedIcon == icon
        
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedIcon = icon
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: Constants.Corner.Radius.button)
                    .fill(isSelected ? selectedColor.opacity(0.15) : Color(.systemGray5))
                    .stroke(
                        isSelected ? selectedColor.opacity(0.5) : Color.clear,
                        lineWidth: 2
                    )
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(isSelected ? selectedColor : .secondary)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Icon Picker Sheet
private struct IconPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedIcon: String
    @State private var selectedColor: Color
    @State private var searchText: String = ""
    
    // Get all available SF Symbols
    private let allIcons: [String] = SymbolsProvider.getAllSymbols()
    
    init(selectedIcon: Binding<String>, selectedColor: Color) {
        self._selectedIcon = selectedIcon
        self._selectedColor = State(initialValue: selectedColor)
    }
    
    private var filteredIcons: [String] {
        if searchText.isEmpty {
            return allIcons
        } else {
            return allIcons.filter { $0.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                SearchBar(searchText: $searchText, placeholder: "Search icons...")
                    .padding(.horizontal)
                    .padding(.bottom)
                
                // Icons grid
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Constants.Spacing.large), count: 4), spacing: Constants.Spacing.large) {
                        ForEach(filteredIcons, id: \.self) { icon in
                            IconOptionLarge(icon: icon)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Choose Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func IconOptionLarge(icon: String) -> some View {
        let isSelected = selectedIcon == icon
        
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedIcon = icon
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: Constants.Corner.Radius.button)
                    .fill(isSelected ? selectedColor.opacity(0.15) : Color(.systemGray5))
                    .stroke(
                        isSelected ? selectedColor.opacity(0.5) : Color.clear,
                        lineWidth: 2
                    )
                    .frame(width: Constants.Icon.Size.large, height: Constants.Icon.Size.large)
                
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(isSelected ? selectedColor : .secondary)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}
