
import Foundation
import StoreKit
internal import Combine

@MainActor
final class PurchaseManager: ObservableObject {

    @Published var product: Product?
    @Published var isLoading = false
    @Published var presentErrorAlert = false
    @Published private(set) var isPro: Bool = UserDefaults.standard.bool(forKey: AppDefaults.Keys.isPro)

    private var transactionListener: Task<Void, Never>?

    init() {
        transactionListener = listenForTransactionUpdates()
    }

    deinit {
        transactionListener?.cancel()
    }


    func canAddAccount(currentCount: Int) -> Bool { isPro || currentCount < FreeLimit.accounts }
    func canAddCustomCategory() -> Bool { isPro }
    func canAddGoal(currentCount: Int) -> Bool { isPro || currentCount < FreeLimit.goals }
    func canAddBudget(currentCount: Int) -> Bool { isPro || currentCount < FreeLimit.budgets }
    func canAddAsset(currentCount: Int) -> Bool { isPro || currentCount < FreeLimit.assets }
    var canExport: Bool { isPro }
    var shouldShowAds: Bool { !isPro }

    func fetchProduct() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let products = try await Product.products(for: [AppDefaults.proLifetime])
            self.product = products.first
            if let product {
                AppDefaults.proPrice = product.displayPrice
            }
        } catch {
            print("Money List: failed to load product — \(error)")
            presentErrorAlert = true
        }
        await refreshEntitlement()
    }

    func purchase() async {
        guard let product else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    print("Money List: purchase verified — \(transaction.productID)")
                    setPro(true)
                    await transaction.finish()
                case .unverified(_, let error):
                    print("Money List: unverified purchase — \(error)")
                    presentErrorAlert = true
                }
            case .userCancelled:
                print("Money List: user cancelled purchase")
            case .pending:
                print("Money List: purchase pending (e.g. Ask to Buy)")
            @unknown default:
                break
            }
        } catch {
            print("Money List: purchase error — \(error)")
            presentErrorAlert = true
        }
    }

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await AppStore.sync()
            await refreshEntitlement()
        } catch {
            print("Money List: restore failed — \(error)")
            presentErrorAlert = true
        }
    }

    func refreshEntitlement() async {
        for await result in StoreKit.Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.productID == AppDefaults.proLifetime, transaction.revocationDate == nil {
                setPro(true)
                return
            }
        }
        setPro(false)
    }

    private func setPro(_ value: Bool) {
        isPro = value
        UserDefaults.standard.set(value, forKey: AppDefaults.Keys.isPro)
    }

    private func listenForTransactionUpdates() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in StoreKit.Transaction.updates {
                guard case .verified(let transaction) = result else { continue }
                if transaction.productID == AppDefaults.proLifetime {
                    await self?.setPro(transaction.revocationDate == nil)
                }
                await transaction.finish()
            }
        }
    }
}


enum FreeLimit {
    static let accounts = 2
    static let goals = 1
    static let budgets = 1
    static let assets = 1
}
