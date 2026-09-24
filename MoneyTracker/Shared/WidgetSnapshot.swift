
import Foundation

struct WidgetSnapshot: Codable {

    struct CategorySlice: Codable, Identifiable {
        var id: String { name }
        let name: String
        let amount: Double
        let colorHex: String
    }

    struct TransactionSnapshot: Codable, Identifiable {
        var id = UUID()
        let title: String
        let subtitle: String
        let amountDisplay: String
        let isExpense: Bool
        let timeDisplay: String
    }

    var safeToSpendDisplay: String
    var daysLeft: Int
    var budgetSpentDisplay: String
    var budgetLimitDisplay: String
    var budgetProgress: Double
    var categories: [CategorySlice]
    var recentTransactions: [TransactionSnapshot]

    static let appGroupID = "group.com.finora.app"
    private static let storageKey = "finora.widget.snapshot"

    static func load() -> WidgetSnapshot {
        guard
            let defaults = UserDefaults(suiteName: appGroupID),
            let data = defaults.data(forKey: storageKey),
            let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
        else {
            return .placeholder
        }
        return snapshot
    }

    func save() {
        guard
            let defaults = UserDefaults(suiteName: Self.appGroupID),
            let data = try? JSONEncoder().encode(self)
        else { return }
        defaults.set(data, forKey: Self.storageKey)
    }

    static let placeholder = WidgetSnapshot(
        safeToSpendDisplay: "$6,450",
        daysLeft: 9,
        budgetSpentDisplay: "$18,400",
        budgetLimitDisplay: "$25,000",
        budgetProgress: 0.74,
        categories: [
            .init(name: "Food & Drinks", amount: 6240, colorHex: "F2786A"),
            .init(name: "Transport", amount: 2450, colorHex: "5B8CDE"),
            .init(name: "Shopping", amount: 3120, colorHex: "9B7FD4"),
            .init(name: "Housing", amount: 6000, colorHex: "34B27F")
        ],
        recentTransactions: [
            .init(title: "Coffee House", subtitle: "Food & Drinks", amountDisplay: "-$95.00", isExpense: true, timeDisplay: "09:30"),
            .init(title: "Bolt", subtitle: "Transport", amountDisplay: "-$128.00", isExpense: true, timeDisplay: "10:15"),
            .init(title: "Salary", subtitle: "Income", amountDisplay: "+$20,000.00", isExpense: false, timeDisplay: "Yesterday")
        ]
    )
}
