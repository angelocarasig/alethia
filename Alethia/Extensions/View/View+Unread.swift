//
//  View+Unread.swift
//  Alethia
//
//  Created by Angelo Carasig on 11/5/2025.
//

import SwiftUI

extension View {
    func unread(_ count: Int) -> some View {
        self.modifier(UnreadBadgeModifier(unread: count))
    }
}

private struct UnreadBadgeModifier: ViewModifier {
    let unread: Int
    
    func body(content: Content) -> some View {
        ZStack(alignment: .topTrailing) {
            content
            
            if unread > 0 {
                let unreadAmount = "\(min(unread, 99))\(unread >= 99 ? "+" : "")"
                
                Text(unreadAmount)
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, Constants.Padding.regular)
                    .padding(.vertical, Constants.Padding.minimal)
                    .background(.red.gradient)
                    .clipShape(.capsule)
                    .offset(Constants.Offset.badge)
            }
        }
    }
}

