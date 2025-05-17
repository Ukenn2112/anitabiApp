//
//  ContentView.swift
//  anitabi
//
//  Created by 维安雨轩 on 2025/05/11.
//

import SwiftUI
import SafariServices
import UIKit

// MARK: - 设备判断扩展与支持机型集合
extension UIDevice {
    var modelIdentifier: String {
        #if targetEnvironment(simulator)
        return ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "Simulator"
        #else
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafePointer(to: &systemInfo.machine) { ptr in
            ptr.withMemoryRebound(to: CChar.self, capacity: 1) { cptr in
                String(validatingUTF8: cptr) ?? "unknown"
            }
        }
        #endif
    }
}

private let dynamicIslandSupportedModels: Set<String> = [
    "iPhone15,2", // iPhone 14 Pro
    "iPhone15,3", // iPhone 14 Pro Max
    "iPhone15,4", // iPhone 15
    "iPhone15,5", // iPhone 15 Plus
    "iPhone16,1", // iPhone 15 Pro
    "iPhone16,2", // iPhone 15 Pro Max
    "iPhone17,1", // iPhone 16 Pro 
    "iPhone17,2", // iPhone 16 Pro Max
    "iPhone17,3", // iPhone 16
    "iPhone17,4"  // iPhone 16 Plus
]

func isDynamicIslandSupported() -> Bool {
    let modelIdentifier = UIDevice.current.modelIdentifier
    return dynamicIslandSupportedModels.contains(modelIdentifier)
}

// MARK: - 应用标识胶囊视图
struct AppIdentityPillView: View {
    var body: some View {
        HStack(spacing: 10) {
            if let uiImage = UIImage(named: "favicon") {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 16, height: 16)
            }
            Text(Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "Anitabi")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.black)
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 14)
        .background(Color.white)
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
    }
}

struct ContentView: View {
    @StateObject private var imageViewModel = ImageViewModel()
    @StateObject private var safariViewModel = SafariViewModel()
    @StateObject private var sceneComparisonViewModel = SceneComparisonViewModel()
    
    // 用于控制是否显示欢迎界面 
    @State private var showingOnboarding = false
    
    var body: some View {
        ZStack {
            // 主内容
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
                    // ようこそ画面
                    .fullScreenCover(isPresented: $showingOnboarding) {
                        OnboardingView(isPresented: $showingOnboarding)
                            .edgesIgnoringSafeArea(.all)
                    }
                    .onAppear {
                        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
                        if hasCompletedOnboarding {
                            showingOnboarding = true
                        }
                    }
            }
            // 动态岛支持机型时显示应用标识胶囊
            if isDynamicIslandSupported() {
                VStack {
                    AppIdentityPillView()
                        .padding(.top, 15)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .ignoresSafeArea()
            }
        }
    }
}

#Preview {
    ContentView()
}
