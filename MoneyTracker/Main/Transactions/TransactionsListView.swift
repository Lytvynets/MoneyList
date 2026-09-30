
import SwiftUI
import SwiftData

struct TransactionsListView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]
    @Query(sort: \Account.createdAt) private var accounts: [Account]

    @State private var searchText = ""
    @State private var filter: Filter = .all
    @State private var accountFilter: Account?
    @State private var editingTransaction: Transaction?
    @State private var showAddTransaction = false

    private enum Filter: String, CaseIterable { case all = "All", expense = "Expenses", income = "Income" }

    private var filtered: [Transaction] {
        allTransactions.filter { transaction in
            if let accountFilter, transaction.account?.id != accountFilter.id { return false }
            switch filter {
            case .all: break
            case .expense: if transaction.type != .expense { return false }
            case .income: if transaction.type != .income { return false }
            }
            guard !searchText.isEmpty else { return true }
            let haystack = (transaction.note ?? "") + (transaction.category?.name ?? "")
            return haystack.localizedCaseInsensitiveContains(searchText)
        }
    }

    struct DayGroup: Identifiable {
        let day: Date
        let items: [Transaction]
        var id: Date { day }
    }

    private var groupedByDay: [DayGroup] {
        let grouped = Dictionary(grouping: filtered) { Calendar.current.startOfDay(for: $0.date) }
        return grouped.keys.sorted(by: >).map { key in
            DayGroup(day: key, items: grouped[key]!.sorted { $0.date > $1.date })
        }
    }

    var body: some View {
        NavigationStack {
            
            
            
            VStack(spacing: 0) {
                filterChips

                ZStack {
                    FinoraColor.background.ignoresSafeArea()

                    if filtered.isEmpty {
                        ScrollView {
                            EmptyStateView(
                                icon: "tray",
                                title: "No transactions found",
                                subtitle: "Try a different filter, or add your first entry.",
                                buttonTitle: "Add transaction"
                            ) { showAddTransaction = true }
                                .padding(.horizontal, FinoraMetric.screenPadding)
                                .padding(.top, 55)
                        }
                        .scrollIndicators(.hidden)
                   
                    } else {
                        List {
                            ForEach(groupedByDay) { group in
                                Section {
                                    ForEach(group.items) { transaction in
                                        TransactionRowView(transaction: transaction)
                                            .listRowBackground(FinoraColor.background)
                                            .listRowSeparatorTint(FinoraColor.divider)
                                            .swipeActions(edge: .leading) {
                                                Button { editingTransaction = transaction } label: {
                                                    Label("Edit", systemImage: "pencil")
                                                }
                                                .tint(FinoraColor.verdant)
                                            }
                                            .swipeActions(edge: .trailing) {
                                                Button(role: .destructive) { delete(transaction) } label: {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            }
                                    }
                                } header: {
                                    dayHeader(for: group)
                                }
                            }
                        }
                        .scrollIndicators(.hidden)
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
                .tabBarSafeArea()
            }
            .background(FinoraColor.background)
            .navigationTitle("Transactions")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("All accounts") { accountFilter = nil }
                        ForEach(accounts) { account in
                            Button(account.name) { accountFilter = account }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(item: $editingTransaction) { transaction in
                AddTransactionView(editingTransaction: transaction)
            }
            .sheet(isPresented: $showAddTransaction) { AddTransactionView() }
            
            
            
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Filter.allCases, id: \.self) { candidate in
                    FilterChip(title: candidate.rawValue, isSelected: filter == candidate) {
                        filter = candidate
                    }
                }
                if let accountFilter {
                    FilterChip(title: accountFilter.name, systemImage: "xmark", isSelected: true, tint: FinoraColor.slate) {
                        self.accountFilter = nil
                    }
                }
            }
            .padding(.horizontal, FinoraMetric.screenPadding)
            .padding(.vertical, 8)
        }
        .background(FinoraColor.background)
    }

    private func dayHeader(for group: DayGroup) -> some View {
        let income = group.items.filter { $0.type == .income }.reduce(Decimal(0)) { $0 + $1.amount }
        let expense = group.items.filter { $0.type == .expense }.reduce(Decimal(0)) { $0 + $1.amount }
        return HStack {
            Text(sectionTitle(for: group.day))
            Spacer()
            if income > 0 {
                Text("+\(income.formatted(.currency(code: "USD")))").foregroundStyle(FinoraColor.verdant)
            }
            if expense > 0 {
                Text("-\(expense.formatted(.currency(code: "USD")))").foregroundStyle(FinoraColor.coral)
            }
        }
        .font(FinoraFont.caption)
        .foregroundStyle(FinoraColor.textPrimary)
    }

    private func sectionTitle(for day: Date) -> String {
        if Calendar.current.isDateInToday(day) { return "Today" }
        if Calendar.current.isDateInYesterday(day) { return "Yesterday" }
        return day.formatted(.dateTime.month(.wide).day())
    }

    private func delete(_ transaction: Transaction) {
        TransactionBalanceEffect.revert(transaction)
        modelContext.delete(transaction)
        try? modelContext.save()
    }
}

#Preview {
    TransactionsListView()
        .modelContainer(for: [Account.self, Transaction.self, TransactionCategory.self], inMemory: true)
}
