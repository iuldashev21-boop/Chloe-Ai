import SwiftUI
import UIKit

extension Color {
    static var chloeBackground: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "#1A1517")
                : UIColor(hex: "#FFF8F0")
        })
    }

    static var chloeSurface: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "#241E20")
                : UIColor(hex: "#FAFAFA")
        })
    }

    static var chloePrimary: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "#C4848D")
                : UIColor(hex: "#B76E79")
        })
    }

    static var chloePrimaryLight: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "#2D2226")
                : UIColor(hex: "#FFF0EB")
        })
    }

    static var chloeAccent: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "#D4907E")
                : UIColor(hex: "#F4A896")
        })
    }

    static var chloeAccentMuted: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "#8E6E66")
                : UIColor(hex: "#E8B4A8")
        })
    }

    static var chloeTextPrimary: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "#F5F0EB")
                : UIColor(hex: "#2D2324")
        })
    }

    static var chloeTextSecondary: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "#B8A5A7")
                : UIColor(hex: "#6B6B6B")
        })
    }

    static var chloeTextTertiary: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "#7A6E70")
                : UIColor(hex: "#9A9A9A")
        })
    }

    static var chloeBorder: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "#3A3234")
                : UIColor(hex: "#E5E5E5")
        })
    }

    static var chloeBorderWarm: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "#3D2E30")
                : UIColor(hex: "#F0E0DA")
        })
    }

    static var chloeUserBubble: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "#2A2325")
                : UIColor(hex: "#F0F0F0")
        })
    }

    static var chloeGradientStart: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "#1A1517")
                : UIColor(hex: "#FFF8F5")
        })
    }

    static var chloeGradientEnd: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "#221A1C")
                : UIColor(hex: "#FEEAE2")
        })
    }

    static var chloeRosewood: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "#A66E72")
                : UIColor(hex: "#8E5A5E")
        })
    }

    static var chloeEtherealGold: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "#8B7B4A")
                : UIColor(hex: "#F3E5AB")
        })
    }
}

extension LinearGradient {
    static var chloeHeadingGradient: LinearGradient {
        LinearGradient(
            colors: [Color.chloePrimary, Color.chloeAccent],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
