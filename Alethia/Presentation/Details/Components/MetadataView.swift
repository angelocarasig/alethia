//
//  MetadataView.swift
//  Alethia
//
//  Created by Angelo Carasig on 4/2/2025.
//

import SwiftUI

struct MetadataView: View {
    @EnvironmentObject private var vm: DetailsViewModel
    
    var origin: Origin? {
        (vm.details?.origins ?? []).min(by: { $0.origin.priority < $1.origin.priority })?.origin
    }
    
    var createdAt: Date {
        origin?.createdAt ?? .distantPast
    }
    
    var updatedAt: Date {
        vm.details?.manga.updatedAt ?? .distantPast
    }
    
    var body: some View {
        Text("Additional Information")
            .font(.title2)
            .fontWeight(.bold)
        
        HStack {
            VStack(alignment: .leading, spacing: Constants.Spacing.regular) {
                VStack(alignment: .leading, spacing: Constants.Spacing.regular) {
                    Text("Content Rating")
                        .font(.headline)
                    
                    let classification = origin?.classification ?? .Unknown
                    
                    Text(classification.rawValue)
                        .font(.subheadline)
                        .padding(.horizontal, Constants.Padding.regular)
                        .padding(.vertical, Constants.Padding.minimal)
                        .background(classification.color)
                        .cornerRadius(Constants.Corner.Radius.regular)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: Constants.Spacing.regular) {
                    Text("Series Start Date")
                        .font(.headline)
                    
                    HStack {
                        Image(systemName: "calendar")
                        Text(createdAt.toRelativeString())
                            .font(.subheadline)
                    }
                    .padding(.horizontal, Constants.Padding.regular)
                    .padding(.vertical, Constants.Padding.minimal)
                    .background(.tint.opacity(0.5))
                    .cornerRadius(Constants.Corner.Radius.regular)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: Constants.Spacing.regular) {
                VStack(alignment: .trailing, spacing: Constants.Spacing.regular) {
                    Text("Publish Status")
                        .font(.headline)
                    
                    let status = origin?.status ?? .Unknown
                    
                    Text(status.rawValue)
                        .font(.subheadline)
                        .padding(.horizontal, Constants.Padding.regular)
                        .padding(.vertical, Constants.Padding.minimal)
                        .background(status.color)
                        .cornerRadius(Constants.Corner.Radius.regular)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: Constants.Spacing.regular) {
                    Text("Last Updated")
                        .font(.headline)
                    
                    HStack {
                        Image(systemName: "calendar")
                        Text(updatedAt.toRelativeString())
                            .font(.subheadline)
                    }
                    .padding(.horizontal, Constants.Padding.regular)
                    .padding(.vertical, Constants.Padding.minimal)
                    .background(.tint.opacity(0.5))
                    .cornerRadius(Constants.Corner.Radius.regular)
                }
            }
        }
    }
}
