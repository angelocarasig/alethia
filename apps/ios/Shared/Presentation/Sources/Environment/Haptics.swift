//
//  Haptics.swift
//  Presentation
//
//  Created by Angelo Carasig on 16/6/2025.
//

import SwiftUI

@MainActor
internal final class Haptics: ObservableObject {
    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "hapticFeedbackEnabled")
        }
    }
    
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notification = UINotificationFeedbackGenerator()
    
    init() {
        self.isEnabled = UserDefaults.standard.bool(forKey: "hapticFeedbackEnabled")
        
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        notification.prepare()
    }
    
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        guard isEnabled else { return }
        
        switch style {
        case .light:
            impactLight.impactOccurred()
        case .medium:
            impactMedium.impactOccurred()
        case .heavy:
            impactHeavy.impactOccurred()
        default:
            impactLight.impactOccurred()
        }
    }
    
    func success() {
        guard isEnabled else { return }
        notification.notificationOccurred(.success)
    }
    
    func warning() {
        guard isEnabled else { return }
        notification.notificationOccurred(.warning)
    }
    
    func error() {
        guard isEnabled else { return }
        notification.notificationOccurred(.error)
    }
}

private struct HapticsKey: @preconcurrency EnvironmentKey {
    @MainActor static let defaultValue = Haptics()
}

extension EnvironmentValues {
    internal var haptics: Haptics {
        get { self[HapticsKey.self] }
        set { self[HapticsKey.self] = newValue }
    }
}
