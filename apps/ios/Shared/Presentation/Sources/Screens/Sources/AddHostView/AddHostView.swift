//
//  AddHostView.swift
//  Presentation
//
//  Created by Angelo Carasig on 4/10/2025.
//

import SwiftUI
import Domain

public struct AddHostView: View {
    @State private var viewModel = AddHostViewModel()
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            Form {
                Section("Host URL") {
                    TextField("https://api.example.com", text: $viewModel.urlText)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .disabled(viewModel.isLoading)
                    
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                if let manifest = viewModel.validatedManifest {
                    Section("Host Details") {
                        LabeledContent("Name", value: manifest.name)
                        LabeledContent("Author", value: manifest.author)
                        LabeledContent("Sources", value: "\(manifest.sources.count)")
                    }
                    
                    Section("Sources") {
                        ForEach(manifest.sources, id: \.slug) { source in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(source.name)
                                        .font(.headline)
                                    Text("Languages: \(source.languages.joined(separator: ", "))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if source.nsfw {
                                    Text("NSFW")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.red.opacity(0.2))
                                        .cornerRadius(4)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Host")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(viewModel.isLoading)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.validatedManifest == nil {
                        Button("Validate") {
                            Task {
                                await viewModel.validateURL()
                            }
                        }
                        .disabled(viewModel.urlText.isEmpty || viewModel.isLoading)
                    } else {
                        Button("Save") {
                            Task {
                                await viewModel.saveHost()
                                dismiss()
                            }
                        }
                        .disabled(viewModel.isLoading)
                    }
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.3))
                }
            }
        }
    }
}
