//
//  CollectionsView.swift
//  Alethia
//
//  Created by Angelo Carasig on 13/4/2025.
//

import SwiftUI

struct CollectionsView: View {
    @EnvironmentObject private var vm: DetailsViewModel
    
    let columns = [
        GridItem(.flexible(), spacing: Constants.Spacing.large),
        GridItem(.flexible(), spacing: Constants.Spacing.large),
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
        VStack(alignment: .leading, spacing: Constants.Spacing.regular) {
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
            
            LazyVGrid(columns: columns, spacing: Constants.Spacing.regular) {
                ForEach(collections, id: \.name) { collection in
                    HStack(spacing: Constants.Spacing.regular) {
                        Image(systemName: "square.grid.2x2.fill")
                        
                        Text(collection.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .lineLimit(3)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(Constants.Padding.regular)
                    .padding(.vertical, Constants.Padding.regular)
                    .background(.tint.opacity(0.5))
                    .cornerRadius(Constants.Corner.Radius.regular)
                }
            }
        }
        .opacity(vm.inLibrary ? 1 : 0.5)
    }
}

private struct ManageCollectionsView: View {
    var body: some View {
        Text("Hi")
    }
}
