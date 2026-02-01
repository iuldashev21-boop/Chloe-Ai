import SwiftUI

enum ChloeFont {
    static let heroBoldItalic = "CormorantGaramond-BoldItalic"
    static let headerDisplay = "Cinzel-Regular"
    static let editorialBoldItalic = "PlayfairDisplay-Italic"
}

extension Font {
    static func chloeHeading(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular)
    }

    static func chloeHeadingMedium(_ size: CGFloat) -> Font {
        .system(size: size, weight: .medium)
    }

    static func chloeBody(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular)
    }

    static func chloeBodyMedium(_ size: CGFloat) -> Font {
        .system(size: size, weight: .medium)
    }

    static let chloeLargeTitle = Font.system(size: 28, weight: .medium)
    static let chloeTitle = Font.system(size: 22, weight: .medium)
    static let chloeTitle2 = Font.system(size: 20, weight: .regular)
    static let chloeHeadline = Font.system(size: 17, weight: .medium)
    static let chloeSubheadline = Font.system(size: 15, weight: .medium)
    static let chloeBodyDefault = Font.system(size: 17, weight: .regular)
    static let chloeBodyLight = Font.system(size: 17, weight: .light)
    static let chloeCaption = Font.system(size: 14, weight: .regular)
    static let chloeCaptionLight = Font.system(size: 14, weight: .light)
    static let chloeButton = Font.custom(ChloeFont.headerDisplay, size: 15)
    static let chloeGreeting = Font.custom(ChloeFont.heroBoldItalic, size: 38)
    static let chloeStatus = Font.custom(ChloeFont.headerDisplay, size: 11)
    static let chloeProgressLabel = Font.system(size: 11, weight: .light)
    static let chloeSidebarSectionHeader = Font.custom(ChloeFont.headerDisplay, size: 12)
    static let chloeSidebarMenuItem = Font.system(size: 15, weight: .regular)
    static let chloeSidebarChatItem = Font.system(size: 14, weight: .regular)

    static let chloeOnboardingQuestion = Font.custom(ChloeFont.heroBoldItalic, size: 40)

    static func chloeInputPlaceholder(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular)
    }
}

// MARK: - Typography Style Modifiers

struct ChloeEditorialHeadingStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.chloeOnboardingQuestion)
            .tracking(1)
            .foregroundStyle(
                LinearGradient(
                    colors: [Color(hex: "#2D2324"), Color(hex: "#8E5A5E")],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .shadow(color: Color(hex: "#2D2324").opacity(0.15), radius: 4, y: 2)
    }
}

struct ChloeHeroStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.chloeGreeting)
            .tracking(34 * -0.02)
    }
}

struct ChloeSecondaryHeaderStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.chloeSidebarSectionHeader)
            .tracking(3)
            .textCase(.uppercase)
    }
}

struct ChloeBodyStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.chloeBodyDefault)
            .lineSpacing(17 * 0.5)
    }
}

struct ChloeCaptionStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.chloeCaption)
            .lineSpacing(14 * 0.5)
    }
}

struct ChloeButtonTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.chloeButton)
            .tracking(3)
    }
}

extension View {
    func chloeEditorialHeading() -> some View {
        modifier(ChloeEditorialHeadingStyle())
    }

    func chloeHeroStyle() -> some View {
        modifier(ChloeHeroStyle())
    }

    func chloeSecondaryHeaderStyle() -> some View {
        modifier(ChloeSecondaryHeaderStyle())
    }

    func chloeBodyStyle() -> some View {
        modifier(ChloeBodyStyle())
    }

    func chloeCaptionStyle() -> some View {
        modifier(ChloeCaptionStyle())
    }

    func chloeButtonTextStyle() -> some View {
        modifier(ChloeButtonTextStyle())
    }
}
