//
//  SceneComparisonView.swift
//  anitabi
//
//  Created by 维安雨轩 on 2025/05/13.
//

import UIKit
import SwiftUI
import AVFoundation
import Photos

// MARK: - 主视图
struct SceneComparisonView: View {
    // MARK: - 属性
    
    // 场景信息
    let scenePhotoURL: URL
    let sceneName: String
    let sceneColor: String
    let sceneLocation: String
    
    // 环境
    @Environment(\.dismiss) private var dismiss
    
    // 状态
    @State private var capturedImage: UIImage? = nil
    @State private var isProcessingPhoto: Bool = false
    @State private var isShowingPermissionAlert: Bool = false
    @State private var permissionAlertData = PermissionAlertData()
    @State private var showGeneratedComparison: Bool = false
    @State private var combinedImage: UIImage? = nil
    
    // 视图模型
    @StateObject private var cameraVM = CameraViewModel()
    
    // MARK: - 主体视图
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景
                Color(hex: sceneColor)
                    .edgesIgnoringSafeArea(.all)
                
                // 内容
                VStack(spacing: 0) {
                    // 顶部区域
                    headerArea
                    
                    // 图片比较区域
                    imagesComparisonArea(geometry: geometry)
                    
                    Spacer()
                    
                    // 底部控制区域
                    controlsArea(geometry: geometry)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear(perform: setupOnAppear)
        .onDisappear(perform: cameraVM.stopSession)
        .alert(isPresented: $isShowingPermissionAlert) {
            createPermissionAlert()
        }
        .fullScreenCover(isPresented: $showGeneratedComparison) {
            if let combinedImage = combinedImage {
                ComparisonResultView(
                    comparisonImage: combinedImage,
                    sceneName: sceneName,
                    dismiss: { showGeneratedComparison = false }
                )
            }
        }
    }
    
    // MARK: - 子视图组件
    
    private var headerArea: some View {
        HStack {
            // 返回按钮
            backButton
            
            Spacer()
            
            // 场景名称
            sceneNameLabel
            
            Spacer()
            
            // 信息按钮
            infoButton
        }
        .padding(.top, 8)
    }
    
    private var backButton: some View {
        Button(action: dismiss.callAsFunction) {
            Image(systemName: "chevron.left")
                .font(.title3)
                .foregroundColor(.white)
                .padding(12)
                .background(Circle().fill(Color.black.opacity(0.6)))
        }
        .padding(.leading, 16)
    }
    
