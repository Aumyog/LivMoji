import UIKit
import AVFoundation
import UniformTypeIdentifiers

class AnimationEngine {
    func generateAnimationFrames(for image: UIImage, animation: AnimationType, duration: Double) async throws -> [UIImage] {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let frames = try self.createAnimationFrames(
                        image: image,
                        animation: animation,
                        duration: duration
                    )
                    continuation.resume(returning: frames)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func createAnimationFrames(image: UIImage, animation: AnimationType, duration: Double) throws -> [UIImage] {
        let frameCount = Int(duration * 30) 
        var frames: [UIImage] = []
        let size = CGSize(width: 200, height: 200)

        for frame in 0..<frameCount {
            let progress = Double(frame) / Double(frameCount)
            let animatedImage = createAnimatedFrame(
                image: image,
                animation: animation,
                progress: progress,
                size: size
            )
            frames.append(animatedImage)
        }
        
        return frames
    }
    
    private func createAnimatedFrame(image: UIImage, animation: AnimationType, progress: Double, size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            
            context.cgContext.saveGState()
            
            switch animation {
            case .bounce:
                let bounceOffset = sin(progress * .pi * 4) * 10
                context.cgContext.translateBy(x: 0, y: bounceOffset)
                
            case .wave:
                let waveX = sin(progress * .pi * 6) * 15
                let waveY = cos(progress * .pi * 4) * 8
                context.cgContext.translateBy(x: waveX, y: waveY)
            }
            
            image.draw(in: rect)
            context.cgContext.restoreGState()
        }
    }
    
}

struct AnimationExporter {
    static func createGIF(from frames: [UIImage], duration: Double) async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let url = try self.generateGIF(frames: frames, duration: duration)
                    continuation.resume(returning: url)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    static func createMP4(from frames: [UIImage], duration: Double) async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let url = try self.generateMP4(frames: frames, duration: duration)
                    continuation.resume(returning: url)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    static func savePNG(_ image: UIImage) throws -> URL {
        guard let data = image.pngData() else {
            throw ExportError.imageConversionFailed
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = "livemoji_\(UUID().uuidString).png"
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        try data.write(to: fileURL)
        return fileURL
    }
    
    private static func generateGIF(frames: [UIImage], duration: Double) throws -> URL {
        guard let firstImage = frames.first else {
            throw ExportError.noFrames
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = "livemoji_\(UUID().uuidString).gif"
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        guard let destination = CGImageDestinationCreateWithURL(
            fileURL as CFURL,
            UTType.gif.identifier as CFString,
            frames.count,
            nil
        ) else {
            throw ExportError.destinationCreationFailed
        }
        
        let frameDelay = duration / Double(frames.count)
        let gifProperties = [
            kCGImagePropertyGIFDictionary: [
                kCGImagePropertyGIFLoopCount: 0
            ]
        ]
        
        CGImageDestinationSetProperties(destination, gifProperties as CFDictionary)
        
        for frame in frames {
            guard let cgImage = frame.cgImage else { continue }
            
            let frameProperties = [
                kCGImagePropertyGIFDictionary: [
                    kCGImagePropertyGIFDelayTime: frameDelay
                ]
            ]
            
            CGImageDestinationAddImage(destination, cgImage, frameProperties as CFDictionary)
        }
        
        guard CGImageDestinationFinalize(destination) else {
            throw ExportError.gifCreationFailed
        }
        
        return fileURL
    }
    
    private static func generateMP4(frames: [UIImage], duration: Double) throws -> URL {
        guard let firstImage = frames.first else {
            throw ExportError.noFrames
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = "livemoji_\(UUID().uuidString).mp4"
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        try? FileManager.default.removeItem(at: fileURL)
        
        let size = firstImage.size
        let writer = try AVAssetWriter(outputURL: fileURL, fileType: .mp4)
        
        let outputSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: size.width,
            AVVideoHeightKey: size.height
        ]
        
        let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: outputSettings)
        let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: writerInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
                kCVPixelBufferWidthKey as String: size.width,
                kCVPixelBufferHeightKey as String: size.height
            ]
        )
        
        writer.add(writerInput)
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)
        
        let frameDuration = CMTime(seconds: duration / Double(frames.count), preferredTimescale: 600)
        
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        
        var frameIndex = 0
        let mediaQueue = DispatchQueue(label: "mediaQueue")
        
        writerInput.requestMediaDataWhenReady(on: mediaQueue) {
            while writerInput.isReadyForMoreMediaData && frameIndex < frames.count {
                let presentationTime = CMTimeMultiply(frameDuration, multiplier: Int32(frameIndex))
                
                if let pixelBuffer = self.pixelBuffer(from: frames[frameIndex], size: size) {
                    pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime)
                }
                
                frameIndex += 1
            }
            
            if frameIndex >= frames.count {
                writerInput.markAsFinished()
                writer.finishWriting {
                    dispatchGroup.leave()
                }
            }
        }
        
        dispatchGroup.wait()
        
        if writer.status == .failed {
            throw ExportError.mp4CreationFailed
        }
        
        return fileURL
    }
    
    private static func pixelBuffer(from image: UIImage, size: CGSize) -> CVPixelBuffer? {
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
        ] as CFDictionary
        
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(size.width),
            Int(size.height),
            kCVPixelFormatType_32ARGB,
            attrs,
            &pixelBuffer
        )
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        defer { CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0)) }
        
        let pixelData = CVPixelBufferGetBaseAddress(buffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let context = CGContext(
            data: pixelData,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: rgbColorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else {
            return nil
        }
        
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context)
        image.draw(in: CGRect(origin: .zero, size: size))
        UIGraphicsPopContext()
        
        return buffer
    }
}


enum ExportError: LocalizedError {
    case noFrames
    case imageConversionFailed
    case destinationCreationFailed
    case gifCreationFailed
    case mp4CreationFailed
    
    var errorDescription: String? {
        switch self {
        case .noFrames:
            return "No animation frames available"
        case .imageConversionFailed:
            return "Failed to convert image data"
        case .destinationCreationFailed:
            return "Failed to create export destination"
        case .gifCreationFailed:
            return "Failed to create GIF file"
        case .mp4CreationFailed:
            return "Failed to create MP4 file"
        }
    }
}

