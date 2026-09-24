

import SwiftUI
import UIKit


extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex.trimmingCharacters(in: .init(charactersIn: "#")))
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb & 0xFF0000) >> 16) / 255
        let g = Double((rgb & 0x00FF00) >> 8) / 255
        let b = Double(rgb & 0x0000FF) / 255
        self.init(red: r, green: g, blue: b)
    }
}



enum FinoraColor {
    static let background = Color(hex: "081712")
    static let backgroundOnb = Color(hex: "E5E5D8")
    static let surface = Color(hex: "0F241D")
    static let surface2 = Color(hex: "051613")
    static let surfaceElevated = Color(hex: "1B3A30")

    static let verdant = Color(hex: "386B4A")  
    static let brassGold = Color(hex: "DDBA4C")
    static let coral = Color(hex: "E8735F")
    static let slate = Color(hex: "6E8CA0")

    static let textPrimary = Color(hex: "F5F7F2")
    static let textSecondary = Color(hex: "8FA398")
    static let textTertiary = Color(hex: "8FA398").opacity(0.6)

    static let divider = Color(hex: "8FA398").opacity(0.15)
    static let inputBorder = Color(hex: "8FA398").opacity(0.3)
    static let cardBorder = Color(hex: "F5F7F2").opacity(0.06)

    static let brandGradient = LinearGradient(
        colors: [verdant, brassGold],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let backgroundGradient = LinearGradient(
        colors: [Color(hex: "0E2A22"), Color(hex: "1F6F54")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

  
    static let screenBackground = LinearGradient(
        colors: [Color(hex: "0D231D"), Color(hex: "0B1F1A")],
        startPoint: .top,
        endPoint: .bottom
    )

    static func amountColor(for type: TransactionType) -> Color {
        switch type {
        case .expense: return coral
        case .income: return verdant
        case .transfer: return slate
        }
    }
}



enum FinoraScreen {
    static var widthScale: CGFloat {
        let width = UIScreen.main.bounds.width
        return min(max(width / 390, 0.92), 1.12)
    }
}



enum FinoraFont {

    static let splashWordmark = Font.system(.title, design: .serif, weight: .semibold)
    static let onboardingHeadline = Font.system(.title, design: .serif, weight: .semibold)
    static let screenTitle = Font.system(.title2, design: .serif, weight: .semibold)
    static let paywallHeadline = Font.system(.title, design: .serif, weight: .semibold)


    static func amount(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size * FinoraScreen.widthScale, weight: weight, design: .rounded)
    }
    static let heroBalance = amount(44, weight: .bold)
    static let cardAmount = amount(20, weight: .semibold)
    static let priceDisplay = amount(32, weight: .bold)

    static let body = Font.system(.subheadline)
    static let bodyMedium = Font.system(.subheadline, weight: .medium)
    static let caption = Font.system(.footnote, weight: .medium)
    static let micro = Font.system(.caption2, weight: .medium)
    static let buttonLabel = Font.system(.body, weight: .semibold)
}


enum FinoraMetric {
    static let screenPadding: CGFloat = 20
    static let gridUnit: CGFloat = 8

    static let cardRadius: CGFloat = 20
    static let chipRadius: CGFloat = 14
    static let sheetRadius: CGFloat = 28

    static let buttonHeight: CGFloat = 54
    static let inputHeight: CGFloat = 52
    static let fabSize: CGFloat = 56
    static let tabBarHeight: CGFloat = 49

    static let cardShadow = Color.black.opacity(0.25)
}



enum CurrencyCode {
    static let common = ["USD", "EUR", "UAH", "GBP", "PLN", "CAD", "AUD", "JPY", "CHF", "CZK", "SEK", "NOK", "TRY", "CNY", "INR"]
}


enum CategoryPalette {
    static let terracotta = "D97757"
    static let dustyBlue = "6B93B0"
    static let dustyPlum = "8B7BA8"
    static let sage = "6FA98C"
    static let brassGold = "DDBA4C"
    static let dustyRose = "C97B92"
    static let mutedTeal = "4E9B9B"
    static let warmGray = "8FA398"

    static let all = [terracotta, dustyBlue, dustyPlum, sage, brassGold, dustyRose, mutedTeal, warmGray]
}



struct CardBackground: ViewModifier {
    var elevated: Bool = false
    func body(content: Content) -> some View {
        let base = elevated ? FinoraColor.surfaceElevated : FinoraColor.surface
        content
            .background(
                LinearGradient(
                    colors: [base, base.opacity(0.88)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: FinoraMetric.cardRadius, style: .continuous)
                    .stroke(FinoraColor.cardBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: FinoraMetric.cardRadius, style: .continuous))
            .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 6)
    }
}

extension View {
    func finoraCard(elevated: Bool = false) -> some View {
        modifier(CardBackground(elevated: elevated))
    }
}
