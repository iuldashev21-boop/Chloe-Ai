import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable {
    case home = "Home"
    case chat = "Chat"
    case journal = "Journal"
    case visionBoard = "Vision Board"
    case affirmations = "Affirmations"
    case goals = "Goals"
    case settings = "Settings"
    case profile = "Profile"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .home: return "house"
        case .chat: return "bubble.left.and.bubble.right"
        case .journal: return "book"
        case .visionBoard: return "photo.on.rectangle"
        case .affirmations: return "sparkles"
        case .goals: return "target"
        case .settings: return "gearshape"
        case .profile: return "person.circle"
        }
    }
}

struct MainTabView: View {
    @State private var selectedItem: SidebarItem? = .home
    @State private var columnVisibility = NavigationSplitViewVisibility.detailOnly

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List(SidebarItem.allCases, selection: $selectedItem) { item in
                Label(item.rawValue, systemImage: item.icon)
                    .foregroundColor(.chloeTextPrimary)
            }
            .navigationTitle("Chloe")
            .listStyle(.sidebar)
        } detail: {
            detailView(for: selectedItem ?? .home)
        }
        .navigationSplitViewStyle(.balanced)
    }

    @ViewBuilder
    private func detailView(for item: SidebarItem) -> some View {
        switch item {
        case .home: HomeView()
        case .chat: ChatView()
        case .journal: JournalView()
        case .visionBoard: VisionBoardView()
        case .affirmations: AffirmationsView()
        case .goals: GoalsView()
        case .settings: SettingsView()
        case .profile: ProfileView()
        }
    }
}

#Preview {
    MainTabView()
}
