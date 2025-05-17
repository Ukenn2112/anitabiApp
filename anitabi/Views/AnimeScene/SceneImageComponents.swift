//
//  SceneImageComponents.swift
//  anitabi
//
//  Created by 维安雨轩 on 2025/05/13.
//

import SwiftUI
import UIKit
import AVFoundation

// MARK: - 场景图像视图
struct SceneImageView: View {
    let url: URL
    
    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                loadingView
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .clipped()
            case .failure:
                errorView
            @unknown default:
                EmptyView()
            }
        }
    }
    
    private var loadingView: some View {
        ZStack {
            Color.black.opacity(0.8)
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
        }
    }
    
    private var errorView: some View {
        ZStack {
            Color.black.opacity(0.8)
            VStack(spacing: 12) {
                Image(systemName: "photo.fill")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                Text("无法加载图片")
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - 相机视图
struct CameraView: UIViewRepresentable {
    let cameraVM: CameraViewModel
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        
        // 初期化後に少し遅延して設定することで、ViewのレイアウトがProperlyされてから処理されるようにする
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            cameraVM.setupPreviewLayer(for: view)
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // フレーム更新時にプレビューレイヤーも更新
        cameraVM.updatePreviewFrame(for: uiView)
        
        // セッションが実行中でなければ再開
        if !cameraVM.isCameraReady {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                cameraVM.setupCamera()
            }
        }
    }
    
    // クリーンアップ用に破棄メソッドを追加
    static func dismantleUIView(_ uiView: UIView, coordinator: ()) {
        // すべてのレイヤーをクリーンアップ
        uiView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
    }
}

// MARK: - 分享表单
struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Helper Extensions
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 