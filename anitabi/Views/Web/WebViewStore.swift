//
//  WebViewStore.swift
//  anitabi
//
//  Created by 维安雨轩 on 2025/05/11.
//

import SwiftUI
import WebKit
import Combine
import UIKit

// WKWebViewのインスタンスを永続化するためのクラス
class WebViewStore: ObservableObject {
    // WKWebViewのシングルトンインスタンス
    @Published var webView: WKWebView
    private var cancellables = Set<AnyCancellable>()
    
    // シングルトンパターンの実装
    static let shared = WebViewStore()
    
    init() {
        // WKWebViewConfigurationを作成
        let configuration = WKWebViewConfiguration()
        
        // カスタムURLスキームハンドラーを登録
        let schemeHandler = CacheURLSchemeHandler()
        configuration.setURLSchemeHandler(schemeHandler, forURLScheme: "cached")
        
        // ウェブコンテンツのスケーリングを制御するスクリプト
        let disableZoomScript = WKUserScript(
            source: "var meta = document.createElement('meta'); meta.name = 'viewport'; meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no'; document.getElementsByTagName('head')[0].appendChild(meta);",
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        
        // スクリプトをコンフィギュレーションに追加
        configuration.userContentController.addUserScript(disableZoomScript)
        
        // WebViewの作成
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.scrollView.pinchGestureRecognizer?.isEnabled = false
        
        // CSS注入
        let excludedModels: Set<String> = ["iPhone12,8", "iPhone14,6"]
        let currentModel = UIDevice.current.modelIdentifier
        let cssString = !excludedModels.contains(currentModel) ?
        """
            @media (max-width: 800px) {
                .side-search-form, .func-change-logs-fixed, .window-bangumis-box {
                    margin-top: 70px !important;
                    background-image: none !important;
                }
                .window-points-box {
                    margin-bottom: 50px !important;
                }
                .func-change-logs-fixed {
                    margin-top: 80px !important;
                }
            }
        """ :
        """
            @media (max-width: 800px) {
                .side-search-form, .func-change-logs-fixed, .window-bangumis-box {
                    margin-top: 20px !important;
                    background-image: none !important;
                }
                .func-change-logs-fixed {
                    margin-top: 30px !important;
                }
            }
        """
        // JavaScriptでCSSを注入するための関数
        let jsString = """
        function injectCSS() {
            const style = document.createElement('style');
            style.textContent = `\(cssString)`;
            document.head.appendChild(style);
        }
        
        // DOMが読み込まれたら実行
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', injectCSS);
        } else {
            injectCSS();
        }
        """
        // ユーザースクリプトを作成
        let userScript = WKUserScript(
            source: jsString,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        // スクリプトをウェブビューに追加
        webView.configuration.userContentController.addUserScript(userScript)
        
        // 初期ロード
        if let url = URL(string: "https://anitabi.cn/map") {
            webView.load(URLRequest(url: url))
        }
    }
    
    // インスタンスに画像ハンドラーとURLハンドラーを設定するメソッド
    func configureHandlers(imageViewModel: ImageViewModel, safariViewModel: SafariViewModel, sceneComparisonViewModel: SceneComparisonViewModel) {
        // 以前のハンドラーを削除（再設定の場合）
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "imageHandler")
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "urlHandler")
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "compareImageHandler")

        // 新しいハンドラーを追加
        let messageHandler = WebViewMessageHandler(imageViewModel: imageViewModel, safariViewModel: safariViewModel, sceneComparisonViewModel: sceneComparisonViewModel)
        webView.configuration.userContentController.add(messageHandler, name: "imageHandler")
        webView.configuration.userContentController.add(messageHandler, name: "urlHandler")
        webView.configuration.userContentController.add(messageHandler, name: "compareImageHandler")

