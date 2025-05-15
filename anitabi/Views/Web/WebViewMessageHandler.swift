//
//  WebViewMessageHandler.swift
//  anitabi
//
//  Created by 维安雨轩 on 2025/05/13.
//

import Foundation
import WebKit
import SwiftUI
import UIKit

// スクリプトメッセージハンドラー：URLリンクと画像リンクの両方を処理
class WebViewMessageHandler: NSObject, WKScriptMessageHandler {
    var imageViewModel: ImageViewModel
    var safariViewModel: SafariViewModel
    var sceneComparisonViewModel: SceneComparisonViewModel
    
    init(imageViewModel: ImageViewModel, safariViewModel: SafariViewModel, sceneComparisonViewModel: SceneComparisonViewModel) {
        self.imageViewModel = imageViewModel
        self.safariViewModel = safariViewModel
        self.sceneComparisonViewModel = sceneComparisonViewModel
        super.init()
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        // 画像URLのメッセージ処理
        if message.name == "imageHandler" {
            if let urlString = message.body as? String {
                DispatchQueue.main.async {
                    self.imageViewModel.setImageURL(urlString)
                }
            }
        }
        // ウェブリンクメッセージ処理
        else if message.name == "urlHandler" {
            if let urlString = message.body as? String {
                DispatchQueue.main.async {
                    self.safariViewModel.openInSafari(urlString)
                }
            } else if let messageDict = message.body as? [String: Any], 
                      let urlString = messageDict["url"] as? String {
                DispatchQueue.main.async {
                    self.safariViewModel.openInSafari(urlString)
                }
            }
        }
        // 「做对比图」ボタンのメッセージ処理
        else if message.name == "compareImageHandler" {
            if let urlString = message.body as? String {
                DispatchQueue.main.async {
                    // URLパラメータの解析
                    if let url = URL(string: urlString),
                       let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
                       let queryItems = components.queryItems {
                        
                        // パラメータの抽出
                        let imageUrlItem = queryItems.first(where: { $0.name == "url" })
                        let nameItem = queryItems.first(where: { $0.name == "name" })
                        let colorItem = queryItems.first(where: { $0.name == "color" })
                        let locationItem = queryItems.first(where: { $0.name == "g" })
                        
                        // 处理URL参数
                        if let imageUrlString = imageUrlItem?.value,
                           let decodedImageUrl = imageUrlString.removingPercentEncoding,
                           let scenePhotoURL = URL(string: decodedImageUrl) {
                            
                            // 场景名
                            let sceneName = nameItem?.value?.removingPercentEncoding ?? ""
                            // 场景主题颜色
                            let sceneColor = colorItem?.value?.removingPercentEncoding ?? "#000000"
                            // 场景经纬度
                            let sceneLocation = locationItem?.value?.removingPercentEncoding ?? ""
                            
                            // 对比图界面を表示
                            self.sceneComparisonViewModel.openSceneComparison(scenePhotoURL, sceneName, sceneColor, sceneLocation)
                        }
                    }
                }
            }
        }
    }
} 