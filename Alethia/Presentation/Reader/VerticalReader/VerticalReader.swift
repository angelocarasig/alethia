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
        let navController = UINavigationController(
            rootViewController: VerticalReaderController(vm: vm)
        )
        
        navController.setNavigationBarHidden(true, animated: false)
        navController.navigationBar.isHidden = true
        return navController
    }
    
    func updateUIViewController(_: UINavigationController, context _: Context) {}
}
