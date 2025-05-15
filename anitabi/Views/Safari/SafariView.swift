//
//  SafariView.swift
//  anitabi
//
//  Created by 维安雨轩 on 2025/05/11.
//

import SwiftUI
import SafariServices

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let configuration = SFSafariViewController.Configuration()
        configuration.entersReaderIfAvailable = false
        configuration.barCollapsingEnabled = true
        
        let safariViewController = SFSafariViewController(url: url, configuration: configuration)
        safariViewController.preferredBarTintColor = UIColor.systemBackground
        safariViewController.preferredControlTintColor = UIColor.systemBlue
        safariViewController.dismissButtonStyle = .close
        
        return safariViewController
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // 更新は不要
    }
} 