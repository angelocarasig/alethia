//
//  SourcesView.swift
//  Alethia
//
//  Created by Angelo Carasig on 13/4/2025.
//

import SwiftUI
import Kingfisher

struct SourcesView: View {
    @EnvironmentObject var vm: DetailsViewModel
    
    var origins: [OriginExtended] {
        (vm.details?.origins ?? []).sorted { $0.origin.priority < $1.origin.priority }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.large) {
            NavigationLink(destination: SourceDetailView()) {
                HStack {
                    Text("Sources")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Image(systemName: "chevron.right")
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            
            VStack(spacing: Constants.Spacing.large) {
                ForEach(origins) { origin in
                    SourceRow(origin)
                        .disabled(origin.source == nil)
                }
            }
        }
        .disabled(!vm.inLibrary)
        .opacity(vm.inLibrary ? 1 : 0.5)
    }
    
    @ViewBuilder
    private func SourceRow(_ origin: OriginExtended) -> some View {
        let sourceDisabled = origin.source == nil
        
        HStack(spacing: Constants.Spacing.large) {
            KFImage(URL(fileURLWithPath: origin.sourceIcon))
                .placeholder {
                    Color.gray.opacity(0.3)
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(
                    width: Constants.Icon.Size.regular,
                    height: Constants.Icon.Size.regular
                )
                .cornerRadius(Constants.Corner.Radius.button)
                .grayscale(sourceDisabled ? 1 : 0)
            
            VStack(alignment: .leading, spacing: Constants.Spacing.minimal) {
                Text("\(origin.sourceName) • \(origin.sourceHost)")
                    .lineLimit(1)
                
                Text("^[\(origin.chapterCount) chapter](inflect: true)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if let originURL = URL(string: origin.origin.url) {
                HStack(spacing: Constants.Spacing.large) {
                    Button {
                        UIPasteboard.general.string = originURL.absoluteString
                    } label: {
                        Image(systemName: "link")
                            .font(.system(size: 20, weight: .medium))
                    }
                    .buttonStyle(.plain)
                    
                    Link(destination: originURL) {
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 20, weight: .medium))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.leading, Constants.Padding.regular)
            }
        }
        .disabled(sourceDisabled)
        .opacity(sourceDisabled ? 0.5 : 1.0)
        .foregroundStyle(sourceDisabled ? .gray : .text)
        .contextMenu {
            if let originURL = URL(string: origin.origin.url) {
                Button {
                    UIPasteboard.general.string = originURL.absoluteString
                } label: {
                    Label("Copy Link", systemImage: "link")
                }
                
                Link(destination: originURL) {
                    Label("Open in Browser", systemImage: "safari")
                }
            }
        }
    }
}

private struct SourceDetailView: View {
    var body: some View {
        Text("hi")
    }
}
