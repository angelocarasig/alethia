//
//  NotificationBanner.swift
//  Alethia
//
//  Created by Angelo Carasig on 10/5/2025.
//

import SwiftUI

struct ReaderNotificationBanner: View {
    let message: String?
    
    var body: some View {
        if let message = message {
            Text(message)
                .font(.headline)
                .fontWeight(.bold)
                .frame(width: 200)
                .padding(.horizontal, Constants.Padding.screen * 2)
                .padding(.vertical, Constants.Padding.screen)
                .background(.ultraThinMaterial, in: .capsule)
                .transition(.opacity)
        }
    }
}
