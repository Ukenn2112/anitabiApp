//
//  ContentView.swift
//  anitabi
//
//  Created by 维安雨轩 on 2025/05/11.
//

import SwiftUI
import SafariServices

struct ContentView: View {
    @StateObject private var imageViewModel = ImageViewModel()
    @StateObject private var safariViewModel = SafariViewModel()
    @StateObject private var sceneComparisonViewModel = SceneComparisonViewModel()
    
    var body: some View {
        NavigationStack {
            PersistentWebView(imageViewModel: imageViewModel, safariViewModel: safariViewModel, sceneComparisonViewModel: sceneComparisonViewModel)
                .edgesIgnoringSafeArea(.all)
                // 画像ビューワー
                .sheet(isPresented: $imageViewModel.isImagePresented) {
                    ImageViewer(isPresented: $imageViewModel.isImagePresented, imageURL: imageViewModel.imageURL)
                }
                // SafariView
                .sheet(isPresented: $safariViewModel.isSafariPresented) {
                    if let url = safariViewModel.safariURL {
                        SafariView(url: url)
                    }
                }
                // シーン比較ビューへのナビゲーション
                .navigationDestination(isPresented: $sceneComparisonViewModel.isSceneComparisonPresented) {
                    if let url = sceneComparisonViewModel.scenePhotoURL,
                       let name = sceneComparisonViewModel.sceneName,
                       let color = sceneComparisonViewModel.sceneColor,
                       let location = sceneComparisonViewModel.sceneLocation {
                        SceneComparisonView(
                            scenePhotoURL: url,
                            sceneName: name,
                            sceneColor: color,
                            sceneLocation: location
                        )
                    }
                }
        }
    }
}

#Preview {
    ContentView()
}
