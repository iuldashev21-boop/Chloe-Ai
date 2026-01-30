import SwiftUI

enum ChloeFont {
    static let headingRegular = "PlayfairDisplay-Regular"
    static let headingMedium = "PlayfairDisplay-Medium"
    static let bodyRegular = "Inter-Regular"
    static let bodyMedium = "Inter-Medium"
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
}
