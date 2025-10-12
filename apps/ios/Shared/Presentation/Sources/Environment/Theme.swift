//
//  Theme.swift
//  Presentation
//
//  Created by Angelo Carasig on 17/6/2025.
//

import SwiftUI
private struct ThemeKey: EnvironmentKey {
    static let defaultValue = Theme()
}

internal extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

@MainActor
internal struct Theme {
    enum Colors {
        static let foreground = Color("ForegroundColor", bundle: .module)
        static let background = Color("BackgroundColor", bundle: .module)
        static let tint = Color("TintColor", bundle: .module)
        static let accent = Color("AccentColor", bundle: .module)
        
        static let alert = Color("AlertColor", bundle: .module)
        static let appBlue = Color("appBlue", bundle: .module)
        static let appGreen = Color("appGreen", bundle: .module)
        static let appOrange = Color("appOrange", bundle: .module)
        static let appPink = Color("appPink", bundle: .module)
        static let appPurple = Color("appPurple", bundle: .module)
        static let appRed = Color("appRed", bundle: .module)
        static let appYellow = Color("appYellow", bundle: .module)
    }
    
    let colors = (
        foreground: Colors.foreground,
        background: Colors.background,
        tint: Colors.tint,
        accent: Colors.accent,
        
        alert: Colors.alert,
        appBlue: Colors.appBlue,
        appGreen: Colors.appGreen,
        appOrange: Colors.appOrange,
        appPink: Colors.appPink,
        appPurple: Colors.appPurple,
        appRed: Colors.appRed,
        appYellow: Colors.appYellow
    )
    
    enum Transitions {
        static func original() -> AnyTransition { .identity }
        static func pop() -> AnyTransition {
            .scale(scale: 0.8, anchor: .leading).combined(with: .opacity)
        }
        static func slide(edge: Edge) -> AnyTransition {
            .asymmetric(
                insertion: .move(edge: edge).combined(with: .opacity),
                removal: .move(edge: edge).combined(with: .opacity)
            )
        }
    }
    
    var transitions = (
        original: Transitions.original,
        pop: Transitions.pop,
        slide: Transitions.slide
    )
    
    enum Animations {
        static let original: Animation = .default
        static let spring: Animation = .spring(response: 0.5, dampingFraction: 0.8)
        static let expand: Animation = .spring(response: 0.4, dampingFraction: 0.75)
    }
    
    let animations = (
        original: Animations.original,
        spring: Animations.spring,
        expand: Animations.expand
    )
}
