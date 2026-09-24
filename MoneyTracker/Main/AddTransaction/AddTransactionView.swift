

import SwiftUI
import SwiftData

struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var exchangeService: CurrencyExchangeService
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @EnvironmentObject private var interstitialAdManager: InterstitialAdManager

    @Query(sort: \Account.createdAt) private var accounts: [Account]
    @Query(sort: \TransactionCategory.sortOrder) private var categories: [TransactionCategory]
    @Query private var profiles: [UserProfile]
    @Query private var budgets: [Budget]

    var editingTransaction: Transaction?

    @State private var type: TransactionType = .expense
    @State private var amountText: String = ""
    @State private var selectedAccount: Account?
    @State private var selectedToAccount: Account?
    @State private var selectedCategory: TransactionCategory?
    @State private var note: String = ""
    @State private var date: Date = .now
    @State private var showMoreDetails = false
    @State private var showAddAccount = false
    @State private var showAddCategory = false
    @FocusState private var amountFieldFocused: Bool

    @State private var inputCurrency: String = "USD"
    @State private var showCurrencyPicker = false

    @State private var receivedAmountText: String = ""
    @State private var receivedAmountManuallyEdited = false
    @FocusState private var receivedAmountFocused: Bool

    private var amount: Decimal {
        Decimal(string: amountText) ?? 0
    }

    private var receivedAmount: Decimal {
        Decimal(string: receivedAmountText) ?? 0
    }

    private var isCrossCurrencyTransfer: Bool {
        guard type == .transfer, let from = selectedAccount, let to = selectedToAccount else { return false }
        return from.currencyCode != to.currencyCode
    }

    private var currentCategories: [TransactionCategory] {
        categories.filter { $0.kind == (type == .income ? .income : .expense) }
    }

    private var canSave: Bool {
        guard amount > 0, selectedAccount != nil else { return false }
        if type == .transfer {
            guard selectedToAccount != nil, selectedToAccount?.id != selectedAccount?.id else { return false }
            if isCrossCurrencyTransfer { return receivedAmount > 0 }
        }
        return true
    }

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(FinoraColor.textTertiary)
                .frame(width: 36, height: 4)
                .padding(.top, 10)

            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(FinoraColor.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(FinoraColor.surface)
                        .clipShape(Circle())
                }
                Spacer()
                VStack(spacing: 2) {
                    Text("Add Transaction").font(FinoraFont.screenTitle).foregroundStyle(FinoraColor.textPrimary)
                    Text("Record your transaction").font(FinoraFont.caption).foregroundStyle(FinoraColor.textSecondary)
                }
                Spacer()
                Color.clear.frame(width: 36, height: 36)
            }
            .padding(.horizontal, FinoraMetric.screenPadding)
            .padding(.top, 12)

            ScrollView {
                VStack(spacing: 20) {
                    typePicker
                    amountSection

                    accountSection(title: "From account", selection: $selectedAccount)

                    if type == .transfer {
                        accountSection(title: "To account", selection: $selectedToAccount)
                        if isCrossCurrencyTransfer {
                            receivedAmountSection
                        }
                    } else {
                        categorySection
                    }

                    DisclosureGroup("More details", isExpanded: $showMoreDetails) {
                        VStack(spacing: 12) {
                            TextField("Add a note", text: $note)
                                .font(FinoraFont.body)
                                .padding(.horizontal, 14)
                                .frame(height: FinoraMetric.inputHeight)
                                .background(FinoraColor.surface)
                                .clipShape(RoundedRectangle(cornerRadius: FinoraMetric.chipRadius))

                            DatePicker("Date", selection: $date, displayedComponents: [.date])
                                .font(FinoraFont.body)
                                .tint(FinoraColor.verdant)
                        }
                        .padding(.top, 10)
                    }
                    .tint(FinoraColor.textPrimary)
                    .font(FinoraFont.bodyMedium)
                    .padding(14)
                    .background(FinoraColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: FinoraMetric.chipRadius))

                    PrimaryButton(title: "Save Transaction") { save() }
                        .disabled(!canSave)
                        .opacity(canSave ? 1 : 0.5)
                }
                .padding(.horizontal, FinoraMetric.screenPadding)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
        .background(FinoraColor.background.ignoresSafeArea())
        .onAppear {
            prefillIfEditing()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { amountFieldFocused = true }
        }
        .onChange(of: selectedAccount) { _, newAccount in
            if type != .transfer { inputCurrency = newAccount?.currencyCode ?? "USD" }
            syncReceivedAmountIfNeeded()
        }
        .onChange(of: selectedToAccount) { _, _ in syncReceivedAmountIfNeeded() }
        .onChange(of: type) { _, newType in
            if newType != .transfer {
                inputCurrency = selectedAccount?.currencyCode ?? "USD"
            } else {
                syncReceivedAmountIfNeeded()
            }
        }
        .sheet(isPresented: $showAddAccount) { AddAccountView() }
        .sheet(isPresented: $showAddCategory) {
            AddCategoryView(defaultKind: type == .income ? .income : .expense)
        }
        .sheet(isPresented: $showCurrencyPicker) {
            CurrencyPickerSheet(selection: $inputCurrency)
                .presentationDetents([.medium])
                .presentationDragIndicator(.hidden)
        }
    }


    private var amountSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(currencySymbol(for: displayCurrencyCode))
                    .font(FinoraFont.amount(30))
                    .foregroundStyle(FinoraColor.textSecondary)
                TextField("0.00", text: $amountText)
                    .keyboardType(.decimalPad)
                    .focused($amountFieldFocused)
                    .font(FinoraFont.amount(40, weight: .bold))
                    .foregroundStyle(FinoraColor.textPrimary)
                    .fixedSize()
                    .onChange(of: amountText) { _, newValue in
                        let sanitized = NumericInput.sanitize(newValue)
                        if sanitized != newValue { amountText = sanitized }
                        syncReceivedAmountIfNeeded()
                    }
                Spacer()

                if type == .transfer {
                    Text(selectedAccount?.currencyCode ?? "USD")
                        .font(FinoraFont.bodyMedium)
                        .foregroundStyle(FinoraColor.textSecondary)
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(FinoraColor.surface)
                        .clipShape(Capsule())
                } else {
                    Button { showCurrencyPicker = true } label: {
                        HStack(spacing: 4) {
                            Text(inputCurrency)
                            Image(systemName: "chevron.down").font(.system(size: 9, weight: .semibold))
                        }
                        .font(FinoraFont.bodyMedium)
                        .foregroundStyle(FinoraColor.textSecondary)
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(FinoraColor.surface)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }

            if type != .transfer, let selectedAccount, inputCurrency != selectedAccount.currencyCode, amount > 0 {
                let converted = exchangeService.convert(amount, from: inputCurrency, to: selectedAccount.currencyCode)
                Text("≈ \(converted.formatted(.currency(code: selectedAccount.currencyCode))) will be recorded on \(selectedAccount.name)")
                    .font(FinoraFont.micro)
                    .foregroundStyle(FinoraColor.textSecondary)
            }
        }
        .padding(.top, 10)
    }

    private var displayCurrencyCode: String {
        type == .transfer ? (selectedAccount?.currencyCode ?? "USD") : inputCurrency
    }

    private func currencySymbol(for code: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        return formatter.currencySymbol ?? code
    }


    private var receivedAmountSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("They receive").font(FinoraFont.bodyMedium).foregroundStyle(FinoraColor.textPrimary)
                Spacer()
                if receivedAmountManuallyEdited {
                    Button("Use exchange rate") {
                        receivedAmountManuallyEdited = false
                        syncReceivedAmountIfNeeded()
                    }
                    .font(FinoraFont.micro)
                    .foregroundStyle(FinoraColor.verdant)
                    .buttonStyle(.plain)
                } else {
                    Label("Live rate", systemImage: "wand.and.stars")
                        .font(FinoraFont.micro)
                        .foregroundStyle(FinoraColor.verdant)
                }
            }

            HStack {
                if let to = selectedToAccount {
                    Text(currencySymbol(for: to.currencyCode))
                        .font(FinoraFont.amount(20))
                        .foregroundStyle(FinoraColor.textSecondary)
                }
                TextField("0.00", text: $receivedAmountText)
                    .keyboardType(.decimalPad)
                    .focused($receivedAmountFocused)
                    .font(FinoraFont.amount(24, weight: .semibold))
                    .foregroundStyle(FinoraColor.textPrimary)
                    .onChange(of: receivedAmountText) { _, newValue in
                        let sanitized = NumericInput.sanitize(newValue)
                        if sanitized != newValue { receivedAmountText = sanitized }
                        if receivedAmountFocused { receivedAmountManuallyEdited = true }
                    }
                Spacer()
                if let to = selectedToAccount {
                    Text(to.currencyCode).font(FinoraFont.caption).foregroundStyle(FinoraColor.textSecondary)
                }
            }
            .padding(.horizontal, 14)
            .frame(height: FinoraMetric.inputHeight)
            .background(FinoraColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: FinoraMetric.chipRadius, style: .continuous))

            if let from = selectedAccount, let to = selectedToAccount {
                let rate = rounded(exchangeService.convert(1, from: from.currencyCode, to: to.currencyCode), places: 4)
                Text("Live rate: 1 \(from.currencyCode) ≈ \(rate.formatted()) \(to.currencyCode)")
                    .font(FinoraFont.micro)
                    .foregroundStyle(FinoraColor.textTertiary)
            }
        }
    }

    private func syncReceivedAmountIfNeeded() {
        guard isCrossCurrencyTransfer, !receivedAmountManuallyEdited,
              let from = selectedAccount, let to = selectedToAccount else { return }
        guard amount > 0 else {
            receivedAmountText = ""
            return
        }
        let converted = exchangeService.convert(amount, from: from.currencyCode, to: to.currencyCode)
        receivedAmountText = "\(rounded(converted, places: 2))"
    }
    

    private func rounded(_ value: Decimal, places: Int) -> Decimal {
        var result = Decimal()
        var mutableValue = value
        NSDecimalRound(&result, &mutableValue, places, .plain)
        return result
    }


    private var typePicker: some View {
        HStack(spacing: 0) {
            ForEach(TransactionType.allCases) { candidate in
                Button {
                    type = candidate
                    selectedCategory = nil
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: icon(for: candidate))
                        Text(candidate.displayName)
                    }
                    .font(FinoraFont.bodyMedium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(type == candidate ? color(for: candidate) : Color.clear)
                    .foregroundStyle(type == candidate ? Color.white : FinoraColor.textSecondary)
                }
            }
        }
        .background(FinoraColor.surface)
        .clipShape(Capsule())
    }

    private func icon(for type: TransactionType) -> String {
        switch type {
        case .expense: "arrow.down.circle.fill"
        case .income: "arrow.up.right"
        case .transfer: "arrow.left.arrow.right"
        }
    }

    private func color(for type: TransactionType) -> Color {
        FinoraColor.amountColor(for: type)
    }

    private func accountSection(title: String, selection: Binding<Account?>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title).font(FinoraFont.bodyMedium).foregroundStyle(FinoraColor.textPrimary)
                Spacer()
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(accounts.filter { !$0.isArchived }) { account in
                        Button { selection.wrappedValue = account } label: {
                            AccountCardView(account: account, isSelected: selection.wrappedValue?.id == account.id)
                        }
                        .buttonStyle(.plain)
                    }
                    AddAccountCard { showAddAccount = true }
                }
            }
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Category").font(FinoraFont.bodyMedium).foregroundStyle(FinoraColor.textPrimary)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 16) {
                ForEach(currentCategories) { category in
                    Button { selectedCategory = category } label: {
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: category.colorHex).opacity(selectedCategory?.id == category.id ? 0.35 : 0.18))
                                Image(systemName: category.iconName)
                                    .foregroundStyle(Color(hex: category.colorHex))
                            }
                            .frame(width: 56, height: 56)
                            .overlay(
                                Circle().stroke(selectedCategory?.id == category.id ? Color(hex: category.colorHex) : .clear, lineWidth: 2)
                            )
                            Text(category.name)
                                .font(FinoraFont.micro)
                                .foregroundStyle(FinoraColor.textSecondary)
                                .lineLimit(1)
                        }
                    }
                    .buttonStyle(.plain)
                }

                Button { showAddCategory = true } label: {
                    VStack(spacing: 6) {
                        ZStack {
                            Circle().fill(FinoraColor.surface)
                            Image(systemName: "plus").foregroundStyle(FinoraColor.textSecondary)
                        }
                        .frame(width: 56, height: 56)
                        .overlay(
                            Circle().strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                                .foregroundStyle(FinoraColor.inputBorder)
                        )
                        Text("Add").font(FinoraFont.micro).foregroundStyle(FinoraColor.textSecondary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func prefillIfEditing() {
        guard let editingTransaction else {
            if selectedAccount == nil { selectedAccount = accounts.first }
            inputCurrency = selectedAccount?.currencyCode ?? "USD"
            return
        }
        type = editingTransaction.type
        amountText = "\(editingTransaction.amount)"
        selectedAccount = editingTransaction.account
        selectedToAccount = editingTransaction.toAccount
        selectedCategory = editingTransaction.category
        note = editingTransaction.note ?? ""
        date = editingTransaction.date
        inputCurrency = editingTransaction.account?.currencyCode ?? "USD"
        if editingTransaction.type == .transfer, let toAmount = editingTransaction.toAmount {
            receivedAmountText = "\(toAmount)"
            receivedAmountManuallyEdited = true
        }
    }

    private func save() {
        guard let selectedAccount else { return }

        let recordedAmount: Decimal = {
            if type == .transfer || inputCurrency == selectedAccount.currencyCode { return amount }
            return exchangeService.convert(amount, from: inputCurrency, to: selectedAccount.currencyCode)
        }()

        let recordedToAmount: Decimal? = (type == .transfer && isCrossCurrencyTransfer) ? receivedAmount : nil

        if let editingTransaction {
            revertBalanceEffect(of: editingTransaction)
            editingTransaction.amount = recordedAmount
            editingTransaction.type = type
            editingTransaction.date = date
            editingTransaction.note = note.isEmpty ? nil : note
            editingTransaction.account = selectedAccount
            editingTransaction.toAccount = type == .transfer ? selectedToAccount : nil
            editingTransaction.toAmount = recordedToAmount
            editingTransaction.category = type == .transfer ? nil : selectedCategory
            applyBalanceEffect(of: editingTransaction)
        } else {
            let transaction = Transaction(
                amount: recordedAmount,
                type: type,
                date: date,
                note: note.isEmpty ? nil : note,
                account: selectedAccount,
                toAccount: type == .transfer ? selectedToAccount : nil,
                toAmount: recordedToAmount,
                category: type == .transfer ? nil : selectedCategory
            )
            modelContext.insert(transaction)
            applyBalanceEffect(of: transaction)
        }

        try? modelContext.save()
        WidgetDataBridge.refresh(context: modelContext, convert: exchangeService.convert)
        notifyIfBudgetThresholdCrossed(category: type == .transfer ? nil : selectedCategory, account: selectedAccount)
        dismiss()

        if purchaseManager.shouldShowAds {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                interstitialAdManager.showIfReady()
            }
        }
    }

   
    private func notifyIfBudgetThresholdCrossed(category: TransactionCategory?, account: Account?) {
        guard profiles.first?.notificationsEnabled == true,
              let category, let account,
              type == .expense else { return }

        let monthStart = Date().startOfMonth
        guard let budget = budgets.first(where: {
            $0.category?.id == category.id && Calendar.current.isDate($0.month, equalTo: monthStart, toGranularity: .month)
        }) else { return }

        let spentThisMonth = (try? modelContext.fetch(FetchDescriptor<Transaction>()))?
            .filter { $0.category?.id == category.id && $0.type == .expense && $0.date >= monthStart }
            .reduce(Decimal(0)) { $0 + exchangeService.convert($1.amount, from: $1.account?.currencyCode ?? account.currencyCode, to: account.currencyCode) }
            ?? 0

        let percent = Int(SafeToSpendCalculator.progress(spent: spentThisMonth, limit: budget.limitAmount) * 100)
        guard percent >= 80 else { return }

        let bucket = percent >= 100 ? 100 : 80
        let flagKey = "finora.notifiedBudget.\(budget.id.uuidString).\(Int(monthStart.timeIntervalSince1970)).\(bucket)"
        guard !UserDefaults.standard.bool(forKey: flagKey) else { return }
        UserDefaults.standard.set(true, forKey: flagKey)

        NotificationService.shared.scheduleBudgetAlert(categoryName: category.name, percentUsed: percent, budgetID: budget.id)
    }

    private func revertBalanceEffect(of transaction: Transaction) {
        switch transaction.type {
        case .expense: transaction.account?.balance += transaction.amount
        case .income: transaction.account?.balance -= transaction.amount
        case .transfer:
            transaction.account?.balance += transaction.amount
            transaction.toAccount?.balance -= transaction.effectiveToAmount
        }
    }

    private func applyBalanceEffect(of transaction: Transaction) {
        switch transaction.type {
        case .expense: transaction.account?.balance -= transaction.amount
        case .income: transaction.account?.balance += transaction.amount
        case .transfer:
            transaction.account?.balance -= transaction.amount
            transaction.toAccount?.balance += transaction.effectiveToAmount
        }
    }
}


enum TransactionBalanceEffect {
    static func revert(_ transaction: Transaction) {
        switch transaction.type {
        case .expense: transaction.account?.balance += transaction.amount
        case .income: transaction.account?.balance -= transaction.amount
        case .transfer:
            transaction.account?.balance += transaction.amount
            transaction.toAccount?.balance -= transaction.effectiveToAmount
        }
    }
}


private struct CurrencyPickerSheet: View {
    @Binding var selection: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            Text("Currency")
                .font(FinoraFont.screenTitle)
                .foregroundStyle(FinoraColor.textPrimary)
                .padding(.top, 20)
                .padding(.bottom, 8)

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(CurrencyCode.common, id: \.self) { code in
                        Button {
                            selection = code
                            dismiss()
                        } label: {
                            HStack {
                                Text(code).foregroundStyle(FinoraColor.textPrimary)
                                Spacer()
                                if code == selection {
                                    Image(systemName: "checkmark").foregroundStyle(FinoraColor.verdant)
                                }
                            }
                            .padding(.horizontal, FinoraMetric.screenPadding)
                            .padding(.vertical, 14)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if code != CurrencyCode.common.last {
                            Divider().overlay(FinoraColor.divider).padding(.leading, FinoraMetric.screenPadding)
                        }
                    }
                }
            }
        }
        .background(FinoraColor.background)
    }
}

#Preview {
    AddTransactionView()
        .modelContainer(for: [Account.self, Transaction.self, TransactionCategory.self, Budget.self, UserProfile.self], inMemory: true)
        .environmentObject(CurrencyExchangeService())
        .environmentObject(PurchaseManager())
        .environmentObject(InterstitialAdManager())
}
