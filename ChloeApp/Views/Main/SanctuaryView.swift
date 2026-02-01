import SwiftUI
import PhotosUI

struct SanctuaryView: View {
    @StateObject private var chatVM = ChatViewModel()
    @State private var chatActive = false
    @State private var appeared = false
    @State private var displayName = "babe"

    // Ghost messages from last session
    @State private var ghostMessages: [Message] = []

    // Sidebar
    @State private var sidebarOpen = false
    @State private var conversations: [Conversation] = []
    @State private var latestVibe: VibeScore? = nil

    // Recents sheet
    @State private var showRecentsSheet = false

    // Navigation destinations
    @State private var showJournal = false
    @State private var showHistory = false
    @State private var showVisionBoard = false
    @State private var showSettings = false

    // Camera & Photo picker
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var selectedImage: UIImage? = nil
    @State private var selectedPhotoItem: PhotosPickerItem? = nil

    private var screenWidth: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.screen.bounds.width ?? 390
    }

    var body: some View {
        ZStack(alignment: .leading) {
            // Layer 0: Background
            Color.chloeBackground
                .ignoresSafeArea()
            EtherealDustParticles()
                .ignoresSafeArea()

            // Layer 1: Sidebar
            SidebarView(
                isOpen: $sidebarOpen,
                conversations: conversations,
                latestVibe: latestVibe,
                onNewChat: {
                    chatVM.startNewChat()
                    ghostMessages = []
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                        chatActive = false
                        sidebarOpen = false
                    }
                },
                onSelectConversation: { convo in
                    chatVM.conversationId = convo.id
                    chatVM.messages = StorageService.shared.loadMessages(forConversation: convo.id)
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                        chatActive = true
                        sidebarOpen = false
                    }
                },
                onNavigate: { destination in
                    // Snap sidebar closed instantly (no animation) so the
                    // navigation push doesn't reveal the main view first.
                    var tx = Transaction()
                    tx.disablesAnimations = true
                    withTransaction(tx) {
                        sidebarOpen = false
                    }
                    switch destination {
                    case .journal: showJournal = true
                    case .history: showHistory = true
                    case .visionBoard: showVisionBoard = true
                    case .settings: showSettings = true
                    }
                }
            )
            .frame(width: screenWidth * 0.8)
            .offset(x: sidebarOpen ? 0 : -screenWidth * 0.8)

            // Layer 1: Main content
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
        .navigationDestination(isPresented: $showJournal) { JournalView() }
        .navigationDestination(isPresented: $showHistory) {
            HistoryView { convo in
                chatVM.conversationId = convo.id
                chatVM.messages = StorageService.shared.loadMessages(forConversation: convo.id)
                chatActive = true
            }
        }
        .navigationDestination(isPresented: $showVisionBoard) { VisionBoardView() }
        .navigationDestination(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showRecentsSheet) {
            recentsSheet
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPickerView { image in
                selectedImage = image
            }
            .ignoresSafeArea()
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotoItem, matching: .images)
        .onChange(of: selectedPhotoItem) {
            guard let item = selectedPhotoItem else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedImage = image
                    if !chatActive { activateChat() }
                    chatVM.inputText = chatVM.inputText.isEmpty ? "What do you think of this?" : chatVM.inputText
                }
                selectedPhotoItem = nil
            }
        }
        .onChange(of: selectedImage) {
            // Also handle camera-picked images
            if selectedImage != nil && !chatActive {
                activateChat()
                if chatVM.inputText.isEmpty {
                    chatVM.inputText = "What do you think of this?"
                }
            }
        }
        .onChange(of: chatVM.messages.count) {
            loadConversations()
        }
        .onChange(of: chatActive) {
            if !chatActive && !chatVM.messages.isEmpty {
                loadGhostMessages()
            }
        }
        .onAppear {
            loadUserData()
            loadGhostMessages()
            loadConversations()
            // Start fresh on first launch only
            if !appeared {
                chatVM.startNewChat()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                appeared = true
            }
        }
    }

    // MARK: - Main Content Wrapper

    private var mainContentWrapper: some View {
        ZStack {
            GradientBackground()

            if chatActive {
                chatLayout
                    .transition(.opacity)
            } else {
                idleLayout
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: chatActive)
        .overlay(alignment: .topLeading) {
            if !chatActive && !sidebarOpen {
                Button { openSidebar() } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.chloeTextSecondary)
                        .frame(width: 44, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                        )
                }
                .padding(.leading, Spacing.screenHorizontal)
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

                // Orb
                ChloeAvatar(size: Spacing.orbSizeSanctuary, isThinking: chatVM.isTyping)
                    .scaleEffect(appeared ? 1.0 : 0.3)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: appeared)

                Spacer().frame(height: Spacing.lg)

                // Greeting
                Text("Hey, \(displayName)")
                    .font(.chloeGreeting)
                    .tracking(36 * 0.03)
                    .foregroundStyle(LinearGradient.chloeHeadingGradient)
                    .luminousBloom(trigger: appeared)

                Spacer().frame(height: Spacing.xs)

                // Status line
                Text(statusText)
                    .font(.chloeStatus)
                    .tracking(2)
                    .textCase(.uppercase)
                    .foregroundColor(.chloeTextTertiary)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeIn(duration: 0.5).delay(0.5), value: appeared)

                Spacer().frame(height: Spacing.xl)

                // Ghost messages
                if !ghostMessages.isEmpty {
                    VStack(spacing: Spacing.xxs) {
                        ForEach(ghostMessages) { msg in
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

                // Input bar
                chatInputBar
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 40)
                    .animation(.spring(response: 0.5, dampingFraction: 0.85).delay(0.6), value: appeared)
            }
        }
    }

    // MARK: - Chat Layout

    private var chatLayout: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                // Custom top bar
                HStack {
                    Button {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                            chatActive = false
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.chloePrimary)
                            .frame(width: 44, height: 44)
                    }

                    Spacer()

                    HStack(spacing: Spacing.xxs) {
                        ChloeAvatar(size: 28, isThinking: chatVM.isTyping)
                        Text("Chat with Chloe")
                            .font(.chloeHeadline)
                            .foregroundColor(.chloeTextPrimary)
                    }

                    Spacer()

                    // Invisible spacer to balance the back button
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.top, geo.safeAreaInsets.top)
                .padding(.bottom, Spacing.xs)
                .background(.ultraThinMaterial)

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: Spacing.xs) {
                            ForEach(chatVM.messages) { message in
                                ChatBubble(message: message)
                                    .id(message.id)
                            }

                            if chatVM.isTyping {
                                HStack {
                                    TypingIndicator()
                                    Spacer()
                                }
                            }
                        }
                        .padding(.horizontal, Spacing.screenHorizontal)
                        .padding(.vertical, Spacing.sm)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .defaultScrollAnchor(.bottom)
                    .onChange(of: chatVM.messages.count) {
                        if let last = chatVM.messages.last {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                withAnimation {
                                    proxy.scrollTo(last.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                    .onChange(of: chatVM.isTyping) {
                        if chatVM.isTyping, let last = chatVM.messages.last {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                withAnimation {
                                    proxy.scrollTo(last.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }

                if let error = chatVM.errorMessage {
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
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.bottom, Spacing.xxxs)
                    .onAppear {
                        if chatVM.lastFailedText == nil {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                withAnimation {
                                    chatVM.errorMessage = nil
                                }
                            }
                        }
                    }
                }

                chatInputBar
            }
        }
        .ignoresSafeArea(.container, edges: .top)
    }

    // MARK: - Shared Input Bar

    private var chatInputBar: some View {
        ChatInputBar(
            text: $chatVM.inputText,
            onSend: {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                if !chatActive { activateChat() }
                Task { await chatVM.sendMessage() }
            },
            onRecentsPressed: { showRecentsSheet = true },
            onTakePhoto: {
                showCamera = true
            },
            onUploadImage: {
                showPhotoPicker = true
            },
            onVisionBoard: {
                closeSidebar {
                    showVisionBoard = true
                }
            }
        )
    }

    // MARK: - Recents Sheet

    private var recentsSheet: some View {
        NavigationStack {
            List {
                if conversations.isEmpty {
                    Text("No recent conversations")
                        .font(.chloeBodyDefault)
                        .foregroundColor(.chloeTextTertiary)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(conversations.prefix(15)) { convo in
                        Button {
                            showRecentsSheet = false
                            chatVM.conversationId = convo.id
                            chatVM.messages = StorageService.shared.loadMessages(forConversation: convo.id)
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
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
                .font(.chloeBodyDefault)
                .foregroundColor(.chloeTextPrimary)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(
                    message.role == .user
                        ? Color.chloeUserBubble
                        : Color.chloePrimaryLight
                )
                .cornerRadius(Spacing.cornerRadius)
                .lineLimit(2)

            if message.role == .chloe { Spacer(minLength: 60) }
        }
    }

    // MARK: - Status Text

    private var statusText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Ready when you are."
        case 12..<17: return "I'm holding space for you."
        default: return "I'm here. No rush."
        }
    }

    // MARK: - Edge Swipe Gesture

    private var isInNestedScreen: Bool {
        showJournal || showHistory || showVisionBoard || showSettings
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

    // MARK: - Helpers

    private func activateChat() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            chatActive = true
        }
    }

    private func openSidebar() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        UISelectionFeedbackGenerator().selectionChanged()
        loadConversations()
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

    private func loadUserData() {
        if let profile = StorageService.shared.loadProfile() {
            displayName = profile.displayName.isEmpty ? "babe" : profile.displayName
        }
    }

    private func loadGhostMessages() {
        // Load ghost messages from the current conversation if available,
        // otherwise fall back to the most recently updated conversation
        let targetId: String? = chatVM.conversationId ?? StorageService.shared.loadConversations()
            .sorted(by: { $0.updatedAt > $1.updatedAt })
            .first?.id
        guard let id = targetId else {
            ghostMessages = []
            return
        }
        let messages = StorageService.shared.loadMessages(forConversation: id)
        ghostMessages = Array(messages.suffix(2))
    }

    private func loadConversations() {
        conversations = StorageService.shared.loadConversations()
            .sorted(by: { $0.updatedAt > $1.updatedAt })
        latestVibe = StorageService.shared.loadLatestVibe()
    }
}

#Preview {
    NavigationStack {
        SanctuaryView()
    }
}
