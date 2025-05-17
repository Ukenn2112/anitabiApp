//
//  ComparisonResultView.swift
//  anitabi
//
//  Created by 维安雨轩 on 2025/05/13.
//

import SwiftUI
import Photos

// MARK: - 比较结果视图
struct ComparisonResultView: View {
    // 属性
    let comparisonImage: UIImage
    let sceneName: String
    let dismiss: () -> Void
    
    @State private var isSaving = false
    @State private var showShareSheet = false
    @State private var showSavedAlert = false
    
    // 常量
    private enum Constants {
        static let buttonSize: CGFloat = 60
        static let buttonSpacing: CGFloat = 40  // 调整为与SceneComparisonView一致
        static let iconSize: CGFloat = 24  // 调整为与SceneComparisonView一致
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack {
                    imageSection
                    buttonSection
                }
            }
            .navigationTitle("\(sceneName) 对比")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭", action: dismiss)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: [comparisonImage])
            }
            .alert("已保存到相册", isPresented: $showSavedAlert) {
                Button("确定", role: .cancel) {}
            }
        }
    }
    
    // 图像部分
    private var imageSection: some View {
        Image(uiImage: comparisonImage)
            .resizable()
            .scaledToFit()
            .padding()
    }
    
    // 按钮部分
    private var buttonSection: some View {
        HStack(spacing: Constants.buttonSpacing) {
            saveButton
            shareButton
        }
        .padding(.bottom, 30)
    }
    
    // 保存按钮
    private var saveButton: some View {
        Button(action: saveImageToGallery) {
            VStack(spacing: 6) {  // 添加了spacing参数
                Image(systemName: isSaving ? "hourglass" : "square.and.arrow.down")
                    .font(.system(size: Constants.iconSize))
                    .foregroundColor(.white)
                    .frame(width: Constants.buttonSize, height: Constants.buttonSize)
                    .background(Circle().fill(Color.black.opacity(0.6)))  // 更新背景色和透明度
                
                Text("保存")
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
        .disabled(isSaving)
    }
    
    // 分享按钮
    private var shareButton: some View {
        Button(action: { showShareSheet = true }) {
            VStack(spacing: 6) {  // 添加了spacing参数
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: Constants.iconSize))
                    .foregroundColor(.white)
                    .frame(width: Constants.buttonSize, height: Constants.buttonSize)
                    .background(Circle().fill(Color.black.opacity(0.6)))  // 更新背景色和透明度
                
                Text("分享")
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
    }
    
    // 保存图像功能
    private func saveImageToGallery() {
        isSaving = true
        
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                UIImageWriteToSavedPhotosAlbum(comparisonImage, nil, nil, nil)
                
                // 显示成功保存的提示
                DispatchQueue.main.async {
                    self.showSavedAlert = true
                }
            }
            
            // 模拟保存延迟以获得更好的用户体验
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                isSaving = false
            }
        }
    }
} 