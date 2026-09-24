
import Foundation
import SwiftData


enum AccountType: String, Codable, CaseIterable, Identifiable {
    case cash, card, savings, other
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cash: "Cash"
        case .card: "Card"
        case .savings: "Savings"
        case .other: "Other"
        }
    }

    var iconName: String {
        switch self {
        case .cash: "banknote.fill"
        case .card: "creditcard.fill"
        case .savings: "building.columns.fill"
        case .other: "square.grid.2x2.fill"
        }
    }
}

enum TransactionType: String, Codable, CaseIterable, Identifiable {
    case expense, income, transfer
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .expense: "Expense"
        case .income: "Income"
        case .transfer: "Transfer"
        }
    }

    var sign: String {
        switch self {
        case .expense: "−"
        case .income: "+"
        case .transfer: ""
        }
    }
}

enum CategoryKind: String, Codable, CaseIterable, Identifiable, Hashable {
    case expense, income
    var id: String { rawValue }
}

enum AssetType: String, Codable, CaseIterable, Identifiable {
    case stock, crypto, collectible
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .stock: "Stocks"
        case .crypto: "Crypto"
        case .collectible: "Other"
        }
    }

    var iconName: String {
        switch self {
        case .stock: "chart.bar.fill"
        case .crypto: "bitcoinsign.circle.fill"
        case .collectible: "shippingbox.fill"
        }
    }


    var supportsAutoUpdate: Bool {
        self == .stock || self == .crypto
    }
}


enum GoalIcon: String, CaseIterable, Identifiable {
    case car = "car.fill"
    case vacation = "beach.umbrella.fill"
    case laptop = "laptopcomputer"
    case home = "house.fill"
    case education = "graduationcap.fill"
    case gift = "gift.fill"
    case ring = "heart.fill"
    case emergency = "cross.case.fill"
    case travel = "airplane"
    case other = "star.fill"

    var id: String { rawValue }
}


enum OverviewVisibility: String, Codable, CaseIterable, Identifiable {
    case automatic, alwaysShow, alwaysHide
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .automatic: "Automatic (hide when empty)"
        case .alwaysShow: "Always show"
        case .alwaysHide: "Always hide"
        }
    }
}


@Model
final class Account {
    var id: UUID = UUID()
    var name: String = ""
    var typeRaw: String = "cash"
    var currencyCode: String = "USD"
    var balance: Decimal = 0
    var colorHex: String = "34B27F"
    var createdAt: Date = Date.now
    var isArchived: Bool = false
    var overviewVisibilityRaw: String = "automatic"


    @Relationship(inverse: \Transaction.account) var transactions: [Transaction]?
    @Relationship(inverse: \Transaction.toAccount) var incomingTransfers: [Transaction]?

    var type: AccountType {
        get { AccountType(rawValue: typeRaw) ?? .other }
        set { typeRaw = newValue.rawValue }
    }

    var overviewVisibility: OverviewVisibility {
        get { OverviewVisibility(rawValue: overviewVisibilityRaw) ?? .automatic }
        set { overviewVisibilityRaw = newValue.rawValue }
    }

    var showsOnOverview: Bool {
        switch overviewVisibility {
        case .automatic: balance > 0
        case .alwaysShow: true
        case .alwaysHide: false
        }
    }

    init(
        name: String,
        type: AccountType,
        currencyCode: String = "USD",
        balance: Decimal = 0,
        colorHex: String = "34B27F",
        isArchived: Bool = false,
        overviewVisibility: OverviewVisibility = .automatic
    ) {
        self.id = UUID()
        self.name = name
        self.typeRaw = type.rawValue
        self.currencyCode = currencyCode
        self.balance = balance
        self.colorHex = colorHex
        self.createdAt = .now
        self.isArchived = isArchived
        self.overviewVisibilityRaw = overviewVisibility.rawValue
    }
}


@Model
final class TransactionCategory {
    var id: UUID = UUID()
    var name: String = ""
    var iconName: String = "questionmark.circle"
    var colorHex: String = "8FA398"
    var kindRaw: String = "expense"
    var isCustom: Bool = true
    var sortOrder: Int = 0

 
    @Relationship(inverse: \Transaction.category) var transactions: [Transaction]?
    @Relationship(inverse: \Budget.category) var budgets: [Budget]?

    var kind: CategoryKind {
        get { CategoryKind(rawValue: kindRaw) ?? .expense }
        set { kindRaw = newValue.rawValue }
    }

    init(
        name: String,
        iconName: String,
        colorHex: String,
        kind: CategoryKind,
        isCustom: Bool = true,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.kindRaw = kind.rawValue
        self.isCustom = isCustom
        self.sortOrder = sortOrder
    }
}


@Model
final class Transaction {
    var id: UUID = UUID()
    var amount: Decimal = 0
    var typeRaw: String = "expense"
    var date: Date = Date.now
    var note: String?
    var receiptImageData: Data?
    @Relationship var account: Account?
    @Relationship var toAccount: Account?
 
