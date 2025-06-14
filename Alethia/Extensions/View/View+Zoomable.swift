//
//  View+Zoomable.swift
//  Alethia
//
//  Created by Angelo Carasig on 11/5/2025.
//

import SwiftUI

extension View {
    @ViewBuilder
    func zoomable(
        isZoomable: Bool = true,
        minZoomScale: CGFloat = 1,
        doubleTapZoomScale: CGFloat = 2
    ) -> some View {
        modifier(ZoomableModifier(
            isZoomable: isZoomable,
            minZoomScale: minZoomScale,
            doubleTapZoomScale: doubleTapZoomScale
        ))
    }
    
    @ViewBuilder
    func zoomable(
        isZoomable: Bool = true,
        minZoomScale: CGFloat = 1,
        doubleTapZoomScale: CGFloat = 2,
        outOfBoundsColor: Color = .clear
    ) -> some View {
        ZStack {
            outOfBoundsColor
            self.zoomable(
                isZoomable: isZoomable,
                minZoomScale: minZoomScale,
                doubleTapZoomScale: doubleTapZoomScale
            )
        }
    }
}

private struct ZoomableModifier: ViewModifier {
    let isZoomable: Bool
    let minZoomScale: CGFloat
    let doubleTapZoomScale: CGFloat
    
    @State private var lastTransform: CGAffineTransform = .identity
    @State private var transform: CGAffineTransform = .identity
    @State private var contentSize: CGSize = .zero
    
    func body(content: Content) -> some View {
        content
            .background(alignment: .topLeading) {
                GeometryReader { proxy in
                    Color.clear
                        .onAppear {
                            contentSize = proxy.size
                        }
                }
            }
            .animatableTransformEffect(transform)
            .gesture(dragGesture, including: transform == .identity ? .none : .all)
            .simultaneousGesture(magnificationGesture)
            .gesture(doubleTapGesture)
            .onChange(of: isZoomable) {
                withAnimation {
                    lastTransform = .identity
                    transform = .identity
                }
            }
    }
    
    private var magnificationGesture: some Gesture {
        MagnifyGesture(minimumScaleDelta: 0)
            .onChanged { value in
                guard isZoomable else { return }
                
                // Calculate the anchor point in the view's coordinate space
                let anchor = value.startAnchor.scaledBy(contentSize)
                
                // Create a transform that scales around the pinch location
                let scaleTransform = CGAffineTransform(translationX: anchor.x, y: anchor.y)
                    .scaledBy(x: value.magnification, y: value.magnification)
                    .translatedBy(x: -anchor.x, y: -anchor.y)
                
                // Apply the scale transform to the last saved transform
                transform = lastTransform.concatenating(scaleTransform)
            }
            .onEnded { _ in
                onEndGesture()
            }
    }
    
    private var doubleTapGesture: some Gesture {
        SpatialTapGesture(count: 2)
            .onEnded { value in
                guard isZoomable else { return }
                
                let newTransform: CGAffineTransform =
                if transform.isIdentity {
                    .anchoredScale(scale: doubleTapZoomScale, anchor: value.location)
                } else {
                    .identity
                }
                
                withAnimation(.spring) {
                    transform = newTransform
                    lastTransform = newTransform
                }
            }
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard isZoomable else { return }
                
                withAnimation(.interactiveSpring) {
                    transform = lastTransform.translatedBy(
                        x: value.translation.width / transform.scaleX,
                        y: value.translation.height / transform.scaleY
                    )
                }
            }
            .onEnded { _ in
                onEndGesture()
            }
    }
    
    private func onEndGesture() {
        guard isZoomable else { return }
        
        let newTransform = limitTransform(transform)
        
        withAnimation(.snappy(duration: 0.1)) {
            transform = newTransform
            lastTransform = newTransform
        }
    }
    
    private func limitTransform(_ transform: CGAffineTransform) -> CGAffineTransform {
        let scaleX = transform.scaleX
        let scaleY = transform.scaleY
        
        if scaleX < minZoomScale || scaleY < minZoomScale {
            return .identity
        }
        
        let maxX = contentSize.width * (scaleX - 1)
        let maxY = contentSize.height * (scaleY - 1)
        
        if transform.tx > 0 || transform.tx < -maxX || transform.ty > 0 || transform.ty < -maxY {
            let tx = min(max(transform.tx, -maxX), 0)
            let ty = min(max(transform.ty, -maxY), 0)
            var transform = transform
            transform.tx = tx
            transform.ty = ty
            return transform
        }
        
        return transform
    }
}

private extension View {
    @ViewBuilder
    func animatableTransformEffect(_ transform: CGAffineTransform) -> some View {
        scaleEffect(
            x: transform.scaleX,
            y: transform.scaleY,
            anchor: .zero
        )
        .offset(x: transform.tx, y: transform.ty)
    }
}

private extension UnitPoint {
    func scaledBy(_ size: CGSize) -> CGPoint {
        .init(
            x: x * size.width,
            y: y * size.height
        )
    }
}

private extension CGAffineTransform {
    static func anchoredScale(scale: CGFloat, anchor: CGPoint) -> CGAffineTransform {
        CGAffineTransform(translationX: anchor.x, y: anchor.y)
            .scaledBy(x: scale, y: scale)
            .translatedBy(x: -anchor.x, y: -anchor.y)
    }
    
    var scaleX: CGFloat {
        sqrt(a * a + c * c)
    }
    
    var scaleY: CGFloat {
        sqrt(b * b + d * d)
    }
}
