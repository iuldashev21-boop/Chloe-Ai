import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

// MARK: - Navigation Destination Enum

enum SanctuaryDestination: Hashable, Identifiable {
    case journal
    case history
    case visionBoard
    case goals
    case affirmations
    case settings

    var id: Self { self }
}

struct SanctuaryView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel = SanctuaryViewModel()
    @StateObject private var chatVM = ChatViewModel()
    @State private var chatActive = false
    @State private var appeared = false

    // Sidebar
    @State private var sidebarOpen = false

    // Recents sheet
    @State private var showRecentsSheet = false

    // Navigation destination (replaces 6 individual boolean flags)
    @State private var activeDestination: SanctuaryDestination? = nil
    @State private var navigatedFromSidebar = false

    // Camera & Photo picker
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var showFileImporter = false
    @State private var showOfflineAlert = false

    // Feedback reporting sheet
    @State private var reportingMessage: Message?
    @State private var reportingPreviousUserMessage: String = ""

    private var screenWidth: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.screen.bounds.width ?? 390
    }

    var body: some View {
        ZStack(alignment: .leading) {
            // Layer 0: Background
            LinearGradient(
                colors: [.chloeGradientStart, .chloeGradientEnd],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            EtherealDustParticles(isPaused: chatActive)
                .ignoresSafeArea()
                .accessibilityHidden(true)

            // Layer 1: Sidebar
            SidebarView(
                isOpen: $sidebarOpen,
                conversations: viewModel.conversations,
                latestVibe: viewModel.latestVibe,
                streak: viewModel.streak,
                currentConversationId: chatVM.conversationId,
                displayName: viewModel.displayName,
                profileImage: viewModel.profileImage,
                onNewChat: {
                    chatVM.startNewChat()
                    viewModel.ghostMessages = []
                    withAnimation(.chloeSpring) {
                        chatActive = false
                        sidebarOpen = false
                    }
                },
                onSelectConversation: { convo in
                    chatVM.conversationId = convo.id
                    chatVM.messages = SyncDataService.shared.loadMessages(forConversation: convo.id)
                    withAnimation(.chloeSpring) {
                        chatActive = true
                        sidebarOpen = false
                    }
                },
                onNavigate: { destination in
                    navigatedFromSidebar = true
                    var tx = Transaction()
                    tx.disablesAnimations = true
                    withTransaction(tx) {
                        sidebarOpen = false
                    }
                    switch destination {
                    case .journal: activeDestination = .journal
                    case .history: activeDestination = .history
                    case .visionBoard: activeDestination = .visionBoard
                    case .goals: activeDestination = .goals
                    case .affirmations: activeDestination = .affirmations
                    case .settings: activeDestination = .settings
                    }
                },
                onRenameConversation: { id, newTitle in
                    viewModel.renameConversation(id: id, newTitle: newTitle, chatVM: chatVM)
                },
                onDeleteConversation: { id in
                    guard viewModel.deleteConversation(id: id, chatVM: chatVM) else {
                        showOfflineAlert = true
                        return
                    }
                    if chatVM.conversationId == id {
                        chatVM.startNewChat()
                        viewModel.ghostMessages = []
                        withAnimation(.chloeSpring) {
                            chatActive = false
                        }
                    }
                },
                onToggleStarConversation: { id in
                    viewModel.toggleStarConversation(id: id)
                }
            )
            .frame(width: screenWidth * 0.8)
            .offset(x: sidebarOpen ? 0 : -screenWidth * 0.8)

            // Layer 2: Main content
            mainContentWrapper
                .scaleEffect(sidebarOpen ? 0.9 : 1.0)
                .offset(x: sidebarOpen ? screenWidth * 0.8 : 0)
                .cornerRadius(sidebarOpen ? 32 : 0)
                .shadow(color: .black.opacity(sidebarOpen ? 0.1 : 0), radius: 20)
                .disabled(sidebarOpen)
                .onTapGesture {
                    if sidebarOpen {
                        closeSidebar()
                    }
                }
        }
        .gesture(edgeSwipeDragGesture)
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: sidebarOpen)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $activeDestination) { destination in
            switch destination {
            case .journal:
                JournalView()
            case .history:
                HistoryView { convo in
                    chatVM.conversationId = convo.id
                    chatVM.messages = SyncDataService.shared.loadMessages(forConversation: convo.id)
                    chatActive = true
                }
            case .visionBoard:
                VisionBoardView()
            case .goals:
                GoalsView()
            case .affirmations:
                AffirmationsView()
            case .settings:
                SettingsView()
            }
        }
        .alert("You're Offline", isPresented: $showOfflineAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You need an internet connection to delete conversations.")
        }
        .sheet(isPresented: $showRecentsSheet) {
            recentsSheet
        }
        .sheet(item: $reportingMessage) { message in
            ReportSheet(
                messageId: message.id,
                conversationId: chatVM.conversationId ?? "",
                userMessage: reportingPreviousUserMessage,
                aiResponse: message.text,
                onDismiss: { reportingMessage = nil },
                onReported: {
                    viewModel.feedbackStates[message.id] = .reported
                    reportingMessage = nil
                }
            )
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPickerView { image in
                chatVM.pendingImage = image
                if !chatActive { activateChat() }
                if chatVM.inputText.isEmpty {
                    chatVM.inputText = "What do you think of this?"
                }
            }
            .ignoresSafeArea()
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotoItem, matching: .images)
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.image]) { result in
            switch result {
            case .success(let url):
                guard url.startAccessingSecurityScopedResource() else { return }
                defer { url.stopAccessingSecurityScopedResource() }
                if let data = try? Data(contentsOf: url),
                   let image = UIImage(data: data) {
                    chatVM.pendingImage = image
                    if !chatActive { activateChat() }
                    if chatVM.inputText.isEmpty {
                        chatVM.inputText = "What do you think of this?"
                    }
                }
            case .failure:
                break
            }
        }
        .onChange(of: selectedPhotoItem) {
            guard let item = selectedPhotoItem else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    chatVM.pendingImage = image
                    if !chatActive { activateChat() }
                    if chatVM.inputText.isEmpty {
                        chatVM.inputText = "What do you think of this?"
                    }
                }
                selectedPhotoItem = nil
            }
        }
        .onChange(of: activeDestination) { oldValue, newValue in
            if newValue == nil {
                if oldValue == .settings {
                    viewModel.reloadProfileImage()
                }
                reopenSidebarIfNeeded()
            }
        }
        .onChange(of: chatActive) {
            if !chatActive && !chatVM.messages.isEmpty {
                viewModel.loadConversations()
                viewModel.loadGhostMessages(conversationId: chatVM.conversationId)
            }
        }
        .onAppear {
            viewModel.loadData()
            viewModel.loadGhostMessages(conversationId: chatVM.conversationId)
            if !appeared {
                chatVM.startNewChat()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                appeared = true
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                Task { await chatVM.triggerAnalysisIfPending() }
            }
        }
    }

    // MARK: - Main Content Wrapper

    private var mainContentWrapper: some View {
        ZStack {
            LinearGradient(
                colors: [.chloeGradientStart, .chloeGradientEnd],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            if chatActive {
                chatLayout
                    .transition(.opacity)
            } else {
                idleLayout
                    .transition(.opacity)
            }
        }
        .animation(.chloeSpring, value: chatActive)
        .overlay(alignment: .top) {
            if !sidebarOpen {
                HStack {
                    Button { openSidebar() } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.chloePrimary)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .stroke(Color.chloePrimary.opacity(0.35), lineWidth: 1.5)
                            )
                    }
                    .accessibilityLabel("Open sidebar")
                    .accessibilityIdentifier("sidebar-button")

                    SyncStatusBadgeWrapper()

                    Spacer()

                    if chatActive {
                        Button {
                            chatVM.startNewChat()
                            viewModel.ghostMessages = []
                            withAnimation(.chloeSpring) {
                                chatActive = false
                            }
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.chloePrimary)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .stroke(Color.chloePrimary.opacity(0.35), lineWidth: 1.5)
                                )
                        }
                        .accessibilityLabel("New chat")
                    }
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .opacity(appeared ? 1 : 0)
                .animation(.easeIn(duration: 0.4).delay(0.5), value: appeared)
                .transition(.opacity)
            }
        }
    }

    // MARK: - Idle Layout

    private var idleLayout: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: geo.size.height * Spacing.sanctuaryOrbY - Spacing.orbSizeSanctuary * 0.7)

                ChloeAvatar(size: Spacing.orbSizeSanctuary, isThinking: chatVM.isTyping)
                    .scaleEffect(appeared ? 1.0 : 0.3)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: appeared)

                Spacer().frame(height: Spacing.lg)

                Text("Hey, \(viewModel.displayName)")
                    .font(.chloeGreeting)
                    .tracking(36 * 0.03)
                    .foregroundStyle(LinearGradient.chloeHeadingGradient)
                    .luminousBloom(trigger: appeared)

                Spacer().frame(height: Spacing.xs)

                Text(viewModel.statusText)
                    .font(.chloeStatus)
                    .tracking(3)
                    .textCase(.uppercase)
                    .foregroundColor(.chloeTextTertiary)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeIn(duration: 0.5).delay(0.5), value: appeared)

                Spacer().frame(height: Spacing.xl)

                if !viewModel.ghostMessages.isEmpty {
                    VStack(spacing: Spacing.xxs) {
                        ForEach(viewModel.ghostMessages) { msg in
                            ghostBubble(msg)
                        }
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .opacity(appeared ? 0.4 : 0)
                    .animation(.easeIn(duration: 0.4).delay(0.7), value: appeared)
                    .onTapGesture {
                        activateChat()
                    }
                }

                Spacer()

                chatInputBar
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 40)
                    .animation(.chloeSpring.delay(0.6), value: appeared)
            }
        }
    }

    // MARK: - Chat Layout

    private var chatLayout: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: Spacing.xs) {
                    // Load older messages button (pagination)
                    if chatVM.hasOlderMessages {
                        Button {
                            chatVM.loadOlderMessages()
                        } label: {
                            Text("Load earlier messages")
                                .font(.chloeCaption)
                                .foregroundColor(.chloePrimary)
                                .padding(.vertical, Spacing.xs)
                        }
                    }

                    ForEach(Array(chatVM.messages.enumerated()), id: \.element.id) { index, message in
                        let previousUserMessage = viewModel.findPreviousUserMessage(beforeIndex: index, in: chatVM.messages)
                        ChatBubble(
                            message: message,
                            conversationId: chatVM.conversationId ?? "",
                            previousUserMessage: previousUserMessage,
                            feedbackState: viewModel.feedbackStates[message.id] ?? .none,
                            onFeedback: { rating in
                                viewModel.handleFeedback(
                                    for: message,
                                    conversationId: chatVM.conversationId,
                                    previousUserMessage: previousUserMessage,
                                    rating: rating
                                )
                            },
                            onReport: {
                                reportingMessage = message
                                reportingPreviousUserMessage = previousUserMessage ?? ""
                            },
                            onOptionSelect: { option in
                                chatVM.inputText = "I'll go with: \(option.label)"
                                Task { await chatVM.sendMessage() }
                            }
                        )
                        .id(message.id)
                    }

                    if chatVM.isTyping {
                        HStack {
                            TypingIndicator()
                                .accessibilityLabel("Chloe is typing")
                            Spacer()
                        }
                    }

                    Color.clear
                        .frame(height: 24)
                        .id("bottomSpacer")
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.vertical, Spacing.sm)
            }
            .contentMargins(.top, 56, for: .scrollContent)
            .scrollDismissesKeyboard(.interactively)
            .defaultScrollAnchor(.bottom)
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 0) {
                    // Offline indicator
                    if chatVM.isOffline {
                        HStack(spacing: Spacing.xxxs) {
                            Image(systemName: "wifi.slash")
                                .font(.system(size: 12, weight: .medium))
                                .accessibilityHidden(true)
                            Text("No internet connection")
                                .font(.chloeCaption)
                        }
                        .foregroundColor(.chloeTextTertiary)
                        .padding(.horizontal, Spacing.screenHorizontal)
                        .padding(.bottom, Spacing.xxxs)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.3), value: chatVM.isOffline)
                        .accessibilityElement(children: .combine)
                        .accessibilityAddTraits(.updatesFrequently)
                    }

                    // Error / retry banner
                    if let error = chatVM.errorMessage, !chatVM.isOffline || chatVM.lastFailedText != nil {
                        HStack {
                            if chatVM.lastFailedText != nil {
                                Button {
                                    Task { await chatVM.retryLastMessage() }
                                } label: {
                                    HStack(spacing: Spacing.xxxs) {
                                        Image(systemName: "arrow.clockwise")
                                            .font(.system(size: 12, weight: .medium))
                                        Text(error)
                                            .font(.chloeCaption)
                                    }
                                    .foregroundColor(.chloeRosewood)
                                }
                                .accessibilityLabel("Retry message")
                            } else {
                                Text(error)
                                    .font(.chloeCaption)
                                    .foregroundColor(.chloeRosewood)
                            }

                            Spacer()

                            Button {
                                chatVM.errorMessage = nil
                                chatVM.lastFailedText = nil
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.chloeTextTertiary)
                                    .frame(width: 24, height: 24)
                            }
                            .accessibilityLabel("Dismiss error")
                        }
                        .padding(.horizontal, Spacing.screenHorizontal)
                        .padding(.bottom, Spacing.xxxs)
                    }

                    chatInputBar
                }
                .background(Color.clear)
            }
            .onChange(of: chatVM.messages.count) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation {
                        proxy.scrollTo("bottomSpacer", anchor: .bottom)
                    }
                }
            }
            .onChange(of: chatVM.isTyping) {
                if chatVM.isTyping {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        withAnimation {
                            proxy.scrollTo("bottomSpacer", anchor: .bottom)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Shared Input Bar

    @ViewBuilder
    private var chatInputBar: some View {
        if chatVM.isLimitReached {
            rechargingCard
        } else {
            ChatInputBar(
                text: $chatVM.inputText,
                pendingImage: $chatVM.pendingImage,
                isSending: chatVM.isSending,
                onSend: {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    if !chatActive { activateChat() }
                    Task { await chatVM.sendMessage() }
                },
                onRecentsPressed: { showRecentsSheet = true },
                onTakePhoto: { showCamera = true },
                onUploadImage: { showPhotoPicker = true },
                onPickFile: { showFileImporter = true },
                onFocus: {
                    if !chatActive { activateChat() }
                }
            )
        }
    }

    // MARK: - Recharging Card

    private var rechargingCard: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 36))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.chloePrimary, .chloePrimary.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .accessibilityHidden(true)

            Text("Chloe is recharging")
                .font(.chloeHeadline)
                .foregroundColor(.chloeTextPrimary)

            Text("She'll be back tomorrow with fresh energy for you.")
                .font(.chloeBodyDefault)
                .foregroundColor(.chloeTextSecondary)
                .multilineTextAlignment(.center)

            Button {
                // TODO: Navigate to paywall / premium purchase
            } label: {
                Text("Unlock Unlimited")
                    .font(.chloeBodyDefault.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.xs)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.chloePrimary, .chloePrimary.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
            }
            .padding(.top, Spacing.xxs)
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Spacing.cornerRadiusLarge)
                .fill(Color.chloePrimaryLight.opacity(0.5))
        )
        .padding(.horizontal, Spacing.screenHorizontal)
        .padding(.bottom, Spacing.sm)
    }

    // MARK: - Recents Sheet

    private var recentsSheet: some View {
        NavigationStack {
            List {
                if viewModel.conversations.isEmpty {
                    Text("No recent conversations")
                        .font(.chloeBodyDefault)
                        .foregroundColor(.chloeTextTertiary)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(viewModel.conversations.prefix(15)) { convo in
                        Button {
                            showRecentsSheet = false
                            chatVM.conversationId = convo.id
                            chatVM.messages = SyncDataService.shared.loadMessages(forConversation: convo.id)
                            withAnimation(.chloeSpring) {
                                chatActive = true
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(convo.title)
                                    .font(.chloeBodyDefault)
                                    .foregroundColor(.chloeTextPrimary)
                                    .lineLimit(1)
                                Text(convo.updatedAt, style: .relative)
                                    .font(.chloeCaption)
                                    .foregroundColor(.chloeTextTertiary)
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(Color.clear)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.chloeBackground)
            .navigationTitle("Recent Chats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showRecentsSheet = false }
                        .foregroundColor(.chloePrimary)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Ghost Bubble

    private func ghostBubble(_ message: Message) -> some View {
        HStack {
            if message.role == .user { Spacer(minLength: 60) }

            Text(message.text)
                .font(message.role == .user ? .chloeBodyDefault.weight(.medium) : .chloeBodyDefault.weight(.light))
                .foregroundColor(.chloeTextPrimary)
                .lineSpacing(8.5)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(
                    message.role == .user
                        ? Color.chloeUserBubble
                        : Color.chloePrimaryLight
                )
                .cornerRadius(Spacing.cornerRadius)
                .lineLimit(2)
                .accessibilityLabel(message.role == .user ? "You said: \(message.text)" : "Chloe said: \(message.text)")

            if message.role == .chloe { Spacer(minLength: 60) }
        }
    }

    // MARK: - Edge Swipe Gesture

    private var isInNestedScreen: Bool {
        activeDestination != nil
    }

    private var edgeSwipeDragGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onEnded { value in
                guard !isInNestedScreen else { return }
                let horizontal = value.translation.width
                if !sidebarOpen && horizontal > 80 && value.startLocation.x < 30 {
                    openSidebar()
                } else if sidebarOpen && horizontal < -80 {
                    closeSidebar()
                }
            }
    }

    // MARK: - View Helpers

    private func activateChat() {
        withAnimation(.chloeSpring) {
            chatActive = true
        }
    }

    private func openSidebar() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        UISelectionFeedbackGenerator().selectionChanged()
        viewModel.loadConversations()
        sidebarOpen = true
    }

    private func closeSidebar(then action: (() -> Void)? = nil) {
        sidebarOpen = false
        if let action {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                action()
            }
        }
    }

    private func reopenSidebarIfNeeded() {
        guard navigatedFromSidebar else { return }
        navigatedFromSidebar = false
        sidebarOpen = true
    }
}

#Preview {
    NavigationStack {
        SanctuaryView()
    }
}
