//
//  ButtonModal.swift
//  Presentation
//
//  Created by Angelo Carasig on 4/10/2025.
//

import SwiftUI

struct ButtonModal<Header: View, Content: View>: View {
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var showingModal = false
    @State private var showingPopover = false
    
    let buttonIcon: String
    let modalTitle: String
    let header: () -> Header
    let content: () -> Content
    
    var body: some View {
        if isInModal {
            Button(action: { showingPopover = true }) {
                Image(systemName: buttonIcon)
                    .foregroundColor(theme.colors.accent)
            }
            .popover(isPresented: $showingPopover) {
                PopoverContent()
            }
        } else {
            Button(action: { showingModal = true }) {
                Image(systemName: buttonIcon)
                    .foregroundColor(theme.colors.accent)
            }
            .sheet(isPresented: $showingModal) {
                ModalContent()
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
    }
    
    private var isInModal: Bool {
        presentationMode.wrappedValue.isPresented
    }
}

extension ButtonModal {
    init(
        buttonIcon: String,
        modalIcon: String? = nil,
        modalTitle: String,
        modalText: String
    ) where Header == AnyView, Content == AnyView {
        self.buttonIcon = buttonIcon
        self.modalTitle = modalTitle
        
        self.header = {
            AnyView(
                Text(modalTitle)
                    .font(.title3)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
            )
        }
        
        self.content = {
            AnyView(
                Text(modalText)
                    .font(.body)
                    .foregroundColor(.primary.opacity(0.8))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            )
        }
    }
    
    init(
        buttonIcon: String,
        modalIcon: String? = nil,
        modalTitle: String,
        @ViewBuilder content: @escaping () -> Content
    ) where Header == AnyView {
        self.buttonIcon = buttonIcon
        self.modalTitle = modalTitle
        self.content = content
        
        self.header = {
            AnyView(
                Text(modalTitle)
                    .font(.title3)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
            )
        }
    }
}

private extension ButtonModal {
    @ViewBuilder
    func ModalContent() -> some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: dimensions.spacing.screen) {
                    header()
                        .padding(.top, dimensions.padding.screen)
                    
                    content()
                    
                    Spacer(minLength: dimensions.spacing.screen)
                }
            }
            .navigationTitle(modalTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingModal = false
                    }
                    .foregroundColor(theme.colors.accent)
                }
            }
        }
    }
    
    @ViewBuilder
    func PopoverContent() -> some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: buttonIcon)
                    .font(.title3)
                    .foregroundColor(theme.colors.accent)
                    .symbolRenderingMode(.hierarchical)
                
                Spacer()

                Text(modalTitle)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.colors.foreground)
                    .lineLimit(1)
                
                Spacer()
                
                Button(action: { showingPopover = false }) {
                    Image(systemName: "xmark")
                        .font(.footnote)
                        .foregroundColor(theme.colors.accent)
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)
            }
            .padding(dimensions.padding.screen)
            
            Divider()
            
            ScrollView {
                content()
                    .font(.footnote)
                .padding(.horizontal, dimensions.padding.screen)
                .padding(.vertical, dimensions.padding.regular)
            }
            .frame(maxHeight: 300)
        }
        .frame(width: 320)
        .background(theme.colors.tint)
        .presentationCompactAdaptation(.popover)
    }
}

