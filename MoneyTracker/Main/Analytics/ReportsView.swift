
import SwiftUI
import SwiftData
import Charts

struct ReportsView: View {
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query private var profiles: [UserProfile]
    @EnvironmentObject private var exchangeService: CurrencyExchangeService

    private enum Period: String, CaseIterable, Hashable { case week = "Week", month = "Month", year = "Year" }

    @State private var period: Period = .month
    @State private var selectedMonth: Date = Date().startOfMonth
    @State private var breakdownType: TransactionType = .expense

    private var currency: String { profiles.first?.defaultCurrencyCode ?? "USD" }

    private func converted(_ amount: Decimal, from code: String) -> Decimal {
        exchangeService.convert(amount, from: code, to: currency)
    }


    struct TrendPoint: Identifiable {
        let date: Date
        let income: Decimal
        let expense: Decimal
        var id: Date { date }
    }

    private var monthTransactions: [Transaction] {
        let range = monthRange(for: selectedMonth)
        return transactions.filter { $0.date >= range.start && $0.date < range.end }
    }

    private var categoryTotals: [CategoryAmount] {
        TransactionCategory.breakdown(of: monthTransactions, type: breakdownType, convert: exchangeService.convert, displayCurrency: currency)
    }

    private var breakdownTotal: Decimal { categoryTotals.reduce(0) { $0 + $1.amount } }

