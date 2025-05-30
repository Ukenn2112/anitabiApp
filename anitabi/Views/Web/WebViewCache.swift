//
//  WebViewCache.swift
//  anitabi
//
//  Created by 维安雨轩 on 2025/05/11.
//

import Foundation
@preconcurrency import WebKit

// URLキャッシュを管理するクラス
class ResourceCacheManager {
    static let shared = ResourceCacheManager()
    private let cache = NSCache<NSString, NSData>()
    private var expirationTimes = [String: Date]()
    private let cacheValidityPeriod: TimeInterval = 3600 // 1時間（秒単位）
    
    private let cachableResources = [
        "https://anitabi.cn/api/g.svg",
        "https://anitabi.cn/mapbox/aniki/aniki@2x.png"
    ]
    
    func isCachableResource(_ urlString: String) -> Bool {
        return cachableResources.contains(urlString)
    }
    
    func cacheData(_ data: Data, for urlString: String) {
        let key = urlString as NSString
        cache.setObject(data as NSData, forKey: key)
        expirationTimes[urlString] = Date().addingTimeInterval(cacheValidityPeriod)
    }
    
    func getCachedData(for urlString: String) -> Data? {
        let key = urlString as NSString
        
        // キャッシュの有効期限をチェック
        if let expirationTime = expirationTimes[urlString], expirationTime > Date(),
           let cachedData = cache.object(forKey: key) {
            return cachedData as Data
        } else {
            // 期限切れなら削除
            cache.removeObject(forKey: key)
            expirationTimes.removeValue(forKey: urlString)
            return nil
        }
    }
}

// URLをインターセプトするためのURL Scheme Handler
class CacheURLSchemeHandler: NSObject, WKURLSchemeHandler {
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url,
              let urlString = url.absoluteString.replacingOccurrences(of: "cached:", with: "") as String? else {
            urlSchemeTask.didFailWithError(NSError(domain: "Invalid URL", code: 0, userInfo: nil))
            return
        }
        
        // キャッシュからデータを取得
        if let cachedData = ResourceCacheManager.shared.getCachedData(for: urlString) {
            // キャッシュから応答
            let response = URLResponse(url: url, mimeType: getMimeType(for: url), expectedContentLength: cachedData.count, textEncodingName: nil)
            urlSchemeTask.didReceive(response)
            urlSchemeTask.didReceive(cachedData)
            urlSchemeTask.didFinish()
            return
        }
        
        // キャッシュになければ通常のリクエストを行い、キャッシュに保存
        if let originalURL = URL(string: urlString) {
            let task = URLSession.shared.dataTask(with: originalURL) { data, response, error in
                if let error = error {
                    urlSchemeTask.didFailWithError(error)
                    return
                }
                
                guard let data = data, let response = response else {
                    urlSchemeTask.didFailWithError(NSError(domain: "No data", code: 0, userInfo: nil))
                    return
                }
                
                // キャッシュに保存
                ResourceCacheManager.shared.cacheData(data, for: urlString)
                
                // 応答を返す
                urlSchemeTask.didReceive(response)
                urlSchemeTask.didReceive(data)
                urlSchemeTask.didFinish()
            }
            task.resume()
        } else {
            urlSchemeTask.didFailWithError(NSError(domain: "Invalid URL", code: 0, userInfo: nil))
        }
    }
    
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        // キャンセル処理が必要な場合はここに実装
    }
    
    private func getMimeType(for url: URL) -> String {
        let pathExtension = url.pathExtension.lowercased()
        switch pathExtension {
        case "svg":
            return "image/svg+xml"
        case "png":
            return "image/png"
        case "jpg", "jpeg":
            return "image/jpeg"
        default:
            return "application/octet-stream"
        }
    }
}

// URLインターセプトするためのNavigationDelegate
class WebViewNavigationDelegate: NSObject, WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let urlString = navigationAction.request.url?.absoluteString,
           ResourceCacheManager.shared.isCachableResource(urlString) {
            // キャッシュ対象のURLならcached:スキームに変換してリクエスト
            if let cachedURL = URL(string: "cached:" + urlString) {
                webView.load(URLRequest(url: cachedURL))
                decisionHandler(.cancel)
                return
            }
        }
        decisionHandler(.allow)
    }
} 