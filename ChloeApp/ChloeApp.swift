import SwiftUI

@main
struct ChloeApp: App {
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(isDarkMode ? .dark : .light)
                .task {
                    applyInterfaceStyle(isDarkMode)
                }
                .onChange(of: isDarkMode) { _, newValue in
                    applyInterfaceStyle(newValue)
                }
        }
    }

    private func applyInterfaceStyle(_ dark: Bool) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else { return }
        window.overrideUserInterfaceStyle = dark ? .dark : .light
    }
}
