//
//  TestView.swift
//  Presentation
//
//  Created by Angelo Carasig on 4/10/2025.
//

import SwiftUI

public struct TestView: View {
    public init() {}
    
    public var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)
            
            Text("Alethia")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("All layers connected!")
                .font(.title3)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                Label("Core ✓", systemImage: "checkmark")
                Label("Domain ✓", systemImage: "checkmark")
                Label("Data ✓", systemImage: "checkmark")
                Label("Presentation ✓", systemImage: "checkmark")
                Label("Composition ✓", systemImage: "checkmark")
                Label("Database initialized ✓", systemImage: "checkmark")
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
    }
}
