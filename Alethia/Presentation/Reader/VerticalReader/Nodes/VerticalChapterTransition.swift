//
//  VerticalChapterTransition.swift
//  Alethia
//
//  Created by Angelo Carasig on 9/5/2025.
//

import SwiftUI
import Combine

struct VerticalChapterTransition: View {
    @Environment(\.dismiss) private var dismiss
    
    let transition: ReaderTransition
    
    private var titleText: String {
        transition.direction == .previous ? "Now Reading" : "End of Chapter"
    }
    
    private var buttonText: String {
        transition.direction == .previous ? "Previous Chapter" : "Next Chapter"
    }
    
    private var missingText: String {
        "There is no \(transition.direction == .previous ? "previous" : "next") chapter."
    }
    
    var body: some View {
        ContentView()
    }
    
    @ViewBuilder
    private func ContentView() -> some View {
        VStack(spacing: 20) {
            Spacer()
            VStack(spacing: Constants.Spacing.regular) {
                Text(titleText)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                Text(transition.from.chapter.toString())
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text(transition.from.scanlator.name)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let target = transition.to {
                HStack {
                    VStack(alignment: .leading, spacing: Constants.Spacing.large) {
                        Text(buttonText)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        VStack(alignment: .leading, spacing: Constants.Spacing.minimal) {
                            Text(target.chapter.toString())
                                .font(.headline)
                                .foregroundColor(.primary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                            Text(target.scanlator.name)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.title)
                        .foregroundStyle(.secondary)
                }
                .padding(Constants.Padding.screen)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.tint.opacity(0.3))
                .cornerRadius(Constants.Corner.Radius.button)
                .padding(.horizontal)
            } else {
                Text(missingText)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            Button {
                dismiss()
            } label: {
                Text("Exit")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                    .background(
                        RoundedRectangle(cornerRadius: Constants.Corner.Radius.button)
                            .fill(Color.blue.opacity(0.1))
                    )
            }
            .padding(.horizontal)
            Spacer()
        }
    }
}
