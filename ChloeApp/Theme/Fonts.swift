import SwiftUI

enum ChloeFont {
    static let headingRegular = "PlayfairDisplay-Regular"
    static let headingMedium = "PlayfairDisplay-Medium"
    static let bodyRegular = "Inter-Regular"
    static let bodyMedium = "Inter-Medium"
    static let serifItalic = "CormorantGaramond-Italic"
    static let sidebarDisplay = "TenorSans-Regular"
}

extension Font {
    static func chloeHeading(_ size: CGFloat) -> Font {
        .custom(ChloeFont.headingRegular, size: size)
    }

    static func chloeHeadingMedium(_ size: CGFloat) -> Font {
        .custom(ChloeFont.headingMedium, size: size)
    }

    static func chloeBody(_ size: CGFloat) -> Font {
        .custom(ChloeFont.bodyRegular, size: size)
    }

    static func chloeBodyMedium(_ size: CGFloat) -> Font {
        .custom(ChloeFont.bodyMedium, size: size)
    }

    static let chloeLargeTitle = Font.custom(ChloeFont.headingMedium, size: 28)
    static let chloeTitle = Font.custom(ChloeFont.headingMedium, size: 22)
    static let chloeTitle2 = Font.custom(ChloeFont.headingRegular, size: 20)
    static let chloeHeadline = Font.custom(ChloeFont.bodyMedium, size: 17)
    static let chloeSubheadline = Font.custom(ChloeFont.bodyMedium, size: 15)
    static let chloeBodyDefault = Font.custom(ChloeFont.bodyRegular, size: 16)
    static let chloeCaption = Font.custom(ChloeFont.bodyRegular, size: 13)
    static let chloeButton = Font.custom(ChloeFont.bodyMedium, size: 15)
    static let chloeGreeting = Font.custom(ChloeFont.headingRegular, size: 36)
    static let chloeStatus = Font.custom(ChloeFont.bodyRegular, size: 11)
    static let chloeProgressLabel = Font.custom(ChloeFont.bodyRegular, size: 11)
    static let chloeSidebarSectionHeader = Font.custom(ChloeFont.bodyMedium, size: 11)
    static let chloeSidebarMenuItem = Font.custom(ChloeFont.bodyRegular, size: 15)
    static let chloeSidebarChatItem = Font.custom(ChloeFont.bodyRegular, size: 14)

    static let chloeOnboardingQuestion = Font.custom(ChloeFont.serifItalic, size: 26)

    static func chloeInputPlaceholder(_ size: CGFloat) -> Font {
        .custom(ChloeFont.bodyRegular, size: size)
    }
}
