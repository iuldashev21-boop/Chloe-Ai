import SwiftUI

extension Color {
    static let chloeBackground = Color(hex: "#FFF8F0")
    static let chloeSurface = Color(hex: "#FAFAFA")
    static let chloePrimary = Color(hex: "#B76E79")
    static let chloePrimaryLight = Color(hex: "#FFF0EB")
    static let chloePrimaryDark = Color(hex: "#8A4A55")
    static let chloeAccent = Color(hex: "#F4A896")
    static let chloeAccentMuted = Color(hex: "#E8B4A8")
    static let chloeTextPrimary = Color(hex: "#2D2324")
    static let chloeTextSecondary = Color(hex: "#6B6B6B")
    static let chloeTextTertiary = Color(hex: "#9A9A9A")
    static let chloeBorder = Color(hex: "#E5E5E5")
    static let chloeBorderWarm = Color(hex: "#F0E0DA")
    static let chloeUserBubble = Color(hex: "#F0F0F0")
    static let chloeGradientStart = Color(hex: "#FFF8F5")
    static let chloeGradientEnd = Color(hex: "#FEEAE2")
    static let chloeRosewood = Color(hex: "#8E5A5E")
    static let chloeEtherealGold = Color(hex: "#F3E5AB")
}

extension LinearGradient {
    static let chloeHeadingGradient = LinearGradient(
        colors: [Color.chloePrimary, Color.chloeAccent],
        startPoint: .leading,
        endPoint: .trailing
    )
}
