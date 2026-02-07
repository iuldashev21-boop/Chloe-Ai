import SwiftUI

/// A small, unobtrusive sync status indicator.
/// Hidden when idle, shows a subtle icon for syncing/pending/error states.
struct SyncStatusBadge: View {
    let status: SyncStatus
    var onRetry: (() -> Void)? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isRotating = false
    @State private var showErrorDetail = false

    var body: some View {
        Group {
            switch status {
            case .idle:
                EmptyView()

            case .syncing:
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.chloeTextTertiary)
                    .rotationEffect(.degrees(!reduceMotion && isRotating ? 360 : 0))
                    .onAppear {
                        guard !reduceMotion else { return }
                        withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                            isRotating = true
                        }
                    }
                    .onDisappear { isRotating = false }
                    .accessibilityLabel("Syncing")

            case .pending:
                Button {
                    onRetry?()
                } label: {
                    Image(systemName: "icloud.and.arrow.up")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.chloeAccent)
                        .symbolEffect(.pulse, options: .repeating)
                }
                .accessibilityLabel("Pending sync. Tap to retry.")
                .accessibilityHint("Data has not been synced to cloud")

            case .error(let message):
                Button {
                    showErrorDetail = true
                } label: {
                    Image(systemName: "exclamationmark.icloud")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.chloeRosewood)
                }
                .accessibilityLabel("Sync error")
                .accessibilityHint(message)
                .alert("Sync Error", isPresented: $showErrorDetail) {
                    if onRetry != nil {
                        Button("Retry") { onRetry?() }
                    }
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(message)
                }
            }
        }
        .frame(width: status == .idle ? 0 : 28, height: status == .idle ? 0 : 28)
        .animation(.easeInOut(duration: 0.2), value: status)
    }
}

// MARK: - Settings Row Variant

/// A larger sync status display for the Settings screen.
struct SyncStatusSettingsRow: View {
    let status: SyncStatus
    var onRetry: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: iconName)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(iconColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text("Sync Status")
                    .font(.chloeBodyDefault)
                    .foregroundColor(.chloeTextPrimary)

                Text(statusDescription)
                    .font(.chloeCaption)
                    .foregroundColor(.chloeTextSecondary)
            }

            Spacer()

            if status == .pending || status != .idle && status != .syncing {
                Button {
                    onRetry?()
                } label: {
                    Text("Sync Now")
                        .font(.chloeCaption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.xxs)
                        .padding(.vertical, Spacing.xxxs)
                        .background(Capsule().fill(Color.chloePrimary))
                }
            } else if status == .syncing {
                ProgressView()
                    .controlSize(.small)
                    .tint(.chloePrimary)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.chloePrimary.opacity(0.6))
            }
        }
        .padding(.vertical, Spacing.xs)
    }

    private var iconName: String {
        switch status {
        case .idle: return "icloud.fill"
        case .syncing: return "arrow.triangle.2.circlepath"
        case .pending: return "icloud.and.arrow.up"
        case .error: return "exclamationmark.icloud"
        }
    }

    private var iconColor: Color {
        switch status {
        case .idle: return .chloePrimary
        case .syncing: return .chloePrimary
        case .pending: return .chloeAccent
        case .error: return .chloeRosewood
        }
    }

    private var statusDescription: String {
        switch status {
        case .idle: return "All data synced"
        case .syncing: return "Syncing..."
        case .pending: return "Changes waiting to sync"
        case .error(let msg): return msg
        }
    }

    private var showRetryButton: Bool {
        switch status {
        case .pending, .error: return true
        default: return false
        }
    }
}

// MARK: - Observation Wrappers

/// Isolates SyncDataService observation so parent views don't re-render on every syncStatus change.
struct SyncStatusBadgeWrapper: View {
    @ObservedObject private var syncService = SyncDataService.shared

    var body: some View {
        SyncStatusBadge(
            status: syncService.syncStatus,
            onRetry: {
                Task { await syncService.retryPendingSync() }
            }
        )
    }
}

/// Isolates SyncDataService observation for the Settings row variant.
struct SyncStatusSettingsRowWrapper: View {
    @ObservedObject private var syncService = SyncDataService.shared

    var body: some View {
        SyncStatusSettingsRow(
            status: syncService.syncStatus,
            onRetry: {
                Task { await syncService.retryPendingSync() }
            }
        )
    }
}

#Preview("Badge - Syncing") {
    SyncStatusBadge(status: .syncing)
        .padding()
        .background(Color.chloeBackground)
}

#Preview("Badge - Pending") {
    SyncStatusBadge(status: .pending)
        .padding()
        .background(Color.chloeBackground)
}

#Preview("Settings Row") {
    VStack {
        SyncStatusSettingsRow(status: .idle)
        SyncStatusSettingsRow(status: .syncing)
        SyncStatusSettingsRow(status: .pending)
        SyncStatusSettingsRow(status: .error("Network timeout"))
    }
    .padding()
    .background(Color.chloeBackground)
}
