//
//  CollectionsView.swift
//  Alethia
//
//  Created by Angelo Carasig on 13/4/2025.
//

import SwiftUI

struct CollectionsView: View {
    @EnvironmentObject private var vm: DetailsViewModel
    
    var details: Detail {
        vm.details.unsafelyUnwrapped
    }
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]
    
    let collections: [Collection] = [
        Collection(name: """
            a really really really really really really really really really really 
            really really really really really really really really really really 
            really really really really really really really really really really 
            long name
        """),
        Collection(name: "1234"),
        Collection(name: "1235"),
        Collection(name: "1236")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            NavigationLink(destination: ManageCollectionsView()) {
                HStack {
                    Text("Collections")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Image(systemName: "chevron.right")
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(collections, id: \.name) { collection in
                    HStack(spacing: 8) {
                        Image(systemName: "square.grid.2x2.fill")
                        
                        Text(collection.name)
                            .lineLimit(4)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(12)
                    .background(.tint.opacity(0.5))
                    .cornerRadius(8)
                }
            }
        }
        .opacity(details.manga.inLibrary ? 1 : 0.5)
    }
}

private struct ManageCollectionsView: View {
    var body: some View {
        Text("Hi")
    }
}
