//
//  CVPixelBuffer+Clamp.swift
//  iCut
//
//  Created by Nail Sharipov on 24.03.2022.
//

import CoreVideo
import UIKit

extension CVPixelBuffer {
    
  func clamp() {
      let width = CVPixelBufferGetWidth(self)
      let height = CVPixelBufferGetHeight(self)
    
      CVPixelBufferLockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
      let floatBuffer = unsafeBitCast(CVPixelBufferGetBaseAddress(self), to: UnsafeMutablePointer<Float>.self)

      let length = height * width
      
      var i = 0
      while i < length {
          let pixel = floatBuffer[i]
          floatBuffer[i] = min(1.0, max(pixel, 0.0))
          i += 1
      }
    
      CVPixelBufferUnlockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
    }
    
    func normolize() {
        let width = CVPixelBufferGetWidth(self)
        let height = CVPixelBufferGetHeight(self)
      
        CVPixelBufferLockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
        let floatBuffer = unsafeBitCast(CVPixelBufferGetBaseAddress(self), to: UnsafeMutablePointer<Float>.self)

        let length = height * width
        
        var i = 0
        var minValue: Float = 10000
        var maxValue: Float = -10000
        
        while i < length {
            let pixel = floatBuffer[i]
            if pixel < minValue {
                minValue = pixel
            }

            if pixel > maxValue {
                maxValue = pixel
            }
            i += 1
        }
        
        let delta = maxValue - minValue
        
        minValue = ceil(minValue)
        maxValue = ceil(maxValue)
        
        i = 0
        
        while i < length {
            let pixel = floatBuffer[i]
            let normal = (pixel - minValue) / delta
            floatBuffer[i] = normal
            i += 1
        }

        CVPixelBufferUnlockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
    }
    
    func image() -> UIImage? {
        let width = CVPixelBufferGetWidth(self)
        let height = CVPixelBufferGetHeight(self)
        let length = height * width
        let rgbaBuffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: 4 * length)
        
        CVPixelBufferLockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
        let floatBuffer = unsafeBitCast(CVPixelBufferGetBaseAddress(self), to: UnsafeMutablePointer<Float>.self)
        
        var i = 0
        var minValue: Float = 10000
        var maxValue: Float = -10000
        
        while i < length {
            let pixel = floatBuffer[i]
            if !pixel.isNaN {
                if pixel < minValue {
                    minValue = pixel
                }

                if pixel > maxValue {
                    maxValue = pixel
                }
            }
            i += 1
        }

        let delta = maxValue - minValue
        
        i = 0
        var j = 0

        while i < length {
            let pixel = floatBuffer[i]
            rgbaBuffer[j] = 255
            rgbaBuffer[j + 1] = 0
            rgbaBuffer[j + 2] = 0
            rgbaBuffer[j + 3] = 0
            if !pixel.isNaN && delta > 0 {
                let normal = (pixel - minValue) / delta
                rgbaBuffer[j + 1] = UInt8(255 * normal)
                rgbaBuffer[j + 3] = UInt8(255 * (1 - normal))
            } else {
                rgbaBuffer[j + 2] = UInt8(255)
            }
            i += 1
            j += 4
        }
        
        CVPixelBufferUnlockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))

        let data = Data(buffer: rgbaBuffer)
        guard let providerRef = CGDataProvider(data: NSData(data: data)) else { return nil }
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
//        let bitmapInfo = CGBitmapInfo.byteOrder32Big
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
        let bitsPerComponent = 8
        let bitsPerPixel = 32
        
        guard let cgim = CGImage(
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bitsPerPixel: bitsPerPixel,
            bytesPerRow: width * 4,
            space: rgbColorSpace,
            bitmapInfo: bitmapInfo,
            provider: providerRef,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
            )
            else { return nil }
        
        
        let image = UIImage(cgImage: cgim)

        rgbaBuffer.deallocate()
        
        return image
    }
    
}
