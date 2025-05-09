//
//  MetadataView.swift
//  Alethia
//
//  Created by Angelo Carasig on 4/2/2025.
//

import SwiftUI

struct MetadataView: View {
    @EnvironmentObject private var vm: DetailsViewModel
    
    var details: Detail {
        vm.details.unsafelyUnwrapped
    }
    
    var origin: Origin {
        details.origins.min(by: { $0.priority < $1.priority })!
    }
    
    var createdAt: Date {
        origin.createdAt
    }
    
    var updatedAt: Date {
        details.manga.updatedAt
    }
    
    var body: some View {
        Text("Additional Information")
            .font(.title2)
            .fontWeight(.bold)
        
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Content Rating")
                        .font(.headline)
                    
                    Text(origin.classification.rawValue)
                        .font(.subheadline)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(origin.classification.color)
                        .cornerRadius(8)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Date Created")
                        .font(.headline)
                    
                    HStack {
                        Image(systemName: "calendar")
                        Text(origin.createdAt.toRelativeString())
                            .font(.subheadline)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.tint.opacity(0.5))
                    .cornerRadius(8)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 10) {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Publish Status")
                        .font(.headline)
                    
                    Text(origin.status.rawValue)
                        .font(.subheadline)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(origin.status.color)
                        .cornerRadius(8)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Last Updated")
                        .font(.headline)
                    
                    HStack {
                        Image(systemName: "calendar")
                        Text(updatedAt.toRelativeString())
                            .font(.subheadline)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.tint.opacity(0.5))
                    .cornerRadius(8)
                }
            }
        }
    }
}

