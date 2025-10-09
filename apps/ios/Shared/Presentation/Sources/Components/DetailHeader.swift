//
//  DetailHeader.swift
//  Presentation
//
//  Created by Angelo Carasig on 9/10/2025.
//

import SwiftUI

struct DetailHeader: View {
    
    let title: String
    
    var body: some View {
        Text(title)
            .font(.title2)
            .fontWeight(.bold)
    }
}