        // 「原图」リンクと「做对比图」リンクをインターセプトするJavaScript
        let imageInterceptionScript = """
        document.addEventListener('click', function(e) {
            // クリックされた要素またはその親要素を探索
            let target = e.target;
            let maxDepth = 5;  // 検索する深さの上限
            let depth = 0;
            
            while (target && depth < maxDepth) {
                // リンクかどうか確認
                if (target.tagName === 'A') {
                    // 「原图」リンクの検出と処理
                    if (target.textContent.trim() === '原图') {
                        e.preventDefault();  // デフォルトのリンク動作を防止
                        const imageUrl = target.getAttribute('href');
                        if (imageUrl) {
                            window.webkit.messageHandlers.imageHandler.postMessage(imageUrl);
                            return;
                        }
                    }
                }
                
                // 親要素へ移動
                target = target.parentElement;
                depth++;
            }
        }, true);  // キャプチャフェーズでイベントをリッスン
        """
        
        // window.openをハイジャックするスクリプト（相対パスを絶対パスに変換）
        let windowOpenInterceptScript = """
        // window.openをハイジャック
        const originalWindowOpen = window.open;
        window.open = function(url, target, features) {
            // URLが指定されている場合
            if (url) {
                try {
                    // 相対パスを絶対パスに変換
                    let fullUrl;
                    
                    // URLが既に完全な形式かチェック
                    if (url.startsWith('http://') || url.startsWith('https://')) {
                        fullUrl = url;
                    } else {
                        // 相対パスの場合は現在のオリジンを先頭に追加
                        fullUrl = new URL(url, window.location.origin).href;
                    }

                    // 「做对比图」リンクの検出
                    if (fullUrl.includes('https://lab.magiconch.com')) {
                        window.webkit.messageHandlers.compareImageHandler.postMessage(fullUrl);
                        return null;
                    }
                    
                    // 完全なURLをハンドラーに送信
                    window.webkit.messageHandlers.urlHandler.postMessage(fullUrl);
                    return null; // window.openの戻り値を期待するコードに対応
                } catch (e) {
                    console.error('URL conversion error:', e);
                    // エラーが発生した場合は元のURLを送信
                    window.webkit.messageHandlers.urlHandler.postMessage(url);
                    return null;
                }
            }
            
            // URLが指定されていない場合は元の関数を呼び出す
            return originalWindowOpen.apply(this, arguments);
        };
        """
        
        // 画像リンクスクリプトの追加と「做对比图」リンクの検出
        let imageInterceptUserScript = WKUserScript(
            source: imageInterceptionScript,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        webView.configuration.userContentController.addUserScript(imageInterceptUserScript)
        
        // ウィンドウオープンスクリプトの追加
        let windowOpenUserScript = WKUserScript(
            source: windowOpenInterceptScript,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        webView.configuration.userContentController.addUserScript(windowOpenUserScript)
        
        // フッター注入スクリプト
        let footerInjectionScript = """
        function injectFooterContent() {
            const funcChangeLogsFixed = document.querySelector('div.func-change-logs-fixed');
            if (funcChangeLogsFixed) {
                const footerDiv = funcChangeLogsFixed.querySelector('div.foot');
                if (footerDiv) {
                    // 既に追加されているか確認
                    const existingNotice = footerDiv.querySelector('div[data-injected-notice]');
                    if (!existingNotice) {
                        const noticeElement = document.createElement('div');
                        noticeElement.setAttribute('data-injected-notice', 'true');
                        noticeElement.innerHTML = '<a><i>下列部分按钮可能需要长按才能被跳转</i></a></br>';
                        footerDiv.insertBefore(noticeElement, footerDiv.firstChild);
                    }
                }
            }
        }
        
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', injectFooterContent);
        } else {
            injectFooterContent();
        }
        
        // 定期的に確認（DOMが動的に変更される場合）
        setInterval(injectFooterContent, 2000);
        """
        
        let footerInjectionUserScript = WKUserScript(
            source: footerInjectionScript,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        webView.configuration.userContentController.addUserScript(footerInjectionUserScript)
    }
} 