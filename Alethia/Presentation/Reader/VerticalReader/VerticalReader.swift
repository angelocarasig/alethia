//
//  VerticalReader.swift
//  Alethia
//
//  Created by Angelo Carasig on 18/5/2025.
//

import UIKit
import SwiftUI

struct VerticalReader: UIViewControllerRepresentable {
    @EnvironmentObject private var vm: ReaderViewModel
    
    func makeUIViewController(context: Context) -> UINavigationController {
        UINavigationController(rootViewController: VerticalReaderController(vm: vm))
    }
    
    func updateUIViewController(_: UINavigationController, context _: Context) {}
}