    var toAmount: Decimal?
    @Relationship var category: TransactionCategory?
    var recurringRuleId: UUID?

    var type: TransactionType {
        get { TransactionType(rawValue: typeRaw) ?? .expense }
        set { typeRaw = newValue.rawValue }
    }

  
    var effectiveToAmount: Decimal { toAmount ?? amount }

    init(
        amount: Decimal,
        type: TransactionType,
        date: Date = .now,
        note: String? = nil,
        account: Account?,
        toAccount: Account? = nil,
        toAmount: Decimal? = nil,
        category: TransactionCategory? = nil
    ) {
        self.id = UUID()
        self.amount = amount
        self.typeRaw = type.rawValue
        self.date = date
        self.note = note
        self.account = account
        self.toAccount = toAccount
        self.toAmount = toAmount
        self.category = category
    }
}


@Model
final class Budget {
    var id: UUID = UUID()
    @Relationship var category: TransactionCategory?
    var limitAmount: Decimal = 0
    var month: Date = Date.now

    init(category: TransactionCategory?, limitAmount: Decimal, month: Date = .now.startOfMonth) {
        self.id = UUID()
        self.category = category
        self.limitAmount = limitAmount
        self.month = month
    }
}



@Model
final class Asset {
    var id: UUID = UUID()
    var typeRaw: String = "stock"
    var name: String = ""
    var ticker: String?
    var currencyCode: String = "USD"
    var note: String?
    var createdAt: Date = Date.now
    var autoUpdateEnabled: Bool = false
    var lastFetchedPrice: Decimal?
    var lastFetchedAt: Date?


    @Relationship(inverse: \AssetTransaction.asset) var transactions: [AssetTransaction]?

    var type: AssetType {
        get { AssetType(rawValue: typeRaw) ?? .collectible }
        set { typeRaw = newValue.rawValue }
    }

 
    func quantity(in ledger: [AssetTransaction]) -> Decimal {
        ledger.sorted { $0.date < $1.date }
            .reduce(Decimal(0)) { $1.kind == .buy ? $0 + $1.quantity : $0 - $1.quantity }
    }


    func averageCostPerUnit(in ledger: [AssetTransaction]) -> Decimal {
        var runningQuantity: Decimal = 0
        var runningCost: Decimal = 0
        for entry in ledger.sorted(by: { $0.date < $1.date }) {
            switch entry.kind {
            case .buy:
                runningCost += entry.quantity * entry.pricePerUnit
                runningQuantity += entry.quantity
            case .sell:
                guard runningQuantity > 0 else { continue }
                let avg = runningCost / runningQuantity
                let soldQty = min(entry.quantity, runningQuantity)
                runningCost -= avg * soldQty
                runningQuantity -= soldQty
            }
        }
        guard runningQuantity > 0 else { return 0 }
        return runningCost / runningQuantity
    }

    func realizedGainLoss(in ledger: [AssetTransaction]) -> Decimal {
        var runningQuantity: Decimal = 0
        var runningCost: Decimal = 0
        var realized: Decimal = 0
        for entry in ledger.sorted(by: { $0.date < $1.date }) {
            switch entry.kind {
            case .buy:
                runningCost += entry.quantity * entry.pricePerUnit
                runningQuantity += entry.quantity
            case .sell:
                guard runningQuantity > 0 else { continue }
                let avg = runningCost / runningQuantity
                let soldQty = min(entry.quantity, runningQuantity)
                realized += (entry.pricePerUnit - avg) * soldQty
                runningCost -= avg * soldQty
                runningQuantity -= soldQty
            }
        }
        return realized
    }

  
    func currentPricePerUnit(in ledger: [AssetTransaction]) -> Decimal {
        lastFetchedPrice ?? averageCostPerUnit(in: ledger)
    }

    func currentValue(in ledger: [AssetTransaction]) -> Decimal {
        currentPricePerUnit(in: ledger) * quantity(in: ledger)
    }

    func unrealizedGainLoss(in ledger: [AssetTransaction]) -> Decimal {
        (currentPricePerUnit(in: ledger) - averageCostPerUnit(in: ledger)) * quantity(in: ledger)
    }

    init(
        type: AssetType,
        name: String,
        ticker: String? = nil,
        currencyCode: String = "USD",
        autoUpdateEnabled: Bool = false,
        note: String? = nil
    ) {
        self.id = UUID()
        self.typeRaw = type.rawValue
        self.name = name
        self.ticker = ticker
        self.currencyCode = currencyCode
        self.autoUpdateEnabled = autoUpdateEnabled
        self.note = note
        self.createdAt = .now
    }
}


@Model
final class AssetTransaction {
    var id: UUID = UUID()
    @Relationship var asset: Asset?
    var kindRaw: String = "buy"
    var quantity: Decimal = 0
    var pricePerUnit: Decimal = 0
    var date: Date = Date.now
    var note: String?

    enum Kind: String, Codable, CaseIterable, Identifiable {
        case buy = "Buy", sell = "Sell"
        var id: String { rawValue }
    }

