//
//  ImageViewModel.swift
//  anitabi
//
//  Created by 维安雨轩 on 2025/05/11.
//

import Foundation
import SwiftUI
import Combine

class ImageViewModel: ObservableObject {
    @Published var imageURL: URL?
    @Published var isImagePresented = false
    
    func setImageURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        self.imageURL = url
        self.isImagePresented = true
    }
    
    func closeImage() {
        self.isImagePresented = false
    }
} 