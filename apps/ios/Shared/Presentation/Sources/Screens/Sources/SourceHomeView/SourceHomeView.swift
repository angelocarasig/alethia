//
//  SourceHomeView.swift
//  Presentation
//
//  Created by Angelo Carasig on 5/10/2025.
//

import SwiftUI
import Domain

public struct SourceHomeView: View {
    let source: Source
    
    @Environment(\.dimensions) private var dimensions
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    
    public init(source: Source) {
        self.source = source
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: dimensions.spacing.large) {
                // header section
                headerSection
                
                Divider()
                
                // info section
                infoSection
                
                // presets section
                if source.presets.count > 0 {
                    presetsSection
                }
                
                Spacer(minLength: dimensions.spacing.large)
            }
            .padding(dimensions.padding.screen)
        }
        .navigationTitle(source.name)
        .navigationBarTitleDisplayMode(.large)
    }
    
    private var headerSection: some View {
        HStack(spacing: dimensions.spacing.large) {
            SourceIcon(url: source.icon.absoluteString, isDisabled: source.disabled)
                .frame(width: 60, height: 60)
            
            VStack(alignment: .leading, spacing: dimensions.spacing.minimal) {
                Text(source.name)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text(source.host)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: dimensions.spacing.regular) {
                    if source.pinned {
                        Label("Pinned", systemImage: "pin.fill")
                            .font(.caption)
                            .foregroundStyle(theme.colors.accent)
                    }
                    
                    if source.disabled {
                        Label("Disabled", systemImage: "nosign")
                            .font(.caption)
                            .foregroundStyle(theme.colors.alert)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, dimensions.padding.regular)
    }
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: dimensions.spacing.large) {
            Text("Source Information")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: dimensions.spacing.regular) {
                infoRow(label: "Host", value: source.host)
                infoRow(label: "Base URL", value: source.host)  // using host as placeholder
                infoRow(label: "^[\(source.presets.count) Preset](inflect: true)", value: nil)
                infoRow(label: "Status", value: source.disabled ? "Disabled" : "Active")
            }
        }
    }
    
    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: dimensions.spacing.large) {
            Text("Available Presets")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(source.presets, id: \.self) { preset in
                HStack {
                    Image(systemName: "tag.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(preset.name)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    SourceHomeRow(source: source, preset: preset)
                }
                .padding(dimensions.padding.regular)
                .background(theme.colors.tint)
                .clipShape(RoundedRectangle(cornerRadius: dimensions.cornerRadius.regular))
            }
        }
    }
    
    private func infoRow(label: String, value: String?) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            if let value = value {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
    }
}
