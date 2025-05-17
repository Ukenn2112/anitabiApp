//
//  CameraViewModel.swift
//  anitabi
//
//  Created by 维安雨轩 on 2025/05/13.
//

import SwiftUI
import AVFoundation
import Photos

// MARK: - 结构体
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
    private var photoDelegate: PhotoCaptureDelegate?
    
    @Published var isSettingUp: Bool = true
    @Published var cameraPermissionDenied: Bool = false
    @Published var photoLibraryPermissionDenied: Bool = false
    @Published private(set) var isCameraReady: Bool = false
    
    // セッションが実行中かどうかを確認するプロパティ
    var isSessionRunning: Bool {
        return captureSession.isRunning
    }
    
    // カメラが使用可能かどうかを確認
    var isCameraAvailable: Bool {
        return !isSettingUp && !cameraPermissionDenied && AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) != nil
    }
    
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
            
            // セッションの開始はメインスレッドで行わない
            self.captureSession.startRunning()
            
            DispatchQueue.main.async {
                self.isSettingUp = false
                self.isCameraReady = true
            }
        }
    }
    
    private func resetCaptureSession() {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
        
        if !captureSession.inputs.isEmpty {
            captureSession.beginConfiguration()
            captureSession.inputs.forEach { captureSession.removeInput($0) }
            captureSession.outputs.forEach { captureSession.removeOutput($0) }
            captureSession.commitConfiguration()
        }
    }
    
    private func configureCaptureSession() {
        captureSession.beginConfiguration()
        
        // 高品質な写真を撮影するための設定
        if captureSession.canSetSessionPreset(.photo) {
            captureSession.sessionPreset = .photo
        }
        
        // バックカメラの設定
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            handleCameraSetupFailure("Failed to get back camera")
            return
        }
        
        do {
            // 自動フォーカスと露出の設定
            try videoDevice.lockForConfiguration()
            if videoDevice.isFocusModeSupported(.continuousAutoFocus) {
                videoDevice.focusMode = .continuousAutoFocus
            }
            if videoDevice.isExposureModeSupported(.continuousAutoExposure) {
                videoDevice.exposureMode = .continuousAutoExposure
            }
            videoDevice.unlockForConfiguration()
            
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            
            guard captureSession.canAddInput(videoInput) else {
                handleCameraSetupFailure("Failed to add video input")
                return
            }
            captureSession.addInput(videoInput)
            
            guard captureSession.canAddOutput(photoOutput) else {
                handleCameraSetupFailure("Failed to add photo output")
                return
            }
            
            // 高品質な写真出力の設定
            photoOutput.maxPhotoQualityPrioritization = .quality
            
            captureSession.addOutput(photoOutput)
            
            captureSession.commitConfiguration()
        } catch {
            handleCameraSetupFailure("Error setting up camera: \(error.localizedDescription)")
        }
    }
    
    private func handleCameraSetupFailure(_ message: String) {
        print(message)
        captureSession.commitConfiguration()
        DispatchQueue.main.async {
            self.isSettingUp = false
            self.isCameraReady = false
        }
    }
    
    func setupPreviewLayer(for view: UIView) {
        // プレビューレイヤーがまだ設定されていない場合のみ設定する
        if self.previewLayer == nil {
            let layer = AVCaptureVideoPreviewLayer(session: self.captureSession)
            layer.videoGravity = .resizeAspectFill
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                // レイヤーの境界を正確に設定
                layer.frame = view.bounds
                
                // キャプチャセッションの現在の状態を確認
                if !self.captureSession.isRunning {
                    self.sessionQueue.async {
                        if !self.captureSession.isRunning {
                            self.captureSession.startRunning()
                        }
                    }
                }
                
                // プレビューレイヤーをビューに追加
                view.layer.sublayers?.forEach { if $0 is AVCaptureVideoPreviewLayer { $0.removeFromSuperlayer() } }
                view.layer.addSublayer(layer)
                self.previewLayer = layer
            }
        } else {
            // 既存のプレビューレイヤーがある場合は更新
            updatePreviewFrame(for: view)
        }
    }
    
    func updatePreviewFrame(for view: UIView) {
        DispatchQueue.main.async { [weak self] in
            guard let layer = self?.previewLayer else { return }
            layer.frame = view.bounds
            
            // キャプチャセッションが実行されていることを確認
            if let captureSession = self?.captureSession, !captureSession.isRunning {
                self?.sessionQueue.async {
                    if !captureSession.isRunning {
                        captureSession.startRunning()
                    }
                }
            }
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self, self.captureSession.isRunning else { return }
            self.captureSession.stopRunning()
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
            
            // 写真設定の構成
            let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
            
            // 利用可能なフラッシュモードを確認して設定
            if self.photoOutput.supportedFlashModes.contains(.auto) {
                settings.flashMode = .auto
            }
            
            self.photoDelegate = PhotoCaptureDelegate { image in
                DispatchQueue.main.async {
                    completion(image)
                    self.photoDelegate = nil
                }
            }
            
            self.photoOutput.capturePhoto(with: settings, delegate: self.photoDelegate!)
        }
    }
}

// MARK: - 照片捕获代理
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
        
        guard let imageData = photo.fileDataRepresentation(), 
              let image = UIImage(data: imageData) else {
            print("Failed to get photo data")
            completion(nil)
            return
        }
        
        saveCapturedImageToGallery(image)
        
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