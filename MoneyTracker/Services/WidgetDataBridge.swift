

import Foundation
import SwiftData
import WidgetKit

@MainActor
enum WidgetDataBridge {

    static func refresh(context: ModelContext, convert: (Decimal, String, String) -> Decimal) {
        do {
            let accounts = try context.fetch(FetchDescriptor<Account>())
            let budgets = try context.fetch(FetchDescriptor<Budget>())
            let transactions = try context.fetch(
                FetchDescriptor<Transaction>(sortBy: [SortDescriptor(\.date, order: .reverse)])
            )
            let profiles = try context.fetch(FetchDescriptor<UserProfile>())

            let currency = profiles.first?.defaultCurrencyCode ?? accounts.first?.currencyCode ?? "USD"

            let monthStart = Date().startOfMonth
            let thisMonthBudgets = budgets.filter {
                Calendar.current.isDate($0.month, equalTo: monthStart, toGranularity: .month)
            }
            let thisMonthTransactions = transactions.filter { $0.date >= monthStart }

            func convertedAmount(_ transaction: Transaction) -> Decimal {
                convert(transaction.amount, transaction.account?.currencyCode ?? currency, currency)
            }

            var spentByCategory: [UUID: Decimal] = [:]
            for transaction in thisMonthTransactions where transaction.type == .expense {
                guard let id = transaction.category?.id else { continue }
                spentByCategory[id, default: 0] += convertedAmount(transaction)
            }

            let totalBalance = accounts
                .filter { !$0.isArchived }
                .reduce(Decimal(0)) { $0 + convert($1.balance, $1.currencyCode, currency) }

            let safeToSpend = SafeToSpendCalculator.safeToSpendToday(
                totalBalance: totalBalance,
                budgets: thisMonthBudgets,
                spentByCategory: spentByCategory,
                goalReservations: 0
            )

            let totalSpent = thisMonthTransactions.filter { $0.type == .expense }.reduce(Decimal(0)) { $0 + convertedAmount($1) }
            let totalLimit = thisMonthBudgets.reduce(Decimal(0)) { $0 + $1.limitAmount }

            var categoryTotals: [UUID: (name: String, amount: Decimal, hex: String)] = [:]
            for transaction in thisMonthTransactions where transaction.type == .expense {
                guard let category = transaction.category else { continue }
                var entry = categoryTotals[category.id] ?? (category.name, 0, category.colorHex)
                entry.amount += convertedAmount(transaction)
                categoryTotals[category.id] = entry
            }

            let snapshot = WidgetSnapshot(
                safeToSpendDisplay: safeToSpend.formatted(.currency(code: currency).precision(.fractionLength(0))),
                daysLeft: Date().daysRemainingInMonth,
                budgetSpentDisplay: totalSpent.formatted(.currency(code: currency).precision(.fractionLength(0))),
                budgetLimitDisplay: totalLimit.formatted(.currency(code: currency).precision(.fractionLength(0))),
                budgetProgress: SafeToSpendCalculator.progress(spent: totalSpent, limit: totalLimit),
                categories: categoryTotals.values
                    .sorted { $0.amount > $1.amount }
                    .prefix(4)
                    .map { .init(name: $0.name, amount: ($0.amount as NSDecimalNumber).doubleValue, colorHex: $0.hex) },
                recentTransactions: transactions.prefix(4).map { transaction in
                    .init(
                        title: transaction.note?.isEmpty == false ? transaction.note! : (transaction.category?.name ?? transaction.type.displayName),
                        subtitle: transaction.category?.name ?? transaction.type.displayName,
                        amountDisplay: (transaction.type == .expense ? "-" : "+") + transaction.amount.formatted(.currency(code: transaction.account?.currencyCode ?? currency)),
                        isExpense: transaction.type == .expense,
                        timeDisplay: transaction.date.formatted(date: .omitted, time: .shortened)
                    )
                }
            )

            snapshot.save()
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("Money List: widget snapshot refresh failed — \(error)")
        }
    }
}
