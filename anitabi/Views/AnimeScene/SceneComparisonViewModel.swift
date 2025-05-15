//
//  SceneComparisonViewModel.swift
//  anitabi
//
//  Created by 维安雨轩 on 2025/05/13.
//

import Foundation
import SwiftUI
import Combine

class SceneComparisonViewModel: ObservableObject {
    @Published var scenePhotoURL: URL?
    @Published var sceneName: String?
    @Published var sceneColor: String?
    @Published var sceneLocation: String?
    @Published var isSceneComparisonPresented = false
    
    func openSceneComparison(_ scenePhotoURL: URL, _ sceneName: String, _ sceneColor: String, _ sceneLocation: String) {
        self.scenePhotoURL = scenePhotoURL
        self.sceneName = sceneName
        self.sceneColor = sceneColor
        self.sceneLocation = sceneLocation
        self.isSceneComparisonPresented = true
    }
    
    func closeSceneComparison() {
        self.isSceneComparisonPresented = false
    }
} 