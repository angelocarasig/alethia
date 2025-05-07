//
//  ContinueReadingView.swift
//  Alethia
//
//  Created by Angelo Carasig on 7/5/2025.
//

import SwiftUI

struct ContinueReadingView: View {
    @EnvironmentObject private var vm: DetailsViewModel

    private let buttonSize = CGSize(width: 150, height: 50)

    var body: some View {
        VStack {
            Spacer()

            HStack {
                Spacer()

                Group {
                    if let chapter = vm.details?.chapters.first(where: { !$0.chapter.read }) {
//                    if false {
                        Button {
                            // TODO: Handle chapter navigation
                        } label: {
                            HStack(spacing: 18) {
                                Image(systemName: "play.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 18, weight: .bold))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Continue")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)

                                    Text("Chapter \(chapter.chapter.number.toString())")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                            .frame(width: buttonSize.width, height: buttonSize.height)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.accentColor.opacity(0.95))
                                    .shadow(radius: 4, y: 2)
                            )
                        }
                        .buttonStyle(.plain)
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 18, weight: .bold))

                            Text("All Chapters Read")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                        )
                    }
                }
            }
        }
        .padding(16)
    }
}
