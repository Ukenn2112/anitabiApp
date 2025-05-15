//
//  SafariViewModel.swift
//  anitabi
//
//  Created by 维安雨轩 on 2025/05/11.
//

import Foundation
import SwiftUI
import Combine

class SafariViewModel: ObservableObject {
    @Published var safariURL: URL?
    @Published var isSafariPresented = false
    
    func openInSafari(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        self.safariURL = url
        self.isSafariPresented = true
    }
    
    func closeSafari() {
        self.isSafariPresented = false
    }
} 