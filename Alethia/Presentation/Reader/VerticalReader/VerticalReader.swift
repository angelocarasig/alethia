//
//  +Representable.swift
//  Alethia
//
//  Created by Angelo Carasig on 17/5/2025.
//

import SwiftUI
import UIKit

struct VerticalReader: UIViewControllerRepresentable {
    @EnvironmentObject private var vm: ReaderViewModel
    
    func makeUIViewController(context _: Context) -> UINavigationController {
        UINavigationController(rootViewController: VerticalReaderController(vm: vm))
    }
    
    func updateUIViewController(_: UINavigationController, context _: Context) {}
}