    var kind: Kind {
        get { Kind(rawValue: kindRaw) ?? .buy }
        set { kindRaw = newValue.rawValue }
    }

    var total: Decimal { quantity * pricePerUnit }

    init(asset: Asset?, kind: Kind, quantity: Decimal, pricePerUnit: Decimal, date: Date = .now, note: String? = nil) {
        self.id = UUID()
        self.asset = asset
        self.kindRaw = kind.rawValue
        self.quantity = quantity
        self.pricePerUnit = pricePerUnit
        self.date = date
        self.note = note
    }
}


@Model
final class Goal {
    var id: UUID = UUID()
    var name: String = ""
    var targetAmount: Decimal = 0
    var currencyCode: String = "USD"
    var iconName: String?
    var customImageData: Data?
    var startDate: Date = Date.now
    var targetDate: Date?
    var monthlyContribution: Decimal?
    var sortOrder: Int = 0
    var linkedAccountIDs: [UUID] = []


    func currentAmount(in accounts: [Account], convert: (Decimal, String, String) -> Decimal) -> Decimal {
        let relevant = linkedAccountIDs.isEmpty ? accounts : accounts.filter { linkedAccountIDs.contains($0.id) }
        return relevant.reduce(Decimal(0)) { partial, account in
            partial + convert(account.balance, account.currencyCode, currencyCode)
        }
    }

    func progress(in accounts: [Account], convert: (Decimal, String, String) -> Decimal) -> Double {
        guard targetAmount > 0 else { return 0 }
        let value = (currentAmount(in: accounts, convert: convert) / targetAmount) as NSDecimalNumber
        return min(max(value.doubleValue, 0), 1)
    }

    init(
        name: String,
        targetAmount: Decimal,
        currencyCode: String = "USD",
        iconName: String? = GoalIcon.other.rawValue,
        customImageData: Data? = nil,
        startDate: Date = .now,
        targetDate: Date? = nil,
        monthlyContribution: Decimal? = nil,
        sortOrder: Int = 0,
        linkedAccountIDs: [UUID] = []
    ) {
        self.id = UUID()
        self.name = name
        self.targetAmount = targetAmount
        self.currencyCode = currencyCode
        self.iconName = iconName
        self.customImageData = customImageData
        self.startDate = startDate
        self.targetDate = targetDate
        self.monthlyContribution = monthlyContribution
        self.sortOrder = sortOrder
        self.linkedAccountIDs = linkedAccountIDs
    }
}


@Model
final class UserProfile {
    var id: UUID = UUID()
    var name: String = "You"
    var email: String?
    var avatarImageData: Data?
    var defaultCurrencyCode: String = "USD"
    var biometricLockEnabled: Bool = false
    var notificationsEnabled: Bool = false
    var showCapitalOnOverview: Bool = true

    init(
        name: String = "You",
        email: String? = nil,
        defaultCurrencyCode: String = "USD",
        biometricLockEnabled: Bool = false,
        notificationsEnabled: Bool = false,
        showCapitalOnOverview: Bool = true
    ) {
        self.id = UUID()
        self.name = name
        self.email = email
        self.defaultCurrencyCode = defaultCurrencyCode
        self.biometricLockEnabled = biometricLockEnabled
        self.notificationsEnabled = notificationsEnabled
        self.showCapitalOnOverview = showCapitalOnOverview
    }
}



struct CategoryAmount: Identifiable {
    let category: TransactionCategory
    let amount: Decimal
    var id: UUID { category.id }
}

extension TransactionCategory {
    static func expenseBreakdown(
        of transactions: [Transaction],
        convert: (Decimal, String, String) -> Decimal,
        displayCurrency: String
    ) -> [CategoryAmount] {
        breakdown(of: transactions, type: .expense, convert: convert, displayCurrency: displayCurrency)
    }


    static func breakdown(
        of transactions: [Transaction],
        type: TransactionType,
        convert: (Decimal, String, String) -> Decimal,
        displayCurrency: String
    ) -> [CategoryAmount] {
        var totals: [UUID: Decimal] = [:]
        var byID: [UUID: TransactionCategory] = [:]
        for transaction in transactions where transaction.type == type {
            guard let category = transaction.category else { continue }
            let amount = convert(transaction.amount, transaction.account?.currencyCode ?? displayCurrency, displayCurrency)
            totals[category.id, default: 0] += amount
            byID[category.id] = category
        }
        return totals.compactMap { id, total in byID[id].map { CategoryAmount(category: $0, amount: total) } }
            .sorted { $0.amount > $1.amount }
    }
}


extension Date {
    var startOfMonth: Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: self)) ?? self
    }

    var startOfYear: Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year], from: self)) ?? self
    }

    var daysRemainingInMonth: Int {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: self) else { return 1 }
        let today = calendar.component(.day, from: self)
        return max(range.count - today + 1, 1)
    }

    var totalDaysInMonth: Int {
        Calendar.current.range(of: .day, in: .month, for: self)?.count ?? 30
    }
}