    private var sceneNameLabel: some View {
        Text(sceneName)
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(Capsule().fill(Color.black.opacity(0.6)))
            .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 1)
    }
    
    private var infoButton: some View {
        Button(action: {
            if let url = URL(string: "https://www.google.com/maps?q=\(sceneLocation)") {
                UIApplication.shared.open(url)
            }
        }) {
            Image(systemName: "info.circle")
                .font(.title3)
                .foregroundColor(.white)
                .padding(10)
                .background(Circle().fill(Color.black.opacity(0.6)))
        }
        .padding(.trailing, 16)
    }
    
    private func imagesComparisonArea(geometry: GeometryProxy) -> some View {
        VStack(spacing: 4) {
            // 动漫场景图片
            SceneImageView(url: scenePhotoURL)
                .frame(width: max(0, geometry.size.width - 16), height: max(0, geometry.size.height * 0.38))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal, 8)
                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
            
            // 用户照片区域
            userPhotoArea(geometry: geometry)
        }
        .padding(.top, 8)
    }
    
    private func userPhotoArea(geometry: GeometryProxy) -> some View {
        Group {
            if let capturedImage = capturedImage {
                // 显示已拍摄的照片
                Image(uiImage: capturedImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width - 16, height: geometry.size.height * 0.38)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal, 8)
                    .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                    .overlay(
                        capturedImageOverlay,
                        alignment: .topTrailing
                    )
            } else {
                // 相机预览
                CameraView(cameraVM: cameraVM)
                    .frame(width: max(0, geometry.size.width - 16), height: max(0, geometry.size.height * 0.38))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal, 8)
                    .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
                    .overlay(
                        cameraOverlayView,
                        alignment: .center
                    )
            }
        }
    }
    
    private var cameraOverlayView: some View {
        Group {
            if cameraVM.cameraPermissionDenied {
                cameraPermissionDeniedOverlay
            } else if cameraVM.isSettingUp {
                cameraSettingUpOverlay
            }
        }
    }
    
    private var cameraPermissionDeniedOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
            
            VStack(spacing: 12) {
                Image(systemName: "camera.metering.unknown")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                
                Text("无法访问相机")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("请在设备的\"设置\"中允许应用访问相机")
                    .font(.caption)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button("前往设置") {
                    openSettings()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.blue))
                .foregroundColor(.white)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 8)
        .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
    }
    
    private var cameraSettingUpOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
            
            VStack {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                Text("正在准备相机...")
                    .foregroundColor(.white)
                    .padding(.top, 8)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 8)
        .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
    }
    
    private var capturedImageOverlay: some View {
        Button(action: {
            withAnimation {
                capturedImage = nil
                // 重新启动相机
                cameraVM.setupCamera()
            }
        }) {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .padding(8)
                .background(Circle().fill(Color.black.opacity(0.7)))
        }
        .padding(12)
    }
    
    private func controlsArea(geometry: GeometryProxy) -> some View {
        VStack(spacing: 8) {
            // 位置信息
            locationInfoView

            // 相机按钮或比较按钮
            if capturedImage != nil {
                capturedImageControlButtons
            } else if !cameraVM.cameraPermissionDenied {
                shutterButton
            }
        }
        .padding(.bottom, 16)
    }
    
    private var capturedImageControlButtons: some View {
        HStack(spacing: 40) {
            // 重拍按钮
            Button(action: {
                withAnimation {
                    capturedImage = nil
                    // 重新启动相机
                    cameraVM.setupCamera()
                }
            }) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                    .padding()
                    .background(Circle().fill(Color.red.opacity(0.8)))
            }
            
            // 生成比较按钮
            Button(action: generateComparison) {
                Image(systemName: "checkmark")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                    .padding()
                    .background(Circle().fill(Color.green.opacity(0.8)))
            }
            .disabled(isProcessingPhoto)
            .overlay(
                isProcessingPhoto ? 
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding() : nil
            )
        }
    }
    
    private var shutterButton: some View {
        Button(action: takePhoto) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 72, height: 72)
                
                Circle()
                    .stroke(Color.white, lineWidth: 4)
                    .frame(width: 86, height: 86)
            }
        }
        .disabled(cameraVM.isSettingUp)
        .opacity(cameraVM.isSettingUp ? 0.5 : 1.0)
    }
    
    private var locationInfoView: some View {
        Group {
            if !sceneLocation.isEmpty {
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.white)
                    
                    Text(sceneLocation)
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(Capsule().fill(Color.black.opacity(0.6)))
                .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 1)
            }
        }
    }
    
    // MARK: - 功能方法
    
    private func setupOnAppear() {
        cameraVM.checkPermissions { denied, type in
            if denied {
                showPermissionAlert(for: type)
            }
        }
    }
    
    private func takePhoto() {
        isProcessingPhoto = true
        cameraVM.capturePhoto { image in
            DispatchQueue.main.async {
                if let image = image {
                    withAnimation {
                        self.capturedImage = image
                    }
                }
                self.isProcessingPhoto = false
            }
        }
    }
    
    private func generateComparison() {
        guard let userImage = capturedImage else {
            return
        }

        isProcessingPhoto = true
        
        Task {
            do {
                // 异步加载动漫场景图片
                let (data, response) = try await URLSession.shared.data(from: scenePhotoURL)
                
                guard let httpResponse = response as? HTTPURLResponse, 
                      (200...299).contains(httpResponse.statusCode),
                      let animeImage = UIImage(data: data) else {
                    throw URLError(.badServerResponse)
                }
                
                // 生成对比图片
                let comparisonGenerator = ComparisonImageGenerator()
                guard let combined = comparisonGenerator.generateComparisonImage(
                    animeImage: animeImage,
                    userImage: userImage,
                    sceneName: sceneName,
                    sceneColor: UIColor(Color(hex: sceneColor)),
                    sceneLocation: sceneLocation
                ) else {
                    throw NSError(domain: "ComparisonGeneratorError", code: 1, userInfo: nil)
                }
                
                // 更新UI
                await MainActor.run {
                    self.combinedImage = combined
                    self.isProcessingPhoto = false
                    self.showGeneratedComparison = true
                }
            } catch {
                // 处理错误
                await MainActor.run {
                    self.isProcessingPhoto = false
                    // 这里可以添加错误提示
                }
            }
        }
    }
    
    private func showPermissionAlert(for type: String) {
        permissionAlertData.title = "\(type)访问受限"
        permissionAlertData.message = "要使用该功能，请在设备的\"设置\"中允许应用访问\(type)"
        isShowingPermissionAlert = true
    }
    
    private func createPermissionAlert() -> Alert {
        Alert(
            title: Text(permissionAlertData.title),
            message: Text(permissionAlertData.message),
            primaryButton: .default(Text("前往设置"), action: openSettings),
            secondaryButton: .cancel(Text("取消"))
        )
    }
    
    private func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
}

