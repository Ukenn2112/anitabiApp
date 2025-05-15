//
//  PersistentWebView.swift
//  anitabi
//
//  Created by 维安雨轩 on 2025/05/11.
//

import SwiftUI
import WebKit

// 永続的なWKWebViewを使用するSwiftUIビュー
struct PersistentWebView: UIViewRepresentable {
    @ObservedObject private var webViewStore: WebViewStore
    @ObservedObject var imageViewModel: ImageViewModel
    @ObservedObject var safariViewModel: SafariViewModel
    @ObservedObject var sceneComparisonViewModel: SceneComparisonViewModel
    
    init(imageViewModel: ImageViewModel, safariViewModel: SafariViewModel, sceneComparisonViewModel: SceneComparisonViewModel) {
        self.webViewStore = WebViewStore.shared
        self.imageViewModel = imageViewModel
        self.safariViewModel = safariViewModel
        self.sceneComparisonViewModel = sceneComparisonViewModel
        
        // 画像処理ハンドラーとURLハンドラーを設定（初期化時に一度だけ）
        self.webViewStore.configureHandlers(imageViewModel: imageViewModel, safariViewModel: safariViewModel, sceneComparisonViewModel: sceneComparisonViewModel)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        // ナビゲーションデリゲートを設定
        webViewStore.webView.navigationDelegate = context.coordinator
        return webViewStore.webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // UIViewRepresentableの更新時には特に何もしない
        // WebViewは永続的なインスタンスなので、毎回再ロードする必要はない
    }
    
    func makeCoordinator() -> WebViewNavigationDelegate {
        return WebViewNavigationDelegate()
    }
}

// ステータスバーとセーフエリアを無視するためのモディファイア
extension View {
    func hideStatusBar() -> some View {
        self
            .statusBar(hidden: true)
            .edgesIgnoringSafeArea(.all)
    }
} 
