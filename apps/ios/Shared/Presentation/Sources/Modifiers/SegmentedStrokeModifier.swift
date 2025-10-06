//
//  SegmentedStrokeModifier.swift
//  Presentation
//
//  Created by Angelo Carasig on 6/10/2025.
//

import SwiftUI

struct SegmentedStrokeModifier: ViewModifier {
    let segments: Int
    let gapAngle: Double
    let strokeColor: Color
    let lineWidth: CGFloat
    
    init(
        segments: Int = 6,
        gapAngle: Double = 10,
        strokeColor: Color,
        lineWidth: CGFloat = 2
    ) {
        self.segments = segments
        self.gapAngle = gapAngle
        self.strokeColor = strokeColor
        self.lineWidth = lineWidth
    }
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            GeometryReader { geo in
                let radius: CGFloat = min(geo.size.width, geo.size.height) / 2
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                let segmentAngle: Double = 360.0 / Double(segments)
                
                ForEach(0..<segments, id: \.self) { index in
                    Path { path in
                        let startAngle = Double(index) * segmentAngle + (gapAngle / 2)
                        let endAngle = startAngle + segmentAngle - gapAngle
                        
                        path.addArc(
                            center: center,
                            radius: radius - (lineWidth / 2),
                            startAngle: .degrees(startAngle - 90), // -90 to start from top
                            endAngle: .degrees(endAngle - 90),
                            clockwise: false
                        )
                    }
                    .stroke(
                        strokeColor,
                        style: StrokeStyle(
                            lineWidth: lineWidth,
                            lineCap: .round
                        )
                    )
                }
            }
        }
    }
}

// MARK: - View Extension

extension View {
    func segmentedStroke(
        segments: Int = 6,
        gapAngle: Double = 10,
        color: Color = .primary.opacity(0.3),
        lineWidth: CGFloat = 2
    ) -> some View {
        modifier(
            SegmentedStrokeModifier(
                segments: segments,
                gapAngle: gapAngle,
                strokeColor: color,
                lineWidth: lineWidth
            )
        )
    }
}
