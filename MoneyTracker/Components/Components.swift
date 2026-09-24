

import SwiftUI
import UIKit


enum NumericInput {
    static func sanitize(_ raw: String) -> String {
        var result = ""
        var seenDot = false
        for character in raw {
            if character == "." || character == "," {
                if !seenDot {
                    result.append(".")
                    seenDot = true
                }
            } else if character.isNumber {
                result.append(character)
            }
        }
        return result
    }
}


struct LiveNumberText: View {
    var value: Decimal
    var currencyCode: String = "USD"
    var font: Font = FinoraFont.heroBalance
    var color: Color = FinoraColor.textPrimary
    var showSign: Bool = false

    var body: some View {
        Text(formatted)
            .font(font)
            .foregroundStyle(color)
            .contentTransition(.numericText(value: doubleValue))
            .animation(.easeOut(duration: 0.5), value: doubleValue)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.55)
    }

    private var doubleValue: Double { (value as NSDecimalNumber).doubleValue }

    private var formatted: String {
        let base = value.formatted(.currency(code: currencyCode).precision(.fractionLength(0...2)))
        guard showSign, value > 0 else { return base }
        return "+\(base)"
    }
}


struct SafeToSpendRing: View {
    var amount: Decimal
    var currencyCode: String
    var daysLeft: Int
    var progress: Double
    var isOverPace: Bool

    @State private var animatedProgress: CGFloat = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(FinoraColor.divider, lineWidth: 3)

            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    isOverPace ? FinoraColor.coral : FinoraColor.verdant,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 4) {
                Text("Safe to spend until the end of the month")
                    .font(FinoraFont.caption)
                    .foregroundStyle(FinoraColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                LiveNumberText(value: amount, currencyCode: currencyCode, font: FinoraFont.heroBalance)

                Text("out of \(daysLeft) days left")
                    .font(FinoraFont.caption)
                    .foregroundStyle(FinoraColor.textSecondary)
            }
        }
        .frame(width: 280, height: 280)
        .onAppear {
            withAnimation(.easeOut(duration: 1.1)) { animatedProgress = CGFloat(progress) }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.easeOut(duration: 0.6)) { animatedProgress = CGFloat(newValue) }
        }
    }
}



struct CustomSegmentedControl<Option: Hashable>: View {
    let options: [(value: Option, label: String)]
    @Binding var selection: Option

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.value) { option in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selection = option.value }
                } label: {
                    Text(option.label)
                        .font(FinoraFont.bodyMedium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selection == option.value ? FinoraColor.surfaceElevated : Color.clear)
                        .foregroundStyle(selection == option.value ? FinoraColor.textPrimary : FinoraColor.textSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(FinoraColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}


struct PrimaryButton: View {
    var title: String
    var icon: String? = nil
    var isLoading: Bool = false
    var gradient: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    if let icon { Image(systemName: icon) }
                    Text(title).font(FinoraFont.buttonLabel)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: FinoraMetric.buttonHeight)
            .foregroundStyle(.white)
            .background(gradient ? AnyShapeStyle(FinoraColor.brandGradient) : AnyShapeStyle(FinoraColor.verdant))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: FinoraColor.verdant.opacity(0.25), radius: 10, x: 0, y: 4)
        }
        .disabled(isLoading)
    }
}

struct SecondaryButton: View {
    var title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(FinoraFont.buttonLabel)
                .frame(maxWidth: .infinity)
                .frame(height: FinoraMetric.buttonHeight)
                .foregroundStyle(FinoraColor.textPrimary)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(FinoraColor.inputBorder, lineWidth: 1.5)
                )
        }
    }
}


struct PillBadge: View {
    var text: String
    var filled: Bool = true

    var body: some View {
        Text(text)
            .font(FinoraFont.micro)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(filled ? FinoraColor.brassGold : Color.clear)
            .foregroundStyle(filled ? FinoraColor.background : FinoraColor.brassGold)
            .overlay(
                Capsule().stroke(FinoraColor.brassGold, lineWidth: filled ? 0 : 1)
            )
            .clipShape(Capsule())
    }
}

struct FilterChip: View {
    var title: String
    var systemImage: String? = nil
    var isSelected: Bool
    var tint: Color = FinoraColor.verdant
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title)
            }
            .font(FinoraFont.bodyMedium)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? tint : FinoraColor.surface)
            .foregroundStyle(isSelected ? Color.white : FinoraColor.textSecondary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}


