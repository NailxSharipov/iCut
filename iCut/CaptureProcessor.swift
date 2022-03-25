//
//  CaptureProcessor.swift
//  iCut
//
//  Created by Nail Sharipov on 24.03.2022.
//

import AVFoundation
import UIKit
import Foundation

final class CaptureProcessor {

    let session: AVCaptureSession
    private let device: AVCaptureDevice
    private let output: AVCapturePhotoOutput
    private let depthOutput: AVCaptureDepthDataOutput
    private let photoSolver = CaptureProcessorPhotoSolver()
    private let depthSolver = CaptureProcessorDepthSolver()
    private let dataOutputQueue = DispatchQueue(label: "CaptureProcessorWorkQueue")
    
    
    var onDidCapturePhoto: ((UIImage?) -> ())? {
        get {
            photoSolver.onDidCapturePhoto
        }
        
        set {
            photoSolver.onDidCapturePhoto = newValue
        }
    }
    
    var onDidUpdateDepthePhoto: ((UIImage?) -> ())? {
        get {
            depthSolver.onDidUpdateDepthePhoto
        }
        
        set {
            depthSolver.onDidUpdateDepthePhoto = newValue
        }
    }
    
    init?() {
        guard let aDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) else { return nil }
        
        device = aDevice
        session = AVCaptureSession()

        output = AVCapturePhotoOutput()
        depthOutput = AVCaptureDepthDataOutput()
        depthOutput.setDelegate(depthSolver, callbackQueue: dataOutputQueue)
        depthOutput.isFilteringEnabled = true
        
        guard
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input),
            session.canAddOutput(output)
        else { return nil }

        session.beginConfiguration()
        
        session.sessionPreset = .photo
        session.addInput(input)
        session.addOutput(output)

        session.addOutput(depthOutput)
        
        if let connection = depthOutput.connection(with: .depthData) {
            connection.isEnabled = true
            connection.videoOrientation = .portrait
        } else {
            print("No AVCaptureConnection")
        }
        
        depthOutput.isFilteringEnabled = false

        session.commitConfiguration()
        
        output.isDepthDataDeliveryEnabled = true
        
    }
    
    deinit {
        self.stop()
    }
    
    func start() {
        guard !session.isRunning else { return }
        session.startRunning()
    }
    
    func stop() {
        guard session.isRunning else { return }
        session.stopRunning()
    }
    
    func takeShot() {
        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
        let isDepthData = output.isDepthDataDeliverySupported
        settings.isDepthDataDeliveryEnabled = isDepthData

        output.capturePhoto(with: settings, delegate: photoSolver)
    }

}

final class CaptureProcessorPhotoSolver: NSObject, AVCapturePhotoCaptureDelegate {
    
    fileprivate var onDidCapturePhoto: ((UIImage?) -> ())?
    
    
    func photoOutput(_ output: AVCapturePhotoOutput, willBeginCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        print("willBeginCaptureFor")
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        print("willCapturePhotoFor")
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        print("didCapturePhotoFor")
        
    }
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        print("didFinishProcessingPhoto")
        if let err = error {
            print(err.localizedDescription)
            return
        }
        
        let convertedDepth: AVDepthData
        let depthDataType = kCVPixelFormatType_DisparityFloat32
        guard let depthData = photo.depthData else { return }
        
        if depthData.depthDataType != depthDataType {
            convertedDepth = depthData.converting(toDepthDataType: depthDataType)
        } else {
            convertedDepth = depthData
        }

        let pixelBuffer = convertedDepth.depthDataMap
        let image = pixelBuffer.image()
//        pixelBuffer.normolize()
//        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
//        let image = UIImage(ciImage: ciImage)
        
        DispatchQueue.main.async { [weak self] in
            self?.onDidCapturePhoto?(image)
        }
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        print("didFinishCaptureFor")
        if let err = error {
            print(err.localizedDescription)
            return
        }
    }
    
}

final class CaptureProcessorDepthSolver: NSObject, AVCaptureDepthDataOutputDelegate {
    
    fileprivate var onDidUpdateDepthePhoto: ((UIImage?) -> ())?
    
    func depthDataOutput(_ output: AVCaptureDepthDataOutput, didOutput depthData: AVDepthData, timestamp: CMTime, connection: AVCaptureConnection) {
        let convertedDepth: AVDepthData
        let depthDataType = kCVPixelFormatType_DisparityFloat32
        if depthData.depthDataType != depthDataType {
            convertedDepth = depthData.converting(toDepthDataType: depthDataType)
        } else {
            convertedDepth = depthData
        }

        let pixelBuffer = convertedDepth.depthDataMap
        let image = pixelBuffer.image()
//        pixelBuffer.normolize()
//        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
//        let image = UIImage(ciImage: ciImage)
        
        DispatchQueue.main.async { [weak self] in
            self?.onDidUpdateDepthePhoto?(image)
        }
    }
    
}
