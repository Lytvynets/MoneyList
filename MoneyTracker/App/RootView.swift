

import SwiftUI
import SwiftData

private enum AppFlowState {
    case splash, onboarding, paywall, main
}

struct RootView: View {
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @EnvironmentObject private var biometricService: BiometricAuthService
    @EnvironmentObject private var exchangeService: CurrencyExchangeService
    @EnvironmentObject private var interstitialAdManager: InterstitialAdManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage(AppDefaults.Keys.hasCompletedOnboarding) private var hasCompletedOnboarding = false
    @AppStorage(AppDefaults.Keys.biometricLockEnabled) private var biometricLockEnabled = false

    @State private var flow: AppFlowState = .splash
    @State private var paywallDismissedThisSession = false

    var body: some View {
        ZStack {
            switch flow {
            case .splash:
                SplashView(onFinished: advanceFromSplash)
            case .onboarding:
                OnboardingView(onComplete: completeOnboarding)
            case .paywall:
                PaywallView(onDismiss: dismissPaywall)
            case .main:
                MainTabView()
            }

            if flow == .main, biometricLockEnabled, !biometricService.isUnlocked {
                LockOverlay()
                    .environmentObject(biometricService)
            }
        }
        .task {
            SeedData.populateIfNeeded(context: modelContext)
            await purchaseManager.refreshEntitlement()
            await exchangeService.refreshIfNeeded()
            WidgetDataBridge.refresh(context: modelContext, convert: exchangeService.convert)
            if purchaseManager.shouldShowAds {
                interstitialAdManager.preload()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard flow == .main, biometricLockEnabled else { return }
            if newPhase == .background {
                biometricService.lock()
            } else if newPhase == .active, !biometricService.isUnlocked {
                Task { await biometricService.authenticate() }
            }
        }
    }

    private func advanceFromSplash() {
        withAnimation {
            flow = hasCompletedOnboarding ? nextAfterOnboarding() : .onboarding
        }
    }

    private func completeOnboarding() {
        hasCompletedOnboarding = true
        withAnimation { flow = nextAfterOnboarding() }
    }

    private func nextAfterOnboarding() -> AppFlowState {
        (!purchaseManager.isPro && !paywallDismissedThisSession) ? .paywall : .main
    }

    private func dismissPaywall() {
        paywallDismissedThisSession = true
        withAnimation { flow = .main }
    }
}

private struct LockOverlay: View {
    @EnvironmentObject private var biometricService: BiometricAuthService

    var body: some View {
        ZStack {
            FinoraColor.background.ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "faceid")
                    .font(.system(size: 54))
                    .foregroundStyle(FinoraColor.brassGold)
                Text("Money List is locked")
                    .font(FinoraFont.bodyMedium)
                    .foregroundStyle(FinoraColor.textPrimary)
                PrimaryButton(title: "Unlock", gradient: true) {
                    Task { await biometricService.authenticate() }
                }
                .frame(maxWidth: 200)
            }
        }
        .task { await biometricService.authenticate() }
    }
}