// MARK: - 辅助视图

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

struct CameraView: UIViewRepresentable {
    let cameraVM: CameraViewModel
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        
        cameraVM.setupPreviewLayer(for: view)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        cameraVM.updatePreviewFrame(for: uiView)
    }
}

struct ComparisonResultView: View {
    let comparisonImage: UIImage
    let sceneName: String
    let dismiss: () -> Void
    
    @State private var isSaving = false
    @State private var showShareSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack {
                    Image(uiImage: comparisonImage)
                        .resizable()
                        .scaledToFit()
                        .padding()
                    
                    HStack(spacing: 30) {
                        saveButton
                        shareButton
                    }
                    .padding(.bottom, 30)
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
        }
    }
    
    private var saveButton: some View {
        Button(action: saveImageToGallery) {
            VStack {
                Image(systemName: isSaving ? "hourglass" : "square.and.arrow.down")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                Text("保存")
                    .font(.caption)
                    .foregroundColor(.white)
            }
            .frame(width: 60, height: 60)
            .background(Circle().fill(Color.blue.opacity(0.8)))
        }
        .disabled(isSaving)
    }
    
    private var shareButton: some View {
        Button(action: { showShareSheet = true }) {
            VStack {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                Text("分享")
                    .font(.caption)
                    .foregroundColor(.white)
            }
            .frame(width: 60, height: 60)
            .background(Circle().fill(Color.green.opacity(0.8)))
        }
    }
    
    private func saveImageToGallery() {
        isSaving = true
        
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                UIImageWriteToSavedPhotosAlbum(comparisonImage, nil, nil, nil)
            }
            
            // 模拟保存延迟以获得更好的用户体验
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                isSaving = false
            }
        }
    }
}

// MARK: - 支持结构体

struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct PermissionAlertData {
    var title: String = ""
    var message: String = ""
}

// MARK: - 视图模型

class CameraViewModel: ObservableObject {
    private let captureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let sessionQueue = DispatchQueue(label: "com.meikenn.anitabi.sessionQueue")
    // 添加属性来保持对PhotoCaptureDelegate的引用
    private var photoDelegate: PhotoCaptureDelegate?
    
    @Published var isSettingUp: Bool = true
    @Published var cameraPermissionDenied: Bool = false
    @Published var photoLibraryPermissionDenied: Bool = false
    
    func checkPermissions(completion: @escaping (Bool, String) -> Void) {
        checkCameraAuthorization { [weak self] denied in
            if denied {
                DispatchQueue.main.async {
                    self?.cameraPermissionDenied = true
                    completion(true, "相机")
                }
            } else {
                self?.setupCamera()
                self?.checkPhotoLibraryAuthorization { denied in
                    if denied {
                        DispatchQueue.main.async {
                            self?.photoLibraryPermissionDenied = true
                            completion(true, "相册")
                        }
                    }
                }
            }
        }
    }
    
