import SwiftUI
import AVFoundation

struct EmojiCreationView: View {
    @EnvironmentObject var viewModel: LiveMojiViewModel
    @State private var showingImagePicker = false
    @State private var showingStyleSelector = false
    @State private var imagePickerSourceType: UIImagePickerController.SourceType = .camera
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [.purple.opacity(0.3), .blue.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {

                        headerView
                        captureSection
                        
                        styleSelectionSection
                        
                       
                        animationSelectionSection
                    
                        if viewModel.isProcessing {
                            processingView
                        }
                        
                        
                        if let image = viewModel.capturedImage {
                            previewSection(image: image)
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle("LivMoji")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(
                    sourceType: imagePickerSourceType,
                    onImageSelected: { image in
                        viewModel.capturedImage = image
                    }
                )
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
            }
        }
    }
   
    private var headerView: some View {
        VStack(spacing: 12) {
            ZStack {
            
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.purple.opacity(0.3), .blue.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 80 + CGFloat(index) * 20, height: 80 + CGFloat(index) * 20)
                        .scaleEffect(1.0 + sin(Date().timeIntervalSinceReferenceDate + Double(index)) * 0.1)
                        .animation(
                            .easeInOut(duration: 2.0 + Double(index) * 0.5)
                            .repeatForever(autoreverses: true),
                            value: Date().timeIntervalSinceReferenceDate
                        )
                }
                
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .pink, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .purple.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            
            VStack(spacing: 8) {
                Text("LivMoji")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Apply visual effects to photos")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
   
    private var captureSection: some View {
        VStack(spacing: 16) {
            Text("Step 1: Capture Your Face")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 16) {
               
                Button(action: {
                    imagePickerSourceType = .camera
                    showingImagePicker = true
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 30))
                        Text("Camera")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.purple.opacity(0.5), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                
                
                Button(action: {
                    imagePickerSourceType = .photoLibrary
                    showingImagePicker = true
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.fill")
                            .font(.system(size: 30))
                        Text("Photos")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.blue.opacity(0.5), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
    
    private var styleSelectionSection: some View {
        VStack(spacing: 16) {
            Text("Step 2: Choose Style")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(EmojiStyle.allCases, id: \.self) { style in
                        StyleCard(
                            style: style,
                            isSelected: viewModel.selectedStyle == style
                        ) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                viewModel.selectedStyle = style
                            }
                            
                        
                            let selectionFeedback = UISelectionFeedbackGenerator()
                            selectionFeedback.selectionChanged()
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
    
    private var animationSelectionSection: some View {
        VStack(spacing: 16) {
            Text("Step 3: Pick Animation")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(AnimationType.allCases, id: \.self) { animation in
                        AnimationCard(
                            animation: animation,
                            isSelected: viewModel.selectedAnimation == animation
                        ) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                viewModel.selectedAnimation = animation
                            }
                            
                        
                            let selectionFeedback = UISelectionFeedbackGenerator()
                            selectionFeedback.selectionChanged()
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
    
    
    private var processingView: some View {
        VStack(spacing: 16) {
    
            ZStack {
                Circle()
                    .stroke(.purple.opacity(0.3), lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: viewModel.processingProgress)
                    .stroke(
                        LinearGradient(
                            colors: [.purple, .pink, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: viewModel.processingProgress)
                
                Image(systemName: "wand.and.stars")
                    .font(.title2)
                    .foregroundColor(.purple)
                    .scaleEffect(1.0 + sin(Date().timeIntervalSinceReferenceDate * 3) * 0.2)
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: Date().timeIntervalSinceReferenceDate)
            }
            
            VStack(spacing: 8) {
                Text("Processing...")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(processingStatusText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Text("\(Int(viewModel.processingProgress * 100))% Complete")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.purple)
            }
        }
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(
                        colors: [.purple.opacity(0.3), .blue.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
    
    private var processingStatusText: String {
        let progress = viewModel.processingProgress
        switch progress {
        case 0.0..<0.2:
            return "Detecting face..."
        case 0.2..<0.4:
            return "Applying filters..."
        case 0.4..<0.7:
            return "Processing image..."
        case 0.7..<0.9:
            return "Finishing up..."
        default:
            return "Complete!"
        }
    }

    private func previewSection(image: UIImage) -> some View {
        VStack(spacing: 16) {
            Text("Preview")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 200, height: 200)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(.purple, lineWidth: 4)
                )
                .shadow(color: .purple.opacity(0.3), radius: 10, x: 0, y: 5)
            
            Button(action: {
                Task {
                    await viewModel.processImage(image)
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "wand.and.stars")
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                    Text("Apply Filter")
                        .fontWeight(.bold)
                        Text("Apply \(viewModel.selectedStyle.displayName) style")
                            .font(.caption)
                            .opacity(0.9)
                    }
                    Spacer()
                    Text(viewModel.selectedStyle.emoji)
                        .font(.title2)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
                .background(
                    LinearGradient(
                        colors: [.purple, .pink, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .disabled(viewModel.isProcessing)
            .opacity(viewModel.isProcessing ? 0.6 : 1.0)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}


struct StyleCard: View {
    let style: EmojiStyle
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                
                ZStack {
                    Circle()
                        .frame(width: 60, height: 60)
                        .foregroundStyle(styleGradient)
                        .shadow(color: isSelected ? .purple : .clear, radius: 8, x: 0, y: 4)
                    
                    Text(style.emoji)
                        .font(.system(size: 28))
                        .scaleEffect(isSelected ? 1.2 : 1.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isSelected)
                }
                
                VStack(spacing: 4) {
                    Text(style.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .purple : .primary)
                    
                    Text(style.description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .frame(width: 100)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? .ultraThinMaterial : .thickMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? 
                                LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                LinearGradient(colors: [.gray.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
    }
    
    private var styleGradient: LinearGradient {
        switch style {
        case .anime:
            return LinearGradient(colors: [.pink, .purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

struct AnimationCard: View {
    let animation: AnimationType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: animation.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(isSelected ? .purple : .primary)
                
                Text(animation.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(width: 80)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? .purple.opacity(0.2) : .clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? .purple : .gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
    }
}

#Preview {
    EmojiCreationView()
        .environmentObject(LiveMojiViewModel())
}

