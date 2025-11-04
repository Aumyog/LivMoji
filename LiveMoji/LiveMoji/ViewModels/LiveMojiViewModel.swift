import SwiftUI
import Vision
import CoreImage

@MainActor
class LiveMojiViewModel: ObservableObject {
    @Published var createdEmojis: [LiveMoji] = []
    @Published var isProcessing = false
    @Published var capturedImage: UIImage?
    @Published var selectedStyle: EmojiStyle = .anime
    @Published var selectedAnimation: AnimationType = .bounce
    @Published var errorMessage: String?
    @Published var showingError = false
    @Published var processingProgress: Double = 0.0
    private let faceDetector = FaceDetectionService()
    private let animationEngine = AnimationEngine()
    private let imageFilterEngine = ImageFilterEngine()
    
    init() {
        loadSavedEmojis()
    }
    
    func processImage(_ image: UIImage) async {
        isProcessing = true
        processingProgress = 0.0
        
        do {
            processingProgress = 0.15
            _ = try? await faceDetector.detectFace(in: image)
            
            processingProgress = 0.6
            let enhancedImage = try await applyImageFilters(to: image)
            
            processingProgress = 0.8
            let emojiImage = try await createEmojiFromImage(enhancedImage)
            
            processingProgress = 1.0
            let liveMoji = createLiveMoji(from: emojiImage)
            createdEmojis.insert(liveMoji, at: 0)
            saveEmojis()
            
            capturedImage = emojiImage
            
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
        } catch {
            print("❌ Processing error: \(error)")
            showError("Failed to process image: \(error.localizedDescription)")
        }
        
        isProcessing = false
        processingProgress = 0.0
    }
    
    func exportEmoji(_ emoji: LiveMoji, format: ExportFormat) async throws -> URL {
        let frames = try await animationEngine.generateAnimationFrames(
            for: emoji.image!,
            animation: emoji.animationType,
            duration: emoji.duration
        )
        
        switch format {
        case .gif:
            return try await AnimationExporter.createGIF(from: frames, duration: emoji.duration)
        case .mp4:
            return try await AnimationExporter.createMP4(from: frames, duration: emoji.duration)
        case .png:
            return try AnimationExporter.savePNG(emoji.image!)
        }
    }
    
    func shareEmoji(_ emoji: LiveMoji, format: ExportFormat) async {
        do {
            let fileURL = try await exportEmoji(emoji, format: format)
            
            DispatchQueue.main.async {
                let activityVC = UIActivityViewController(
                    activityItems: [fileURL],
                    applicationActivities: nil
                )
                
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    window.rootViewController?.present(activityVC, animated: true)
                }
            }
        } catch {
            showError("Failed to export emoji: \(error.localizedDescription)")
        }
    }
    
    func deleteEmoji(_ emoji: LiveMoji) {
        createdEmojis.removeAll { $0.id == emoji.id }
        saveEmojis()
    }
    
    
    private func applyImageFilters(to image: UIImage) async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let filterStyle: ImageFilterEngine.FilterStyle = {
                    switch self.selectedStyle {
                    case .anime: return .anime
                    }
                }()
                
                let processedImage = self.imageFilterEngine.applyFilter(
                    to: image, 
                    style: filterStyle, 
                    intensity: 0.8
                )
                continuation.resume(returning: processedImage)
            }
        }
    }
    
    private func createEmojiFromImage(_ image: UIImage) async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let renderer = UIGraphicsImageRenderer(size: CGSize(width: 200, height: 200))
                let emojiImage = renderer.image { context in
                    let rect = CGRect(origin: .zero, size: CGSize(width: 200, height: 200))
                    context.cgContext.setFillColor(UIColor.systemBackground.cgColor)
                    context.cgContext.fillEllipse(in: rect)
                    image.draw(in: rect.insetBy(dx: 20, dy: 20))
                    context.cgContext.setStrokeColor(UIColor.label.cgColor)
                    context.cgContext.setLineWidth(4)
                    context.cgContext.strokeEllipse(in: rect.insetBy(dx: 2, dy: 2))
                }
                
                continuation.resume(returning: emojiImage)
            }
        }
    }
    
    private func createLiveMoji(from image: UIImage) -> LiveMoji {
        let imageData = image.pngData() ?? Data()
        return LiveMoji(
            name: "Emoji \(Date().formatted(.dateTime.hour().minute()))",
            createdAt: Date(),
            imageData: imageData,
            animationType: selectedAnimation,
            duration: 2.0
        )
    }
    
    private func loadSavedEmojis() {
        if let data = UserDefaults.standard.data(forKey: "SavedEmojis"),
           let emojis = try? JSONDecoder().decode([LiveMoji].self, from: data) {
            createdEmojis = emojis
        }
    }
    
    private func saveEmojis() {
        if let data = try? JSONEncoder().encode(createdEmojis) {
            UserDefaults.standard.set(data, forKey: "SavedEmojis")
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.error)
    }
}

class FaceDetectionService {
    func detectFace(in image: UIImage) async throws -> FaceDetectionResult {
        return try await withCheckedThrowingContinuation { continuation in
            guard let cgImage = image.cgImage else {
                continuation.resume(throwing: NSError(domain: "FaceDetection", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid image"]))
                return
            }
            
            let request = VNDetectFaceRectanglesRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNFaceObservation],
                      let firstFace = observations.first else {
                    continuation.resume(throwing: NSError(domain: "FaceDetection", code: -2, userInfo: [NSLocalizedDescriptionKey: "No face detected"]))
                    return
                }
                
                let result = FaceDetectionResult(
                    boundingBox: firstFace.boundingBox,
                    landmarks: firstFace.landmarks,
                    confidence: firstFace.confidence
                )
                continuation.resume(returning: result)
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }
}

