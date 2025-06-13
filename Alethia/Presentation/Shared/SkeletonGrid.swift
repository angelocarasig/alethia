//
//  SkeletonGrid.swift
//  Alethia
//
//  Created by Angelo Carasig on 5/6/2025.
//

import Core
import SwiftUI

private struct SkeletonItem: Identifiable {
    let id: Int
}

struct SkeletonGrid: View {
    private let items = (0..<12).map { SkeletonItem(id: $0) }
    private let gridColumns = Array(repeating: GridItem(.flexible(), spacing: .Spacing.minimal), count: 3)
    
    var body: some View {
        CollectionViewGrid(
            data: items,
            id: \.id,
            columns: 3,
            spacing: .Spacing.regular,
            showsScrollIndicator: false,
            content: { _ in
                SkeletonCard()
            }
        )
    }
}

private struct SkeletonCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .aspectRatio(2/3, contentMode: .fit)
                .shimmer()
            
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 12)
                    .shimmer()
                
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(width: 80)
                    .shimmer()
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 8)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}
