import UIKit
import CoreImage

class ImageFilterEngine {
    
    private let context = CIContext(options: [.cacheIntermediates: false])
    
    enum FilterStyle: String, CaseIterable {
        case anime = "anime"
        
        var displayName: String {
            switch self {
            case .anime: return "Anime"
            }
        }
        
        var emoji: String {
            switch self {
            case .anime: return "🎌"
            }
        }
    }
      
    func applyFilter(to image: UIImage, style: FilterStyle, intensity: CGFloat = 1.0) -> UIImage {
        guard let ciImage = CIImage(image: image) else { return image }
        
        let processedImage: CIImage
        
        switch style {
        case .anime:
            processedImage = applyAnimeFilter(to: ciImage, intensity: intensity)
        }
        
        let extent = processedImage.extent.isInfinite ? ciImage.extent : processedImage.extent
        
        guard let outputCGImage = context.createCGImage(processedImage, from: extent) else {
            return image
        }
        
        return UIImage(cgImage: outputCGImage, scale: image.scale, orientation: image.imageOrientation)
    }
    
    
    private func applyAnimeFilter(to image: CIImage, intensity: CGFloat) -> CIImage {
        var result = image
        
        if let bilateralFilter = CIFilter(name: "CIBilateralFilter") {
            bilateralFilter.setValue(result, forKey: kCIInputImageKey)
            bilateralFilter.setValue(5.0 * intensity, forKey: "inputSigmaS")
            bilateralFilter.setValue(0.1, forKey: "inputSigmaR")
            result = bilateralFilter.outputImage ?? result
        }
        
        if let vibranceFilter = CIFilter(name: "CIVibrance") {
            vibranceFilter.setValue(result, forKey: kCIInputImageKey)
            vibranceFilter.setValue(intensity * 2.0, forKey: kCIInputAmountKey)
            result = vibranceFilter.outputImage ?? result
        }
        
        if let glowFilter = CIFilter(name: "CIGaussianBlur") {
            glowFilter.setValue(result, forKey: kCIInputImageKey)
            glowFilter.setValue(2.0 * intensity, forKey: kCIInputRadiusKey)
            if let glow = glowFilter.outputImage {
                if let blendFilter = CIFilter(name: "CIScreenBlendMode") {
                    blendFilter.setValue(result, forKey: kCIInputImageKey)
                    blendFilter.setValue(glow, forKey: kCIInputBackgroundImageKey)
                    result = blendFilter.outputImage ?? result
                }
            }
        }
        if let tempFilter = CIFilter(name: "CITemperatureAndTint") {
            tempFilter.setValue(result, forKey: kCIInputImageKey)
            tempFilter.setValue(CIVector(x: 6500 + (500 * intensity), y: 0), forKey: "inputNeutral")
            result = tempFilter.outputImage ?? result
        }
        return result
    }
    
}

