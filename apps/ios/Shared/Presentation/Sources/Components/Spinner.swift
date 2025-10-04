//
//  Spinner.swift
//  Presentation
//
//  Created by Angelo Carasig on 17/6/2025.
//
import SwiftUI

internal struct Spinner: View {
    enum Size {
        case small
        case regular
        case large
        
        var barWidth: CGFloat {
            switch self {
            case .small: return 2
            case .regular: return 3
            case .large: return 4
            }
        }
        
        var barHeight: CGFloat {
            switch self {
            case .small: return 16
            case .regular: return 28
            case .large: return 40
            }
        }
        
        var spacing: CGFloat {
            switch self {
            case .small: return 3
            case .regular: return 4
            case .large: return 5
            }
        }
        
        var barCount: Int {
            switch self {
            case .small: return 5
            case .regular: return 7
            case .large: return 7
            }
        }
        
        var fontSize: Font {
            switch self {
            case .small: return .caption2
            case .regular: return .caption
            case .large: return .footnote
            }
        }
    }
    
    @State private var isAnimating = false
    
    let prompt: String?
    let size: Size
    
    init(prompt: String? = nil, size: Size = .regular) {
        self.prompt = prompt
        self.size = size
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: size.spacing) {
                ForEach(0..<size.barCount, id: \.self) { index in
                    RoundedRectangle(cornerRadius: size.barWidth / 2)
                        .fill(Color.primary)
                        .frame(width: size.barWidth, height: size.barHeight)
                        .scaleEffect(y: isAnimating ? 0.5 : 1.0)
                        .animation(
                            .easeInOut(duration: 0.4)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.1),
                            value: isAnimating
                        )
                }
            }
            
            if let prompt = prompt {
                Text(prompt)
                    .font(size.fontSize)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .onAppear { isAnimating = true }
    }
}

#Preview("Small") {
    Spinner(size: .small)
}

#Preview("Regular") {
    Spinner(size: .regular)
}

#Preview("Large") {
    Spinner(size: .large)
}

#Preview("Small with Prompt") {
    Spinner(prompt: "Loading...", size: .small)
}

#Preview("Regular with Prompt") {
    Spinner(prompt: "Loading your library...", size: .regular)
}

#Preview("Large with Prompt") {
    Spinner(prompt: "This might take a moment\nwhile we fetch your content", size: .large)
        .padding()
}

#Preview("All Sizes") {
    VStack(spacing: 40) {
        Spinner(prompt: "Small", size: .small)
        Spinner(prompt: "Regular", size: .regular)
        Spinner(prompt: "Large", size: .large)
    }
    .padding()
}
