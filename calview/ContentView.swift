import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            CalendarContainerView()
                .tabItem { Label("Calendar", systemImage: "calendar") }
            LegendEditorView()
                .tabItem { Label("Legend", systemImage: "paintpalette") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
    }
}
