//
//  CollectionsView.swift
//  Alethia
//
//  Created by Angelo Carasig on 13/4/2025.
//

import SwiftUI

struct Collection {
    var name: String
}

struct CollectionsView: View {
    @EnvironmentObject private var vm: DetailsViewModel
    
    var details: Detail {
        vm.details!
    }
    
    let collections: [Collection] = [
        Collection(name: "123"),
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
            
            VStack(spacing: 12) {
                ForEach(collections, id: \.name) { collection in
                    HStack(spacing: 8) {
                        Image(systemName: "square.grid.2x2.fill")
                        
                        Text(collection.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
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
