import SwiftUI
import PhotosUI

struct SettingsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @ObservedObject private var syncService = SyncDataService.shared
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled = true
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var profile: Profile?
    @State private var appeared = false
    @State private var showClearDataAlert = false
    @State private var showResetAlert = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var profileImage: UIImage?
    @State private var showImageOptions = false
    @State private var showPhotoPicker = false

    // Privacy & Data Management
    @State private var showDataCollectionInfo = false
    @State private var showDeleteAccountAlert = false
    @State private var showDeleteConfirmation = false
    @State private var deleteConfirmText = ""
    @State private var isDeleting = false
    @State private var showDeleteSuccess = false
    @State private var showExportSheet = false
    @State private var exportFileURL: URL?
    @State private var isExporting = false

    var body: some View {
        ZStack {
            GradientBackground()

            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Account Section
                    settingsSection("ACCOUNT") {
                        HStack(spacing: Spacing.sm) {
                            // Tappable avatar
                            Button { showImageOptions = true } label: {
                                avatarView
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Change profile photo")

                            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                                Text(profile?.displayName ?? "Chloe User")
                                    .font(.chloeBodyDefault)
                                    .foregroundColor(.chloeTextPrimary)

                                Text(profile?.email ?? "")
                                    .font(.chloeCaption)
                                    .foregroundColor(.chloeTextSecondary)
                            }

                            Spacer()

                            // Subscription badge
                            Text(tierLabel)
                                .font(.chloeCaption)
                                .foregroundColor(.white)
                                .padding(.horizontal, Spacing.xxs)
                                .padding(.vertical, Spacing.xxxs)
                                .background(
                                    Capsule()
                                        .fill(V1_PREMIUM_FOR_ALL || profile?.subscriptionTier == .premium
                                              ? Color.chloePrimary
                                              : Color.chloeTextTertiary)
                                )
                        }
                    }

                    // Preferences Section
                    settingsSection("PREFERENCES") {
                        VStack(spacing: 0) {
                            settingsToggleRow(
                                icon: "bell",
                                label: "Notifications",
                                isOn: $notificationsEnabled
                            )

                            Divider()
                                .padding(.leading, 40)

                            settingsToggleRow(
                                icon: "hand.tap",
                                label: "Haptic Feedback",
                                isOn: $hapticFeedbackEnabled
                            )

                            Divider()
                                .padding(.leading, 40)

                            settingsToggleRow(
                                icon: "moon.stars",
                                label: "Dark Mode",
                                isOn: $isDarkMode
                            )
                        }
                    }

                    // Sync Section
                    settingsSection("DATA") {
                        SyncStatusSettingsRow(
                            status: syncService.syncStatus,
                            onRetry: {
                                Task { await syncService.retryPendingSync() }
                            }
                        )
                    }

                    // Support Section
                    settingsSection("SUPPORT") {
                        VStack(spacing: 0) {
                            settingsRow(icon: "info.circle", label: "About Chloe") {
                                Text(appVersion)
                                    .font(.chloeCaption)
                                    .foregroundColor(.chloeTextSecondary)
                            }

                            Divider()
                                .padding(.leading, 40)

                            settingsRow(icon: "envelope", label: "Send Feedback") {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.chloeTextTertiary)
                                    .accessibilityHidden(true)
                            }
                        }
                    }

                    // Privacy & Legal Section
                    settingsSection("PRIVACY & LEGAL") {
                        VStack(spacing: 0) {
                            Link(destination: URL(string: "https://auth-redirect-one.vercel.app/privacy")!) {
                                settingsRow(icon: "hand.raised", label: "Privacy Policy") {
                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(.chloeTextTertiary)
                                        .accessibilityHidden(true)
                                }
                            }
                            .buttonStyle(.plain)

                            Divider()
                                .padding(.leading, 40)

                            Link(destination: URL(string: "https://auth-redirect-one.vercel.app/terms")!) {
                                settingsRow(icon: "doc.text", label: "Terms of Service") {
                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(.chloeTextTertiary)
                                        .accessibilityHidden(true)
                                }
                            }
                            .buttonStyle(.plain)

                            Divider()
                                .padding(.leading, 40)

                            Button {
                                showDataCollectionInfo = true
                            } label: {
                                settingsRow(icon: "eye", label: "What We Collect") {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(.chloeTextTertiary)
                                        .accessibilityHidden(true)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Data Management Section
                    settingsSection("YOUR DATA") {
                        VStack(spacing: 0) {
                            Button {
                                isExporting = true
                                exportUserData()
                            } label: {
                                settingsRow(icon: "square.and.arrow.up", label: "Export My Data") {
                                    if isExporting {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12, weight: .regular))
                                            .foregroundColor(.chloeTextTertiary)
                                            .accessibilityHidden(true)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .disabled(isExporting)

                            Divider()
                                .padding(.leading, 40)

                            Button {
                                showDeleteAccountAlert = true
                            } label: {
                                HStack(spacing: Spacing.xs) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 16, weight: .regular))
                                        .foregroundColor(.red)
                                        .frame(width: 24)
                                        .accessibilityHidden(true)

                                    Text("Delete Account")
                                        .font(.chloeBodyDefault)
                                        .foregroundColor(.red)

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundColor(.chloeTextTertiary)
                                        .accessibilityHidden(true)
                                }
                                .padding(.vertical, Spacing.xs)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Developer Mode Section
                    #if DEBUG
                    devModeSection
                    #endif

                    // Sign Out
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        authVM.signOut()
                    } label: {
                        Text("SIGN OUT")
                            .font(.chloeButton)
                            .tracking(3)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.sm)
                            .background(Color.chloeRosewood)
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.top, Spacing.sm)
                }
                .padding(.top, Spacing.xl)
                .padding(.bottom, Spacing.xxl)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 12)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .alert("Clear All Data?", isPresented: $showClearDataAlert) {
            Button("Clear Everything", role: .destructive) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                notificationsEnabled = true
                hapticFeedbackEnabled = true
                authVM.signOut()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete all local data including your profile, conversations, journal entries, and preferences. You'll need to sign in and complete onboarding again.")
        }
        .alert("Reset to Welcome?", isPresented: $showResetAlert) {
            Button("Reset", role: .destructive) {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                authVM.signOut()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will sign you out and return to the welcome screen. Your data will be cleared.")
        }
        .onAppear {
            profile = SyncDataService.shared.loadProfile()
            if let data = SyncDataService.shared.loadProfileImage() {
                profileImage = UIImage(data: data)
            }
            withAnimation(Spacing.chloeSpring) {
                appeared = true
            }
        }
        .confirmationDialog("Profile Photo", isPresented: $showImageOptions, titleVisibility: .visible) {
            Button("Choose Photo") { showPhotoPicker = true }
            if profileImage != nil {
                Button("Remove Photo", role: .destructive) {
                    try? SyncDataService.shared.deleteProfileImage()
                    profileImage = nil
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotoItem, matching: .images)
        .onChange(of: selectedPhotoItem) {
            guard let item = selectedPhotoItem else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data),
                   let jpegData = uiImage.jpegData(compressionQuality: 0.8) {
                    do {
                        let path = try SyncDataService.shared.saveProfileImage(jpegData)
                        var updated = profile ?? Profile()
                        updated.profileImageUri = path
                        updated.updatedAt = Date()
                        try SyncDataService.shared.saveProfile(updated)
                        profile = updated
                        profileImage = uiImage
                    } catch {}
                }
                selectedPhotoItem = nil
            }
        }
        .sheet(isPresented: $showDataCollectionInfo) {
            DataCollectionInfoView()
        }
        .sheet(isPresented: $showExportSheet) {
            if let url = exportFileURL {
                ShareSheetView(activityItems: [url])
            }
        }
        // Delete Account — Step 1: Initial warning
        .alert("Delete Account?", isPresented: $showDeleteAccountAlert) {
            Button("Continue", role: .destructive) {
                deleteConfirmText = ""
                showDeleteConfirmation = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete ALL your data — profile, conversations, journal entries, goals, vision board, and cloud data. This cannot be undone.")
        }
        // Delete Account — Step 2: Type DELETE to confirm
        .alert("Type DELETE to confirm", isPresented: $showDeleteConfirmation) {
            TextField("Type DELETE", text: $deleteConfirmText)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.characters)
            Button("Delete Everything", role: .destructive) {
                guard deleteConfirmText == "DELETE" else { return }
                performDeleteAccount()
            }
            Button("Cancel", role: .cancel) {
                deleteConfirmText = ""
            }
        } message: {
            Text("This action is irreversible. Type DELETE to confirm permanent account deletion.")
        }
        // Delete Account — Success notification
        .alert("Account Deleted", isPresented: $showDeleteSuccess) {
            Button("OK") {
                authVM.signOut()
            }
        } message: {
            Text("All your data has been deleted. You will now be signed out.")
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private var avatarView: some View {
        let cameraBadge = Image(systemName: "camera.fill")
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 18, height: 18)
            .background(Circle().fill(Color.chloePrimary))
            .accessibilityHidden(true)

        if let profileImage {
            Image(uiImage: profileImage)
                .resizable()
                .scaledToFill()
                .frame(width: 48, height: 48)
                .clipShape(Circle())
                .overlay(alignment: .bottomTrailing) { cameraBadge }
        } else {
            Circle()
                .fill(Color.chloePrimary.opacity(0.15))
                .frame(width: 48, height: 48)
                .overlay(
                    Text(avatarInitial)
                        .font(.chloeHeadline)
                        .foregroundColor(.chloePrimary)
                )
                .overlay(alignment: .bottomTrailing) { cameraBadge }
        }
    }

    private var avatarInitial: String {
        let name = profile?.displayName ?? ""
        return name.isEmpty ? "?" : String(name.prefix(1)).uppercased()
    }

    private var tierLabel: String {
        if V1_PREMIUM_FOR_ALL { return "Premium" }
        return profile?.subscriptionTier == .premium ? "Premium" : "Free"
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(version) (\(build))"
    }

    // MARK: - Developer Mode

    #if DEBUG
    private var devModeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("DEVELOPER")
                .font(.chloeSidebarSectionHeader)
                .tracking(2)
                .foregroundColor(.red.opacity(0.5))
                .padding(.horizontal, Spacing.screenHorizontal)

            VStack(spacing: Spacing.xs) {
                // Skip to Main App toggle
                BentoGridCard {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.orange)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Skip to Main App")
                                .font(.chloeBodyDefault)
                                .foregroundColor(.chloeTextPrimary)
                            Text("Bypass auth & onboarding")
                                .font(.chloeCaption)
                                .foregroundColor(.chloeTextTertiary)
                        }

                        Spacer()

                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            skipToMain()
                        } label: {
                            Text("GO")
                                .font(.chloeCaption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, Spacing.xs)
                                .padding(.vertical, Spacing.xxxs)
                                .background(Capsule().fill(Color.chloeAccent))
                        }
                    }
                }

                // Destructive actions
                BentoGridCard {
                    VStack(spacing: 0) {
                        // Reset to Welcome
                        Button {
                            showResetAlert = true
                        } label: {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(.orange)
                                    .frame(width: 24)

                                Text("Reset to Welcome Screen")
                                    .font(.chloeBodyDefault)
                                    .foregroundColor(.chloeTextPrimary)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.chloeTextTertiary)
                                    .accessibilityHidden(true)
                            }
                            .padding(.vertical, Spacing.xs)
                        }
                        .buttonStyle(.plain)

                        Divider()
                            .padding(.leading, 40)

                        // Clear All Data
                        Button {
                            showClearDataAlert = true
                        } label: {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "trash")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(.red.opacity(0.8))
                                    .frame(width: 24)

                                Text("Clear All Data")
                                    .font(.chloeBodyDefault)
                                    .foregroundColor(.red.opacity(0.8))

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.chloeTextTertiary)
                                    .accessibilityHidden(true)
                            }
                            .padding(.vertical, Spacing.xs)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)
        }
    }
    #endif

    #if DEBUG
    private func skipToMain() {
        Task { await authVM.devSignIn() }
        AppEvents.onboardingDidComplete.send()
    }
    #endif

    // MARK: - Delete Account

    private func performDeleteAccount() {
        isDeleting = true
        Task {
            do {
                try await SyncDataService.shared.deleteAccount()
                await MainActor.run {
                    isDeleting = false
                    showDeleteSuccess = true
                }
            } catch {
                await MainActor.run {
                    isDeleting = false
                    // Fall back to local clear + sign out even if cloud delete fails
                    SyncDataService.shared.clearAll()
                    authVM.signOut()
                }
            }
        }
    }

    // MARK: - Data Export

    private func exportUserData() {
        Task {
            let data = gatherExportData()
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601

            guard let jsonData = try? encoder.encode(data) else {
                await MainActor.run { isExporting = false }
                return
            }

            let tempDir = FileManager.default.temporaryDirectory
            let fileName = "chloe_data_export_\(formattedExportDate).json"
            let fileURL = tempDir.appendingPathComponent(fileName)

            do {
                try jsonData.write(to: fileURL)
                await MainActor.run {
                    exportFileURL = fileURL
                    isExporting = false
                    showExportSheet = true
                }
            } catch {
                await MainActor.run { isExporting = false }
            }
        }
    }

    private func gatherExportData() -> ChloeDataExport {
        let service = SyncDataService.shared
        let profile = service.loadProfile()
        let conversations = service.loadConversations()
        let journalEntries = service.loadJournalEntries()
        let goals = service.loadGoals()
        let affirmations = service.loadAffirmations()
        let visionItems = service.loadVisionItems()
        let userFacts = service.loadUserFacts()

        var conversationExports: [ConversationExport] = []
        for convo in conversations {
            let messages = service.loadMessages(forConversation: convo.id)
            conversationExports.append(ConversationExport(
                conversation: convo,
                messages: messages
            ))
        }

        return ChloeDataExport(
            exportDate: Date(),
            profile: profile,
            conversations: conversationExports,
            journalEntries: journalEntries,
            goals: goals,
            affirmations: affirmations,
            visionItems: visionItems,
            userFacts: userFacts
        )
    }

    private var formattedExportDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    // MARK: - Section Builder

    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(.chloeSidebarSectionHeader)
                .tracking(2)
                .foregroundColor(.chloeTextTertiary)
                .padding(.horizontal, Spacing.screenHorizontal)

            BentoGridCard {
                content()
            }
            .padding(.horizontal, Spacing.screenHorizontal)
        }
    }

    // MARK: - Row Builders

    private func settingsRow<Trailing: View>(icon: String, label: String, @ViewBuilder trailing: () -> Trailing) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.chloePrimary)
                .frame(width: 24)
                .accessibilityHidden(true)

            Text(label)
                .font(.chloeBodyDefault)
                .foregroundColor(.chloeTextPrimary)

            Spacer()

            trailing()
        }
        .padding(.vertical, Spacing.xs)
    }

    private func settingsToggleRow(icon: String, label: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.chloePrimary)
                .frame(width: 24)
                .accessibilityHidden(true)

            Text(label)
                .font(.chloeBodyDefault)
                .foregroundColor(.chloeTextPrimary)

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(.chloePrimary)
                .accessibilityLabel(label)
        }
        .padding(.vertical, Spacing.xs)
    }
}

// MARK: - Data Export Models

struct ChloeDataExport: Encodable {
    let exportDate: Date
    let profile: Profile?
    let conversations: [ConversationExport]
    let journalEntries: [JournalEntry]
    let goals: [Goal]
    let affirmations: [Affirmation]
    let visionItems: [VisionItem]
    let userFacts: [UserFact]
}

struct ConversationExport: Encodable {
    let conversation: Conversation
    let messages: [Message]
}

// MARK: - Share Sheet (UIKit wrapper)

struct ShareSheetView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AuthViewModel())
    }
}
