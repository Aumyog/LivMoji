import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = LiveMojiViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            EmojiCreationView()
                .tabItem {
                    Image(systemName: "face.smiling")
                    Text("Create")
                }
                .tag(0)
            
            EmojiGalleryView()
                .tabItem {
                    Image(systemName: "photo.on.rectangle")
                    Text("Gallery")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("Settings")
                }
                .tag(2)
        }
        .accentColor(.purple)
        .environmentObject(viewModel)
    }
}

#Preview {
    ContentView()
}

