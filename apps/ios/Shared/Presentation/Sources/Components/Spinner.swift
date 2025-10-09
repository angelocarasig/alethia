//
//  Spinner.swift
//  Presentation
//
//  Created by Angelo Carasig on 7/10/2025.
//

import SwiftUI

struct Spinner: View {
    let text: String?
    let size: Size
    
    enum Size {
        case small
        case medium
        case large
        
        var circleSize: CGFloat {
            switch self {
            case .small: return 30
            case .medium: return 50
            case .large: return 70
            }
        }
        
        var lineWidth: CGFloat {
            switch self {
            case .small: return 2
            case .medium: return 3
            case .large: return 4
            }
        }
        
        var font: Font {
            switch self {
            case .small: return .caption
            case .medium: return .subheadline
            case .large: return .body
            }
        }
        
        var spacing: CGFloat {
            switch self {
            case .small: return 8
            case .medium: return 12
            case .large: return 16
            }
        }
    }
    
    init(text: String? = nil, size: Size = .medium) {
        self.text = text
        self.size = size
    }
    
    @State private var scale: CGFloat = 0.8
    
    var body: some View {
        VStack(spacing: size.spacing) {
            Circle()
                .stroke(Color.accentColor, lineWidth: size.lineWidth)
                .frame(width: size.circleSize, height: size.circleSize)
                .scaleEffect(scale)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                        scale = 1.3
                    }
                }
            
            if let text = text {
                Text(text)
                    .font(size.font)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Previews
#Preview("Small") {
    Spinner(text: "Loading...", size: .small)
}

#Preview("Small - No Text") {
    Spinner(size: .small)
}

#Preview("Medium") {
    Spinner(text: "Loading...", size: .medium)
}

#Preview("Medium - No Text") {
    Spinner(size: .medium)
}

#Preview("Large") {
    Spinner(text: "Loading...", size: .large)
}

#Preview("Large - No Text") {
    Spinner(size: .large)
}

#Preview("All Sizes") {
    VStack(spacing: 60) {
        VStack {
            Text("Small")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spinner(text: "Loading...", size: .small)
        }
        
        VStack {
            Text("Medium")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spinner(text: "Loading...", size: .medium)
        }
        
        VStack {
            Text("Large")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spinner(text: "Loading...", size: .large)
        }
    }
    .padding()
}

#Preview("Different Text Lengths") {
    VStack(spacing: 40) {
        Spinner(text: "Loading", size: .medium)
        Spinner(text: "Please wait...", size: .medium)
        Spinner(text: "Fetching your data", size: .medium)
    }
    .padding()
}
