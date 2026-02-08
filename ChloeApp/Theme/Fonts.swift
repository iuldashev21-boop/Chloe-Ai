import SwiftUI

enum ChloeFont {
    static let heroBoldItalic = "CormorantGaramond-BoldItalic"
    static let headerDisplay = "Cinzel-Regular"
}

extension Font {
    // MARK: - Dynamic Type–aware semantic fonts
    // Each maps to the nearest Apple text style so the system scales them with accessibility settings.

    static let chloeLargeTitle = Font.system(.largeTitle, weight: .medium)
    static let chloeTitle = Font.system(.title, weight: .medium)
    static let chloeTitle2 = Font.system(.title2)
    static let chloeHeadline = Font.system(.headline, weight: .medium)
    static let chloeSubheadline = Font.system(.subheadline, weight: .medium)
    static let chloeBodyDefault = Font.system(.body)
    static let chloeCaption = Font.system(.footnote)
    static let chloeCaptionLight = Font.system(.footnote, weight: .light)

    // Custom fonts with relativeTo: scales with Dynamic Type while keeping the custom typeface
    static let chloeButton = Font.custom(ChloeFont.headerDisplay, size: 15, relativeTo: .subheadline)
    static let chloeGreeting = Font.custom(ChloeFont.heroBoldItalic, size: 38, relativeTo: .largeTitle)
    static let chloeStatus = Font.custom(ChloeFont.headerDisplay, size: 11, relativeTo: .caption2)
    static let chloeSidebarAppName = Font.custom(ChloeFont.heroBoldItalic, size: 24, relativeTo: .title)
    static let chloeSidebarSectionHeader = Font.custom(ChloeFont.headerDisplay, size: 11, relativeTo: .caption2)
    static let chloeSidebarMenuItem = Font.custom(ChloeFont.headerDisplay, size: 14, relativeTo: .footnote)
    static let chloeSidebarChatItem = Font.system(.footnote)

    static let chloeOnboardingQuestion = Font.custom(ChloeFont.heroBoldItalic, size: 40, relativeTo: .largeTitle)

    static func chloeInputPlaceholder(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular)
    }
}

// MARK: - Typography Style Modifiers

struct ChloeEditorialHeadingStyle: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .font(.chloeOnboardingQuestion)
            .tracking(1)
            .foregroundStyle(
                LinearGradient(
                    colors: colorScheme == .dark
                        ? [Color(hex: "#D4A0A8"), Color(hex: "#8E5A5E")]
                        : [Color(hex: "#2D2324"), Color(hex: "#8E5A5E")],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .shadow(
                color: colorScheme == .dark
                    ? Color(hex: "#8E5A5E").opacity(0.3)
                    : Color(hex: "#2D2324").opacity(0.15),
                radius: 4, y: 2
            )
    }
}

extension View {
    func chloeEditorialHeading() -> some View {
        modifier(ChloeEditorialHeadingStyle())
    }
}
