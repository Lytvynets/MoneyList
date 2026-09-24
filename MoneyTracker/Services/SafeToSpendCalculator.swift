
import Foundation

enum SafeToSpendCalculator {

    static func safeToSpendToday(
        totalBalance: Decimal,
        budgets: [Budget],
        spentByCategory: [UUID: Decimal],
        goalReservations: Decimal,
        today: Date = .now
    ) -> Decimal {
        let remainingBudgetObligations = budgets.reduce(Decimal(0)) { partial, budget in
            guard let categoryID = budget.category?.id else { return partial }
            let spent = spentByCategory[categoryID] ?? 0
            let remaining = max(budget.limitAmount - spent, 0)
            return partial + remaining
        }

        let available = totalBalance - remainingBudgetObligations - goalReservations
        let days = Decimal(today.daysRemainingInMonth)
        guard days > 0 else { return max(available, 0) }
        return max(available / days, 0)
    }

    static func isOverPace(spentToday: Decimal, safeToSpendToday: Decimal) -> Bool {
        guard safeToSpendToday > 0 else { return spentToday > 0 }
        return spentToday > safeToSpendToday * Decimal(1.15)
    }

    static func progress(spent: Decimal, limit: Decimal) -> Double {
        guard limit > 0 else { return 0 }
        let value = (spent / limit) as NSDecimalNumber
        return min(max(value.doubleValue, 0), 1)
    }
}
