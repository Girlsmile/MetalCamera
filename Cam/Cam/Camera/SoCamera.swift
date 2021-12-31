//
//  SoCamera.swift
//  Cam
//
//  Created by flow on 2021/12/29.
//

import Foundation
import UIKit
import AVFoundation
import MetalKit
import Metal

class SoCamera: NSObject {
    
    var didStartSuccessed = false
    
    /// 是否应用当前扫码
    var enable = true
    
    weak var delegate: SoCameraUserConfigDelegate?
    
    weak var dataCallbackDelegate: SoCameraDataDelegate?
    
    var videoTextureCache: CVMetalTextureCache?
    
    public var orientation:ImageOrientation?
    
    /// 捕捉设备
    private var device: AVCaptureDevice? = {
        let videoDevice = AVCaptureDevice.default(for: .video)
        
        guard let videoDevice = videoDevice else {
            return nil
        }
        
        return videoDevice
    }()
    
    /// 输入sesson
    private var input: AVCaptureDeviceInput?
    
   
    private var output: AVCaptureVideoDataOutput?
    
    /// 输出sesson
    private var session: AVCaptureSession!
        
    private var layer: AVCaptureVideoPreviewLayer?
    
    private var lastResult: String?
    
    private var lastResultTime: TimeInterval = 0
    
    override init() {
        super.init()
        setupDevice()
    }
    

    func setupDevice() {
        
        guard let device = device else { return }
        
        input = try? AVCaptureDeviceInput.init(device: device)
        
        output = AVCaptureVideoDataOutput()
        output?.setSampleBufferDelegate(self, queue: Task.shared.cameraOutputQueue)
        
        session = AVCaptureSession()
        session.canSetSessionPreset(.high)
        if let inp = input, let outp = output {
            session.addInput(inp)
            session.addOutput(outp)
        }
        
        layer = AVCaptureVideoPreviewLayer.init(session: session)
        layer?.videoGravity = .resizeAspectFill
        
    }
    
    func enableCameraConfig() {
        
        guard let videoDevice = device else {
            return
        }
        
        //自动白平衡
        if videoDevice.isWhiteBalanceModeSupported(.autoWhiteBalance) {
            try? videoDevice.lockForConfiguration()
            videoDevice.whiteBalanceMode = .autoWhiteBalance
            videoDevice.unlockForConfiguration()
        }
        
        //自动对焦
        if videoDevice.isFocusModeSupported(.continuousAutoFocus) {
            try? videoDevice.lockForConfiguration()
            videoDevice.focusMode = .continuousAutoFocus
            videoDevice.unlockForConfiguration()
        }
        
        //自动曝光
        if videoDevice.isExposureModeSupported(.autoExpose) {
            try? videoDevice.lockForConfiguration()
            videoDevice.exposureMode = .autoExpose
            videoDevice.unlockForConfiguration()
        }
        
    }
    
}

//

// MARK: - AVCaptureMetadataOutputObjectsDelegate

//
extension SoCamera: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let cameraFrame = CMSampleBufferGetImageBuffer(sampleBuffer)!
        let bufferWidth = CVPixelBufferGetWidth(cameraFrame)
        let bufferHeight = CVPixelBufferGetHeight(cameraFrame)
        let currentTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        CVPixelBufferLockBaseAddress(cameraFrame, CVPixelBufferLockFlags(rawValue:CVOptionFlags(0)))
        
        
        let texture: Texture?
        
        var textureRef:CVMetalTexture? = nil
        let _ = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.videoTextureCache!, cameraFrame, nil, .bgra8Unorm, bufferWidth, bufferHeight, 0, &textureRef)
        if let concreteTexture = textureRef, let cameraTexture = CVMetalTextureGetTexture(concreteTexture) {
            texture = Texture(orientation: self.orientation ?? .portrait, texture: cameraTexture, timingStyle: .videoFrame(timestamp: Timestamp(currentTime)))
        } else {
            texture = nil
        }
        
        
        texture?.texture
        
        
    }
    
    
}


//

// MARK: -  使用方法

//
extension SoCamera {
    
    /// 启动
    func begin() {
        beginToScan()
    }
    
    /// 结束
    func cancel() {
        stopScan()
    }
    
    /// 打开手电筒
    func openTorch() {
        try? device?.lockForConfiguration()
        device?.torchMode = .on
        device?.unlockForConfiguration()
    }
    
    /// 关闭手电筒
    func closeTorch() {
        try? device?.lockForConfiguration()
        device?.torchMode = .off
        device?.unlockForConfiguration()
    }
    
}

//

// MARK: -  其他逻辑

//
private extension SoCamera {
    
    /// 是否支持camera
    var isCameraAvailable: Bool {
        return UIImagePickerController.isSourceTypeAvailable(.camera)
    }
    
    /// 是否有权限
    var isCameraAuthorized: Bool {
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video, completionHandler: {_ in
                self.enableCameraConfig()
            })
            return true
        default:
            return false
        }
        
    }
    
    /// 开始扫描
    func beginToScan() {
        guard isCameraAvailable else {
            /// error 不支持camera
            if let method =  dataCallbackDelegate?.startFailRequireDevice {
                method()
            }
           
            return
        }
        
        
        guard isCameraAuthorized else {
            /// 没有权限
            dataCallbackDelegate?.startFailRequirePermisson()
            return
        }
        
        if let _ = input, let layer = self.layer, !self.session.isRunning {
            self.layer?.frame = delegate?.preview.bounds ?? .zero
       
            self.session.startRunning()
            delegate?.preview.layer.insertSublayer(layer, at: 0)
        }
        
    }
    
    
    /// 结束扫描
    func stopScan() {
        guard isCameraAvailable else {
            /// error 不支持camera
            return
        }
        
        if let _ = self.input, self.session.isRunning {
            self.session.stopRunning()
        }
    }
    
    
    
    
}