struct CategoryIconView: View {
    var iconName: String
    var colorHex: String
    var size: CGFloat = 40

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: colorHex).opacity(0.18))
            Image(systemName: iconName)
                .font(.system(size: size * 0.45, weight: .semibold))
                .foregroundStyle(Color(hex: colorHex))
        }
        .frame(width: size, height: size)
    }
}


struct AccountCardView: View {
    var account: Account
    var isSelected: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: account.type.iconName)
                    .foregroundStyle(FinoraColor.verdant)
                Spacer()
            }
            Text(account.name)
                .font(FinoraFont.caption)
                .foregroundStyle(FinoraColor.textSecondary)
            LiveNumberText(value: account.balance, currencyCode: account.currencyCode, font: FinoraFont.cardAmount)
        }
        .padding(14)
        .frame(width: 150, height: 90, alignment: .topLeading)
        .background(FinoraColor.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isSelected ? FinoraColor.verdant : .clear, lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}


struct AddAccountCard: View {
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .semibold))
                Text("Add account").font(FinoraFont.caption)
            }
            .foregroundStyle(FinoraColor.textSecondary)
            .frame(width: 150, height: 90)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                    .foregroundStyle(FinoraColor.inputBorder)
            )
        }
    }
}


struct InvestmentCardView: View {
    var value: Decimal
    var currencyCode: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(FinoraColor.brassGold)
                Spacer()
            }
            Text("Investments")
                .font(FinoraFont.caption)
                .foregroundStyle(FinoraColor.textSecondary)
            LiveNumberText(value: value, currencyCode: currencyCode, font: FinoraFont.cardAmount)
        }
        .padding(14)
        .frame(width: 150, height: 90, alignment: .topLeading)
        .background(FinoraColor.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(FinoraColor.brassGold.opacity(0.4), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}


struct TransactionRowView: View {
    var transaction: Transaction

    private var title: String {
        if let note = transaction.note, !note.isEmpty { return note }
        if transaction.type == .transfer { return "Transfer" }
        return transaction.category?.name ?? transaction.type.displayName
    }


    private var subtitle: String? {
        if transaction.type == .transfer {
            return transaction.toAccount.map { "→ \($0.name)" }
        }
        guard let note = transaction.note, !note.isEmpty else { return nil }
        return transaction.category?.name
    }

    var body: some View {
        HStack(spacing: 12) {
            CategoryIconView(
                iconName: transaction.category?.iconName ?? "arrow.left.arrow.right",
                colorHex: transaction.category?.colorHex ?? FinoraColor.slate.toHex(),
                size: 36
            )
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(FinoraFont.bodyMedium)
                    .foregroundStyle(FinoraColor.textPrimary)
                    .lineLimit(1)
                if let subtitle {
                    Text(subtitle)
                        .font(FinoraFont.caption)
                        .foregroundStyle(FinoraColor.textSecondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                LiveNumberText(
                    value: transaction.type == .expense ? -transaction.amount : transaction.amount,
                    currencyCode: transaction.account?.currencyCode ?? "USD",
                    font: FinoraFont.cardAmount,
                    color: FinoraColor.amountColor(for: transaction.type)
                )
                Text(transaction.date.formatted(date: .omitted, time: .shortened))
                    .font(FinoraFont.micro)
                    .foregroundStyle(FinoraColor.textTertiary)
            }
        }
        .padding(.vertical, 8)
    }
}


struct EmptyStateView: View {
    var icon: String
    var title: String
    var subtitle: String
    var buttonTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle().fill(FinoraColor.brandGradient.opacity(0.15)).frame(width: 72, height: 72)
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundStyle(FinoraColor.brassGold)
            }
            VStack(spacing: 6) {
                Text(title).font(FinoraFont.bodyMedium).foregroundStyle(FinoraColor.textPrimary)
                Text(subtitle)
                    .font(FinoraFont.body)
                    .foregroundStyle(FinoraColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
            if let buttonTitle, let action {
                PrimaryButton(title: buttonTitle, gradient: false, action: action)
                    .frame(maxWidth: 220)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .finoraCard()
    }
}


extension View {
    func tabBarSafeArea() -> some View {
        safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: FinoraMetric.tabBarHeight + 24)
        }
    }
}


extension Color {
    func toHex() -> String {
        UIColor(self).toHexString()
    }
}

extension UIColor {
    func toHexString() -> String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
