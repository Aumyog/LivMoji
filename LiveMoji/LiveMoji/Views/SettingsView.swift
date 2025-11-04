import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: LiveMojiViewModel
    @State private var showingAbout = false
    @State private var defaultExportFormat: ExportFormat = .gif
    
    var body: some View {
        NavigationView {
            Form {
               
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("LiveMoji")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Anime Photo Filter")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "face.smiling.inverse")
                            .font(.system(size: 40))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .padding(.vertical, 8)
                }
                
                // Export Settings
                Section("Export Settings") {
                    Picker("Default Export Format", selection: $defaultExportFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.displayName).tag(format)
                        }
                    }
                }
                
               
                Section("Preferences") {
                    HStack {
                        Text("Created Emojis")
                        Spacer()
                        Text("\(viewModel.createdEmojis.count)")
                            .foregroundColor(.secondary)
                    }
                }
                
              
                Section("Storage") {
                    Button(action: clearAllEmojis) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            Text("Clear All Emojis")
                                .foregroundColor(.red)
                        }
                    }
                    
                    Button(action: exportAllEmojis) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export All Emojis")
                        }
                    }
                }
                
                
                Section("About") {
                    Button(action: { showingAbout = true }) {
                        HStack {
                            Image(systemName: "info.circle")
                            Text("About LiveMoji")
                        }
                    }
                    
                    Button(action: shareApp) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share App")
                        }
                    }
                    
                    Button(action: rateApp) {
                        HStack {
                            Image(systemName: "star")
                            Text("Rate App")
                        }
                    }
                }
                
                
                Section("Technical") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text("2024.11.1")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Swift Version")
                        Spacer()
                        Text("5.9")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
        }
    }
    
 
    
    private func clearAllEmojis() {
       
        let alert = UIAlertController(
            title: "Clear All Emojis",
            message: "Are you sure you want to delete all your created emojis? This action cannot be undone.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete All", style: .destructive) { _ in
            withAnimation(.spring()) {
                viewModel.createdEmojis.removeAll()
               
                if let data = try? JSONEncoder().encode([LiveMoji]()) {
                    UserDefaults.standard.set(data, forKey: "SavedEmojis")
                }
            }
        })
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true)
        }
    }
    
    private func exportAllEmojis() {
        Task {
       
            var exportURLs: [URL] = []
            
            for emoji in viewModel.createdEmojis {
                do {
                    let url = try await viewModel.exportEmoji(emoji, format: defaultExportFormat)
                    exportURLs.append(url)
                } catch {
                    print("Failed to export \(emoji.name): \(error)")
                }
            }
            
            DispatchQueue.main.async {
                let activityVC = UIActivityViewController(
                    activityItems: exportURLs,
                    applicationActivities: nil
                )
                
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    window.rootViewController?.present(activityVC, animated: true)
                }
            }
        }
    }
    
    private func shareApp() {
        let shareText = "Check out AnimeStyle! Apply anime-style filters to your photos with SwiftUI."
        
        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
    
    private func rateApp() {
        
        print("Opening App Store for rating...")
    }
}


struct AboutView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "face.smiling.inverse")
                            .font(.system(size: 80))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("LiveMoji")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("AI-Powered Animated Emoji Creator")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Features")
                            .font(.headline)
                        
                        FeatureRow(
                            icon: "camera.fill",
                            title: "Smart Camera Capture",
                            description: "Advanced face detection with Vision framework"
                        )
                        
                        FeatureRow(
                            icon: "wand.and.stars",
                            title: "AI Style Transfer",
                            description: "Core ML powered emoji transformation"
                        )
                        
                        FeatureRow(
                            icon: "play.circle",
                            title: "Custom Animations",
                            description: "SwiftUI powered smooth emoji animations"
                        )
                        
                        FeatureRow(
                            icon: "square.and.arrow.up",
                            title: "Multiple Export Formats",
                            description: "Export as GIF, MP4, or PNG"
                        )
                        
                        FeatureRow(
                            icon: "iphone",
                            title: "Modern iOS Design",
                            description: "Built with SwiftUI and iOS best practices"
                        )
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    
            
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Technical Stack")
                            .font(.headline)
                        
                        TechStackRow(framework: "SwiftUI", description: "Modern declarative UI")
                        TechStackRow(framework: "Vision", description: "Face detection")
                        TechStackRow(framework: "Core Image", description: "Image filtering")
                        TechStackRow(framework: "Swift Concurrency", description: "Async/await patterns")
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    
                
                    VStack(spacing: 12) {
                        Text("Built with 💜 using Swift & SwiftUI")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("Designed to impress Apple Engineering Teams")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
                .padding()
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}


struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.purple)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}


struct TechStackRow: View {
    let framework: String
    let description: String
    
    var body: some View {
        HStack {
            Text(framework)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.purple)
            
            Spacer()
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(LiveMojiViewModel())
}