    private var trendData: [TrendPoint] {
        let calendar = Calendar.current
        let now = Date()
        switch period {
        case .week, .month:
            let daysBack = period == .week ? 6 : (calendar.range(of: .day, in: .month, for: now)?.count ?? 30) - 1
            let start = calendar.date(byAdding: .day, value: -daysBack, to: calendar.startOfDay(for: now))!
            var buckets: [Date: (Decimal, Decimal)] = [:]
            var day = start
            while day <= now {
                buckets[day] = (0, 0)
                day = calendar.date(byAdding: .day, value: 1, to: day)!
            }
            for transaction in transactions where transaction.date >= start {
                let key = calendar.startOfDay(for: transaction.date)
                let amount = converted(transaction.amount, from: transaction.account?.currencyCode ?? currency)
                var entry = buckets[key] ?? (0, 0)
                if transaction.type == .income { entry.0 += amount }
                if transaction.type == .expense { entry.1 += amount }
                buckets[key] = entry
            }
            return buckets.keys.sorted().map { TrendPoint(date: $0, income: buckets[$0]!.0, expense: buckets[$0]!.1) }

        case .year:
            let start = calendar.date(byAdding: .month, value: -11, to: now.startOfMonth)!
            var buckets: [Date: (Decimal, Decimal)] = [:]
            var month = start
            for _ in 0..<12 {
                buckets[month] = (0, 0)
                month = calendar.date(byAdding: .month, value: 1, to: month)!
            }
            for transaction in transactions where transaction.date >= start {
                let key = transaction.date.startOfMonth
                let amount = converted(transaction.amount, from: transaction.account?.currencyCode ?? currency)
                var entry = buckets[key] ?? (0, 0)
                if transaction.type == .income { entry.0 += amount }
                if transaction.type == .expense { entry.1 += amount }
                buckets[key] = entry
            }
            return buckets.keys.sorted().map { TrendPoint(date: $0, income: buckets[$0]!.0, expense: buckets[$0]!.1) }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                CustomSegmentedControl(
                    options: Period.allCases.map { ($0, $0.rawValue) },
                    selection: $period
                )

                monthNavigator

                CustomSegmentedControl(
                    options: [(TransactionType.expense, "Expenses"), (TransactionType.income, "Income")],
                    selection: $breakdownType
                )
                .frame(maxWidth: 220)

                if categoryTotals.isEmpty {
                    EmptyStateView(
                        icon: "chart.pie",
                        title: breakdownType == .expense ? "No expenses this month" : "No income this month",
                        subtitle: "Once you add transactions, your breakdown will appear here."
                    )
                } else {
                    donutChart
                    legend
                }

                trendChart

                calendarHeatmap
            }
            .padding(.horizontal, FinoraMetric.screenPadding)
            .padding(.bottom, 24)
        }
        .tabBarSafeArea()
    }

    private var monthNavigator: some View {
        HStack {
            Button { shiftMonth(-1) } label: { Image(systemName: "chevron.left") }
            Spacer()
            Text(selectedMonth.formatted(.dateTime.month(.wide).year()))
                .font(FinoraFont.bodyMedium)
            Spacer()
            Button { shiftMonth(1) } label: { Image(systemName: "chevron.right") }
        }
        .foregroundStyle(FinoraColor.textPrimary)
    }

    private var donutChart: some View {
        Chart(categoryTotals) { item in
            SectorMark(
                angle: .value("Amount", (item.amount as NSDecimalNumber).doubleValue),
                innerRadius: .ratio(0.62),
                angularInset: 1.5
            )
            .foregroundStyle(Color(hex: item.category.colorHex))
            .cornerRadius(3)
        }
        .frame(height: 220)
        .chartBackground { _ in
            VStack(spacing: 4) {
                Text(breakdownType == .expense ? "Expenses" : "Income").font(FinoraFont.caption).foregroundStyle(FinoraColor.textSecondary)
                Text(breakdownTotal.formatted(.currency(code: currency)))
                    .font(FinoraFont.amount(18, weight: .bold))
                    .foregroundStyle(FinoraColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal, 24)
            }
        }
    }

    private var legend: some View {
        VStack(spacing: 8) {
            ForEach(categoryTotals) { item in
                HStack {
                    Circle().fill(Color(hex: item.category.colorHex)).frame(width: 8, height: 8)
                    Text(item.category.name).font(FinoraFont.body).foregroundStyle(FinoraColor.textPrimary)
                    Spacer()
                    Text(percentString(item.amount))
                        .font(FinoraFont.caption)
                        .foregroundStyle(FinoraColor.textSecondary)
                }
            }
        }
    }

    private var trendChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Income vs. expenses").font(FinoraFont.bodyMedium).foregroundStyle(FinoraColor.textPrimary)
            Chart {
                ForEach(trendData) { point in
                    LineMark(x: .value("Date", point.date), y: .value("Amount", (point.income as NSDecimalNumber).doubleValue))
                        .foregroundStyle(by: .value("Series", "Income"))
                        .interpolationMethod(.monotone)
                    LineMark(x: .value("Date", point.date), y: .value("Amount", (point.expense as NSDecimalNumber).doubleValue))
                        .foregroundStyle(by: .value("Series", "Expenses"))
                        .interpolationMethod(.monotone)
                }
            }
            .chartForegroundStyleScale(["Income": FinoraColor.verdant, "Expenses": FinoraColor.coral])
            .frame(height: 160)
        }
    }

    private var calendarHeatmap: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spending calendar").font(FinoraFont.bodyMedium).foregroundStyle(FinoraColor.textPrimary)
            let days = daysInMonth(selectedMonth)
            let maxSpend = days.map(spent(on:)).max() ?? 1

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                ForEach(Array(leadingOffset(for: selectedMonth)), id: \.self) { _ in
                    Color.clear.frame(height: 28)
                }
                ForEach(days, id: \.self) { day in
                    let amount = spent(on: day)
                    let intensity = maxSpend > 0 ? min(max((amount / maxSpend as NSDecimalNumber).doubleValue, 0), 1) : 0
                    Text("\(Calendar.current.component(.day, from: day))")
                        .font(FinoraFont.micro)
                        .frame(height: 28)
                        .frame(maxWidth: .infinity)
                        .background(FinoraColor.verdant.opacity(0.15 + intensity * 0.7))
                        .foregroundStyle(FinoraColor.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
    }

    private func shiftMonth(_ delta: Int) {
        if let newMonth = Calendar.current.date(byAdding: .month, value: delta, to: selectedMonth) {
            selectedMonth = newMonth
        }
    }

    private func monthRange(for month: Date) -> (start: Date, end: Date) {
        let start = month.startOfMonth
        let end = Calendar.current.date(byAdding: .month, value: 1, to: start) ?? start
        return (start, end)
    }

    private func daysInMonth(_ month: Date) -> [Date] {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: month) else { return [] }
        let start = month.startOfMonth
        return range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: start) }
    }

    private func leadingOffset(for month: Date) -> Range<Int> {
        let weekday = Calendar.current.component(.weekday, from: month.startOfMonth) 
        let mondayIndexed = (weekday + 5) % 7
        return 0..<mondayIndexed
    }

    private func spent(on day: Date) -> Decimal {
        transactions
            .filter { $0.type == .expense && Calendar.current.isDate($0.date, inSameDayAs: day) }
            .reduce(Decimal(0)) { $0 + converted($1.amount, from: $1.account?.currencyCode ?? currency) }
    }

    private func percentString(_ value: Decimal) -> String {
        guard breakdownTotal > 0 else { return "0%" }
        let ratio = (value / breakdownTotal as NSDecimalNumber).doubleValue
        return ratio.formatted(.percent.precision(.fractionLength(1)))
    }
}

#Preview {
    ReportsView()
        .modelContainer(for: [Transaction.self, TransactionCategory.self, Account.self, UserProfile.self], inMemory: true)
        .environmentObject(CurrencyExchangeService())
}