    private func checkCameraAuthorization(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(false)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                completion(!granted)
            }
        case .denied, .restricted:
            completion(true)
        @unknown default:
            completion(true)
        }
    }
    
    private func checkPhotoLibraryAuthorization(completion: @escaping (Bool) -> Void) {
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized, .limited:
            completion(false)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { status in
                completion(status != .authorized && status != .limited)
            }
        case .denied, .restricted:
            completion(true)
        @unknown default:
            completion(true)
        }
    }
    
    func setupCamera() {
        isSettingUp = true
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.resetCaptureSession()
            self.configureCaptureSession()
        }
    }
    
    private func resetCaptureSession() {
        // 如果会话已配置，则重置
        if !captureSession.inputs.isEmpty {
            captureSession.beginConfiguration()
            captureSession.inputs.forEach { captureSession.removeInput($0) }
            captureSession.outputs.forEach { captureSession.removeOutput($0) }
            captureSession.commitConfiguration()
        }
    }
    
    private func configureCaptureSession() {
        captureSession.beginConfiguration()
        
        // 设置会话质量
        if captureSession.canSetSessionPreset(.photo) {
            captureSession.sessionPreset = .photo
        }
        
        // 获取后置摄像头
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            handleCameraSetupFailure("Failed to get back camera")
            return
        }
        
        do {
            // 创建输入
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            
            // 添加输入
            guard captureSession.canAddInput(videoInput) else {
                handleCameraSetupFailure("Failed to add video input")
                return
            }
            captureSession.addInput(videoInput)
            
            // 添加输出
            guard captureSession.canAddOutput(photoOutput) else {
                handleCameraSetupFailure("Failed to add photo output")
                return
            }
            captureSession.addOutput(photoOutput)
            
            // 提交配置
            captureSession.commitConfiguration()
            
            // 在后台启动会话
            captureSession.startRunning()
            
            DispatchQueue.main.async {
                self.isSettingUp = false
            }
        } catch {
            handleCameraSetupFailure("Error setting up camera: \(error.localizedDescription)")
        }
    }
    
    private func handleCameraSetupFailure(_ message: String) {
        print(message)
        captureSession.commitConfiguration()
        DispatchQueue.main.async {
            self.isSettingUp = false
        }
    }
    
    func setupPreviewLayer(for view: UIView) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            if self.previewLayer == nil {
                let layer = AVCaptureVideoPreviewLayer(session: self.captureSession)
                layer.videoGravity = .resizeAspectFill
                
                DispatchQueue.main.async {
                    layer.frame = view.bounds
                    view.layer.addSublayer(layer)
                    self.previewLayer = layer
                }
            }
        }
    }
    
    func updatePreviewFrame(for view: UIView) {
        DispatchQueue.main.async { [weak self] in
            guard let layer = self?.previewLayer else { return }
            layer.frame = view.bounds
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self, self.captureSession.isRunning else { return }
            self.captureSession.stopRunning()
            // 清理代理引用
            self.photoDelegate = nil
        }
    }
    
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        sessionQueue.async { [weak self] in
            guard let self = self, self.captureSession.isRunning else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
            
            // 使用属性保持对代理的引用
            self.photoDelegate = PhotoCaptureDelegate { image in
                DispatchQueue.main.async {
                    completion(image)
                    // 任务完成后清理引用，避免内存泄漏
                    self.photoDelegate = nil
                }
            }
            
            self.photoOutput.capturePhoto(with: settings, delegate: self.photoDelegate!)
        }
    }
}

// MARK: - 辅助类

