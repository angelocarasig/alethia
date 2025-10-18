//
//  SourceGridPageSheet.swift
//  Presentation
//
//  Created by Angelo Carasig on 18/10/2025.
//

import SwiftUI

struct SourceGridPageSheet: View {
    let currentPage: Int
    let totalPages: Int
    let onPageSelect: (Int) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(
                    columns: Array(
                        repeating: GridItem(.flexible(), spacing: dimensions.spacing.regular),
                        count: 4
                    ),
                    spacing: dimensions.spacing.regular
                ) {
                    ForEach(1...totalPages, id: \.self) { page in
                        pageButton(page)
                    }
                }
                .padding(dimensions.padding.screen)
            }
            .navigationTitle("Jump to Page")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(theme.colors.accent)
                }
            }
        }
    }
    
    func pageButton(_ page: Int) -> some View {
        let isCurrentPage = page == currentPage
        
        return Button {
            onPageSelect(page)
        } label: {
            Text("\(page)")
                .font(.headline)
                .fontWeight(isCurrentPage ? .bold : .medium)
                .foregroundColor(isCurrentPage ? .white : theme.colors.foreground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, dimensions.padding.screen)
                .background(isCurrentPage ? theme.colors.accent : theme.colors.tint)
                .cornerRadius(dimensions.cornerRadius.button)
        }
        .buttonStyle(.plain)
    }
}
