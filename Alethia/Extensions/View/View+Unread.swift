//
//  View+Unread.swift
//  Alethia
//
//  Created by Angelo Carasig on 11/5/2025.
//

import Core
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
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, .Padding.regular)
                    .padding(.vertical, .Padding.minimal)
                    .background(Color.red)
                    .clipShape(.capsule)
                    .offset(.Offset.badge)
            }
        }
    }
}

