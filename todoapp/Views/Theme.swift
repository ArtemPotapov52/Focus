import SwiftUI

extension Color {
    static let appBg = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.07, alpha: 1) : UIColor(Color(hex: "f9f9f9")) })
    static let appText = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.93, alpha: 1) : UIColor(Color(hex: "1a1c1c")) })
    static let appTextSec = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.55, alpha: 1) : UIColor(Color(hex: "444748")) })
    static let appGrayBg = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.15, alpha: 1) : UIColor(Color(hex: "eeeeee")) })
    static let appBorder = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.25, alpha: 1) : UIColor(Color(hex: "c4c7c7")) })
    static let appBubble = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.15, alpha: 1) : UIColor(Color(hex: "f3f3f4")) })
    static let appWhite = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.12, alpha: 1) : UIColor(Color(hex: "ffffff")) })
    static let appAccent = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.4, green: 0.75, blue: 1, alpha: 1) : UIColor(Color(hex: "006685")) })
    static let appAccentBg = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.1, green: 0.2, blue: 0.3, alpha: 0.5) : UIColor(Color(hex: "bfe9ff")) })
    static let appGreenBg = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.06, green: 0.12, blue: 0.06, alpha: 1) : UIColor(Color(hex: "f0f7f0")) })
    static let appBlueBg = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.06, green: 0.1, blue: 0.18, alpha: 1) : UIColor(Color(hex: "eef6ff")) })
    static let appPinkBg = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.18, green: 0.06, blue: 0.06, alpha: 1) : UIColor(Color(hex: "fff5f5")) })
}

extension ShapeStyle where Self == Color {
    static var appBg: Color { Color.appBg }
    static var appText: Color { Color.appText }
    static var appTextSec: Color { Color.appTextSec }
    static var appGrayBg: Color { Color.appGrayBg }
    static var appBorder: Color { Color.appBorder }
    static var appBubble: Color { Color.appBubble }
    static var appWhite: Color { Color.appWhite }
    static var appAccent: Color { Color.appAccent }
    static var appAccentBg: Color { Color.appAccentBg }
    static var appGreenBg: Color { Color.appGreenBg }
    static var appBlueBg: Color { Color.appBlueBg }
    static var appPinkBg: Color { Color.appPinkBg }
}
