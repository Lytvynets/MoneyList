
import SwiftUI
import SwiftData

@main
struct FinoraApp: App {
    @StateObject private var purchaseManager = PurchaseManager()
    @StateObject private var biometricService = BiometricAuthService()
    @StateObject private var exchangeService = CurrencyExchangeService()
    @StateObject private var interstitialAdManager = InterstitialAdManager()

    init() {
        AdsService.start()
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Account.self,
            TransactionCategory.self,
            Transaction.self,
            Budget.self,
            Asset.self,
            AssetTransaction.self,
            Goal.self,
            UserProfile.self
        ])

   
        let configuration = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Money List: could not create ModelContainer — \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(purchaseManager)
                .environmentObject(biometricService)
                .environmentObject(exchangeService)
                .environmentObject(interstitialAdManager)
                .preferredColorScheme(.dark) 
        }
        .modelContainer(sharedModelContainer)
    }
}
