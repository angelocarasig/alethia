//
//  PlaceholderView.swift
//  Alethia
//
//  Created by Angelo Carasig on 17/4/2025.
//

import Core
import SwiftUI

struct PlaceholderView: View {
    let geometry: GeometryProxy
    
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(maxWidth: .infinity)
                    .shimmer()
                
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(maxWidth: .infinity)
                    .shimmer()
                
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .aspectRatio(1, contentMode: .fit)
                    .shimmer()
            }
            .frame(height: 45)
            .shimmer()
            
            VStack(alignment: .leading) {
                Group {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(maxWidth: .infinity)
                        .frame(height: geometry.size.height / 6)
                        .cornerRadius(4)
                        .shimmer()
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 16)
                        .cornerRadius(4)
                        .opacity(0.6)
                        .shimmer()
                }
                .redacted(reason: .placeholder)
                
                HStack {
                    Spacer()
                    HStack(spacing: 5) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 12, height: 12)
                            .cornerRadius(2)
                            .shimmer()
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 60, height: 12)
                            .cornerRadius(2)
                            .shimmer()
                    }
                }
                .padding(.top, .Padding.regular)
            }
            .cornerRadius(.Corner.regular)
            .frame(maxWidth: .infinity)
            
            Spacer().frame(height: 1000)
        }
    }
}
