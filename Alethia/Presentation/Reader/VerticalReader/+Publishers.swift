//
//  +Publishers.swift
//  Alethia
//
//  Created by Angelo Carasig on 17/5/2025.
//

import UIKit
import Combine

final class PanelPublisher {
    static let shared = PanelPublisher()
    
    let sliderPct = PassthroughSubject<Double, Never>()
    let didEndScrubbing = PassthroughSubject<Void, Never>()
}


extension VerticalReaderController {
    func subscribeAll() {
        subToSliderPublisher()
        subToScrubEventPublisher()
//        subToAutoScrollPublisher()
//        subToPagePaddingPublisher()
    }
}

// MARK: Slider

extension VerticalReaderController {
    func subToSliderPublisher() {
        PanelPublisher
            .shared
            .sliderPct
            .sink { [weak self] value in
                self?.handleSliderPositionChange(value)
            }
            .store(in: &subscriptions)
    }
    
    func subToScrubEventPublisher() {
        PanelPublisher
            .shared
            .didEndScrubbing
            .sink { [weak self] in
                self?.onScrollStop()
            }
            .store(in: &subscriptions)
    }
}
