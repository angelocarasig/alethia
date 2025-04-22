//
//  ScrollView+PullToRefresh.swift
//  Alethia
//
//  Created by Angelo Carasig on 19/2/2025.
//

import Foundation
import SwiftUI

// https://stackoverflow.com/a/79429223

extension View {
    func onPullToRefresh(
        delay nanoseconds: UInt64 = 4_000_000_000,
        action: @escaping () async -> Void
    ) -> some View {
        self.refreshable {
            try? await Task.sleep(nanoseconds: nanoseconds)
            await action()
        }
    }
}