class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (UIImage?) -> Void
    
    init(completion: @escaping (UIImage?) -> Void) {
        self.completion = completion
        super.init()
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error.localizedDescription)")
            completion(nil)
            return
        }
        
        // 获取图像数据
        guard let imageData = photo.fileDataRepresentation(), 
              let image = UIImage(data: imageData) else {
            print("Failed to get photo data")
            completion(nil)
            return
        }
        
        // 保存到相册
        saveCapturedImageToGallery(image)
        
        // 返回图像
        completion(image)
    }
    
    private func saveCapturedImageToGallery(_ image: UIImage) {
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        } completionHandler: { success, error in
            if let error = error {
                print("Error saving photo to gallery: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - 对比图生成器

class ComparisonImageGenerator {
    func generateComparisonImage(
        animeImage: UIImage,
        userImage: UIImage?,
        sceneName: String,
        sceneColor: UIColor,
        sceneLocation: String
    ) -> UIImage? {
        // 常量定义
        let cornerRadius: CGFloat = 12
        let horizontalPadding: CGFloat = 20
        let topPadding: CGFloat = 24
        let bottomPadding: CGFloat = 24
        let imageSpacing: CGFloat = 12
        let iconSize: CGFloat = 28
        let iconTextSpacing: CGFloat = 10
        let titleFontSize: CGFloat = 20
        let locationFontSize: CGFloat = 16
        
        // 固定animeImage的显示尺寸
        let fixedAnimeWidth: CGFloat = 640
        let fixedAnimeHeight: CGFloat = 360
        
        // 计算画布尺寸
        let contentWidth = fixedAnimeWidth
        let canvasWidth = contentWidth + (horizontalPadding * 2)
        
        // 顶部和底部元素的高度
        let topElementHeight = max(iconSize, titleFontSize + 6) + 6
        let bottomElementHeight = max(iconSize, locationFontSize + 6) + 10
        
        // 画布总高度
        let totalHeight = topPadding + topElementHeight + fixedAnimeHeight + 
                        imageSpacing + fixedAnimeHeight + bottomElementHeight + bottomPadding
        
        let canvasSize = CGSize(width: canvasWidth, height: totalHeight)
        
        // 创建图像渲染器
        let renderer = UIGraphicsImageRenderer(size: canvasSize)
        
        return renderer.image { context in
            let ctx = context.cgContext
            
            // 绘制背景和圆角
            let backgroundRect = CGRect(origin: .zero, size: canvasSize)
            let backgroundPath = UIBezierPath(roundedRect: backgroundRect, cornerRadius: cornerRadius)
            sceneColor.setFill()
            backgroundPath.fill()
            
            // 绘制favicon和场景名称
            if let favicon = UIImage(named: "favicon") {
                let faviconRect = CGRect(
                    x: horizontalPadding, 
                    y: topPadding, 
                    width: iconSize, 
                    height: iconSize
                )
                favicon.draw(in: faviconRect)
                
                // 绘制场景名称文本
                let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: titleFontSize, weight: .medium),
                    .foregroundColor: UIColor.white,
                    .shadow: {
                        let shadow = NSShadow()
                        shadow.shadowColor = UIColor.black.withAlphaComponent(0.5)
                        shadow.shadowOffset = CGSize(width: 1, height: 1)
                        shadow.shadowBlurRadius = 3
                        return shadow
                    }()
                ]
                
                let titleRect = CGRect(
                    x: horizontalPadding + iconSize + iconTextSpacing,
                    y: topPadding + (iconSize - titleFontSize) / 2 - 2,
                    width: contentWidth - iconSize - iconTextSpacing,
                    height: titleFontSize + 4
                )
                
                sceneName.draw(in: titleRect, withAttributes: titleAttributes)
            }
            
            // 绘制固定尺寸的anime图像区域
            let animeImageRect = CGRect(
                x: horizontalPadding,
                y: topPadding + topElementHeight + 8,
                width: fixedAnimeWidth,
                height: fixedAnimeHeight
            )
            
            // 创建用于裁剪的圆角路径
            let animeImagePath = UIBezierPath(roundedRect: animeImageRect, cornerRadius: cornerRadius)
            ctx.saveGState()
            animeImagePath.addClip()
            
            // 计算animeImage的缩放比例，优先填满宽度，其次是高度
            let animeImageAspect = animeImage.size.width / animeImage.size.height
            let targetAspect = fixedAnimeWidth / fixedAnimeHeight
            
            var drawRectAnime = animeImageRect
            
            if animeImageAspect > targetAspect {
                // 原图比例更宽，以高度为基准缩放
                let scaledWidth = fixedAnimeHeight * animeImageAspect
                drawRectAnime.origin.x = animeImageRect.minX + (fixedAnimeWidth - scaledWidth) / 2
                drawRectAnime.size.width = scaledWidth
            } else {
                // 原图比例更窄，以宽度为基准缩放
                let scaledHeight = fixedAnimeWidth / animeImageAspect
                drawRectAnime.origin.y = animeImageRect.minY + (fixedAnimeHeight - scaledHeight) / 2
                drawRectAnime.size.height = scaledHeight
            }
            
            animeImage.draw(in: drawRectAnime)
            ctx.restoreGState()
            
            // 绘制用户图像（如果可用）
            if let userImage = userImage {
                let userImageRect = CGRect(
                    x: horizontalPadding,
                    y: animeImageRect.maxY + imageSpacing,
                    width: fixedAnimeWidth,
                    height: fixedAnimeHeight
                )
                
                let userImagePath = UIBezierPath(roundedRect: userImageRect, cornerRadius: cornerRadius)
                ctx.saveGState()
                userImagePath.addClip()
                
                // 计算userImage的缩放比例，同样优先填满宽度，其次是高度
                let userImageAspect = userImage.size.width / userImage.size.height
                
                var drawRectUser = userImageRect
                
                if userImageAspect > targetAspect {
                    // 原图比例更宽，以高度为基准缩放
                    let scaledWidth = fixedAnimeHeight * userImageAspect
                    drawRectUser.origin.x = userImageRect.minX + (fixedAnimeWidth - scaledWidth) / 2
                    drawRectUser.size.width = scaledWidth
                } else {
                    // 原图比例更窄，以宽度为基准缩放
                    let scaledHeight = fixedAnimeWidth / userImageAspect
                    drawRectUser.origin.y = userImageRect.minY + (fixedAnimeHeight - scaledHeight) / 2
                    drawRectUser.size.height = scaledHeight
                }
                
                userImage.draw(in: drawRectUser)
                ctx.restoreGState()
                
                // 绘制位置坐标
                let locationAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.monospacedSystemFont(ofSize: locationFontSize, weight: .regular),
                    .foregroundColor: UIColor.white
                ]
                
                // 计算位置文本大小
                let locationTextSize = sceneLocation.size(withAttributes: locationAttributes)
                
                // 放置位置图标，基于文本宽度确保完全可见
                if let locationIcon = UIImage(systemName: "mappin.and.ellipse") {
                    let iconTint = locationIcon.withTintColor(.white, renderingMode: .alwaysOriginal)
                    
                    // 位置从右侧开始，为文本留出空间
                    let locationIconRect = CGRect(
                        x: canvasWidth - horizontalPadding - locationTextSize.width - iconTextSpacing - iconSize,
                        y: userImageRect.maxY + bottomElementHeight - iconSize,
                        width: iconSize,
                        height: iconSize
                    )
                    iconTint.draw(in: locationIconRect)
                    
                    // 在图标旁边绘制位置文本
                    let locationRect = CGRect(
                        x: locationIconRect.maxX + iconTextSpacing,
                        y: locationIconRect.minY + (iconSize - locationFontSize) / 2 - 2,
                        width: locationTextSize.width,
                        height: locationTextSize.height
                    )
                    
                    sceneLocation.draw(in: locationRect, withAttributes: locationAttributes)
                }
            }
        }
    }
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

// MARK: - Preview
struct SceneComparisonView_Previews: PreviewProvider {
    static var previews: some View {
        SceneComparisonView(
            scenePhotoURL: URL(string: "https://image.anitabi.cn/points/272510/39zlm4tj.jpg")!,
            sceneName: "东京塔夜景",
            sceneColor: "FF5733",
            sceneLocation: "东京都港区芝公园4丁目"
        )
    }
}
