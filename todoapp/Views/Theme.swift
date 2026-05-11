import SwiftUI

extension Color {
    static let appBg = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1) : UIColor(Color(hex: "f9f9f9")) })
    static let appText = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1) : UIColor(Color(hex: "1a1c1c")) })
    static let appTextSec = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.63, green: 0.63, blue: 0.63, alpha: 1) : UIColor(Color(hex: "444748")) })
    static let appGrayBg = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1) : UIColor(Color(hex: "eeeeee")) })
}
