

import Foundation
import SwiftData

enum SeedData {

    static let defaultExpenseCategories: [(name: String, icon: String, hex: String)] = [
        ("Food & Drinks", "fork.knife", CategoryPalette.terracotta),
        ("Transport", "car.fill", CategoryPalette.dustyBlue),
        ("Shopping", "bag.fill", CategoryPalette.dustyPlum),
        ("Home", "house.fill", CategoryPalette.sage),
        ("Entertainment", "gamecontroller.fill", CategoryPalette.brassGold),
        ("Health", "heart.fill", CategoryPalette.dustyRose),
        ("Education", "graduationcap.fill", CategoryPalette.mutedTeal),
        ("Other", "ellipsis.circle.fill", CategoryPalette.warmGray)
    ]

    static let defaultIncomeCategories: [(name: String, icon: String, hex: String)] = [
        ("Salary", "banknote.fill", CategoryPalette.sage),
        ("Freelance", "laptopcomputer", CategoryPalette.dustyBlue),
        ("Gifts", "gift.fill", CategoryPalette.brassGold),
        ("Other Income", "ellipsis.circle.fill", CategoryPalette.warmGray)
    ]

    @MainActor
    static func populateIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<TransactionCategory>()
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else { return }

        for (index, item) in defaultExpenseCategories.enumerated() {
            let category = TransactionCategory(
                name: item.name, iconName: item.icon, colorHex: item.hex,
                kind: .expense, isCustom: false, sortOrder: index
            )
            context.insert(category)
        }
        for (index, item) in defaultIncomeCategories.enumerated() {
            let category = TransactionCategory(
                name: item.name, iconName: item.icon, colorHex: item.hex,
                kind: .income, isCustom: false, sortOrder: index
            )
            context.insert(category)
        }

        let cash = Account(name: "Cash", type: .cash, currencyCode: "USD", balance: 0)
        context.insert(cash)

        let profile = UserProfile()
        context.insert(profile)

        try? context.save()
    }
}
