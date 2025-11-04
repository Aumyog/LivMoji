import Foundation
import UIKit
import Vision

// MARK: - Emoji Model
struct LiveMoji: Identifiable, Codable {
    let id = UUID()
    let name: String
    let createdAt: Date
    let imageData: Data
    let animationType: AnimationType
    let duration: Double
    
    var image: UIImage? {
        UIImage(data: imageData)
    }
}

// MARK: - Animation Types
enum AnimationType: String, CaseIterable, Codable {
    case bounce = "bounce"
    case wave = "wave"
    
    var displayName: String {
        switch self {
        case .bounce: return "Bounce"
        case .wave: return "Wave"
        }
    }
    
    var icon: String {
        switch self {
        case .bounce: return "arrow.up.and.down"
        case .wave: return "water.waves"
        }
    }
}

// MARK: - Emoji Style
enum EmojiStyle: String, CaseIterable {
    case anime = "anime"
    
    var displayName: String {
        switch self {
        case .anime: return "Effect"
        }
    }
    
    var emoji: String {
        switch self {
        case .anime: return "✨"
        }
    }
    
    var description: String {
        switch self {
        case .anime: return "Apply visual effect"
        }
    }
}

// MARK: - Face Detection Result
struct FaceDetectionResult {
    let boundingBox: CGRect
    let landmarks: VNFaceLandmarks2D?
    let confidence: Float
}

// MARK: - Export Format
enum ExportFormat: String, CaseIterable {
    case gif = "gif"
    case mp4 = "mp4"
    case png = "png"
    
    var displayName: String {
        switch self {
        case .gif: return "GIF"
        case .mp4: return "MP4"
        case .png: return "PNG"
        }
    }
    
    var fileExtension: String {
        return rawValue
    }
}

