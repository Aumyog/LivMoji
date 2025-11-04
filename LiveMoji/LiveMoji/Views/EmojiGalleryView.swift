import SwiftUI

struct EmojiGalleryView: View {
    @EnvironmentObject var viewModel: LiveMojiViewModel
    @State private var selectedEmoji: LiveMoji?
    @State private var showingExportOptions = false
    @State private var showingDeleteAlert = false
    @State private var emojiToDelete: LiveMoji?
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [.purple.opacity(0.1), .blue.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if viewModel.createdEmojis.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(viewModel.createdEmojis) { emoji in
                                EmojiCard(emoji: emoji) {
                                    selectedEmoji = emoji
                                    showingExportOptions = true
                                }
                                .contextMenu {
                                    contextMenuItems(for: emoji)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("My LiveMojis")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedEmoji) { emoji in
                EmojiDetailView(emoji: emoji)
                    .environmentObject(viewModel)
            }
            .confirmationDialog("Export Options", isPresented: $showingExportOptions, presenting: selectedEmoji) { emoji in
                Button("Export as GIF") {
                    Task {
                        await viewModel.shareEmoji(emoji, format: .gif)
                    }
                }
                Button("Export as MP4") {
                    Task {
                        await viewModel.shareEmoji(emoji, format: .mp4)
                    }
                }
                Button("Export as PNG") {
                    Task {
                        await viewModel.shareEmoji(emoji, format: .png)
                    }
                }
                Button("Cancel", role: .cancel) { }
            }
            .alert("Delete Emoji", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    if let emoji = emojiToDelete {
                        withAnimation(.spring()) {
                            viewModel.deleteEmoji(emoji)
                        }
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete this emoji? This action cannot be undone.")
            }
        }
    }
    

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "face.dashed")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple.opacity(0.6), .blue.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 12) {
                Text("No LiveMojis Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Create your first animated emoji to see it here")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
            
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let tabBarController = windowScene.windows.first?.rootViewController as? UITabBarController {
                    tabBarController.selectedIndex = 0
                }
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create LiveMoji")
                        .fontWeight(.semibold)
                }
                .padding()
                .background(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
    }
    
    private func contextMenuItems(for emoji: LiveMoji) -> some View {
        Group {
            Button(action: {
                selectedEmoji = emoji
                showingExportOptions = true
            }) {
                Label("Export", systemImage: "square.and.arrow.up")
            }
            
            Button(action: {
    
                Task {
                    await viewModel.shareEmoji(emoji, format: .gif)
                }
            }) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            
            Divider()
            
            Button(role: .destructive, action: {
                emojiToDelete = emoji
                showingDeleteAlert = true
            }) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}


struct EmojiCard: View {
    let emoji: LiveMoji
    let onTap: () -> Void
    @State private var isAnimating = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
            
                if let image = emoji.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.purple.opacity(0.3), lineWidth: 2)
                        )
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .animation(
                            .easeInOut(duration: emoji.duration)
                            .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                        .onAppear {
                            isAnimating = true
                        }
                }
                
            
                VStack(spacing: 4) {
                    Text(emoji.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        Image(systemName: emoji.animationType.icon)
                            .font(.caption)
                        Text(emoji.animationType.displayName)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    
                    Text(emoji.createdAt.formatted(.dateTime.month().day().hour().minute()))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.purple.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}


struct EmojiDetailView: View {
    let emoji: LiveMoji
    @EnvironmentObject var viewModel: LiveMojiViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var isAnimating = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    if let image = emoji.image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 250, height: 250)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(.purple, lineWidth: 3)
                            )
                            .shadow(color: .purple.opacity(0.3), radius: 15, x: 0, y: 8)
                            .scaleEffect(isAnimating ? 1.1 : 1.0)
                            .animation(
                                .easeInOut(duration: emoji.duration)
                                .repeatForever(autoreverses: true),
                                value: isAnimating
                            )
                            .onAppear {
                                isAnimating = true
                            }
                    }
                    
                
                    VStack(spacing: 16) {
                        Text(emoji.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        HStack(spacing: 20) {
                            DetailItem(
                                icon: emoji.animationType.icon,
                                title: "Animation",
                                value: emoji.animationType.displayName
                            )
                            
                            DetailItem(
                                icon: "clock",
                                title: "Duration",
                                value: String(format: "%.1f", emoji.duration) + "s"
                            )
                        }
                        
                        DetailItem(
                            icon: "calendar",
                            title: "Created",
                            value: emoji.createdAt.formatted(.dateTime.weekday().month().day().hour().minute())
                        )
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                    
             
                    VStack(spacing: 12) {
                        Text("Export Options")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(spacing: 12) {
                            ExportButton(format: .gif, emoji: emoji, viewModel: viewModel)
                            ExportButton(format: .mp4, emoji: emoji, viewModel: viewModel)
                            ExportButton(format: .png, emoji: emoji, viewModel: viewModel)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                }
                .padding()
            }
            .navigationTitle("LiveMoji Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}


struct DetailItem: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.purple)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
    }
}


struct ExportButton: View {
    let format: ExportFormat
    let emoji: LiveMoji
    let viewModel: LiveMojiViewModel
    
    var body: some View {
        Button(action: {
            Task {
                await viewModel.shareEmoji(emoji, format: format)
            }
        }) {
            VStack(spacing: 8) {
                Image(systemName: formatIcon)
                    .font(.title2)
                
                Text(format.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.purple.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.purple.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var formatIcon: String {
        switch format {
        case .gif: return "gif"
        case .mp4: return "video"
        case .png: return "photo"
        }
    }
}

#Preview {
    EmojiGalleryView()
        .environmentObject(LiveMojiViewModel())
}

