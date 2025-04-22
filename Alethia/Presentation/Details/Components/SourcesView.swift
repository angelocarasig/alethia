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
    
    var details: Detail {
        vm.details!
    }
    
    var body: some View {
        let origins = details.origins.sorted { $0.priority < $1.priority }
        
        VStack(alignment: .leading, spacing: 16) {
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
            .disabled(!details.manga.inLibrary)
            
            VStack(spacing: 20) {
                ForEach(origins, id: \.id) { origin in
                    SourceRow(origin)
                        .disabled(origin.sourceId == nil)
                }
            }
        }
        .opacity(details.manga.inLibrary ? 1 : 0.5)
    }
    
    @ViewBuilder
    private func SourceRow(_ origin: Origin) -> some View {
        let sourceDisabled = origin.sourceId == nil
        
        HStack(spacing: 12) {
            KFImage(URL(fileURLWithPath: ""))
                .placeholder {
                    Color.gray.opacity(0.3)
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 48, height: 48)
                .cornerRadius(12)
                .grayscale(sourceDisabled ? 1 : 0)
            
            VStack(alignment: .leading, spacing: 4) {
                // TODO:
                Text("Some Source")
                    .font(.headline)
                
                Text("Some Host")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text("69 Chapters")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if let originURL = URL(string: origin.url) {
                HStack(spacing: 16) {
                    Button {
                        UIPasteboard.general.string = originURL.absoluteString
                        //                        let drop = Drop(
                        //                            title: "Copied to clipboard!",
                        //                            icon: UIImage(systemName: "checkmark")?.withTintColor(.green, renderingMode: .alwaysOriginal),
                        //                            position: .top
                        //                        )
                        //                        Drops.show(drop)
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
                .padding(.leading, 8)
            }
        }
        .opacity(sourceDisabled ? 0.5 : 1.0)
        .foregroundStyle(sourceDisabled ? .gray : .text)
        .contextMenu {
            if let originURL = URL(string: origin.url) {
                Button {
                    UIPasteboard.general.string = originURL.absoluteString
                    //                    let drop = Drop(
                    //                        title: "Copied to clipboard!",
                    //                        icon: UIImage(systemName: "checkmark")?.withTintColor(.green, renderingMode: .alwaysOriginal),
                    //                        position: .top
                    //                    )
                    //                    Drops.show(drop)
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
