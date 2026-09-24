

import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject private var purchaseManager: PurchaseManager
    var onDismiss: () -> Void
    
    private let features: [(icon: String, text: String)] = [
        ("nosign", "No ads. Ever."),
        ("wallet.pass", "Unlimited accounts"),
        ("tag", "Unlimited custom categories"),
        ("target", "Unlimited budgets and goals"),
        ("chart.line.uptrend.xyaxis", "Unlimited investments — stocks, crypto, and more"),
        ("doc.text", "Export your data to CSV")
    ]
    
    var body: some View {
        ZStack {
            FinoraColor.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 0) {
                        ZStack {
                            VStack {
                                HStack {
                                    Button(action: onDismiss) {
                                        Image(systemName: "xmark")
                                            .foregroundStyle(FinoraColor.textSecondary)
                                            .frame(width: 44, height: 44)
                                            .background(FinoraColor.surface)
                                            .clipShape(Circle())
                                    }
                                    Spacer()
                                }
                                Spacer()
                            }
                            
                            Image("logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 170)
                        }
                        
                        
                        VStack(spacing: 10) {
                            (
                                Text("Unlock ").foregroundStyle(FinoraColor.textPrimary)
                                + Text("Money List").foregroundStyle(FinoraColor.verdant)
                                + Text(" Pro").foregroundStyle(FinoraColor.textPrimary)
                            )
                            .font(FinoraFont.paywallHeadline)
                            
                            Text("Everything you need for complete control over your money")
                                .font(FinoraFont.body)
                                .foregroundStyle(FinoraColor.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    
                    VStack(spacing: 9) {
                        ForEach(features, id: \.text) { feature in
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle().fill(FinoraColor.verdant.opacity(0.15)).frame(width: 34, height: 34)
                                    Image(systemName: feature.icon)
                                        .font(.system(size: 17, weight: .medium))
                                        .foregroundStyle(FinoraColor.verdant)
                                }
                                Text(feature.text)
                                    .font(FinoraFont.bodyMedium)
                                    .foregroundStyle(FinoraColor.textPrimary)
                                Spacer()
                            }
                        }
                    }
                    
                    priceCard
                    
                    PrimaryButton(
                        title: "Unlock Money List Pro",
                        icon: "lock.fill",
                        isLoading: purchaseManager.isLoading,
                        gradient: true
                    ) {
                        Task {
                            await purchaseManager.purchase()
                            if purchaseManager.isPro { onDismiss() }
                        }
                    }
                    
                    HStack(spacing: 6) {
                        Button("Restore Purchase") {
                            Task {
                                await purchaseManager.restorePurchases()
                                if purchaseManager.isPro { onDismiss() }
                            }
                        }
                        Text("•")
                        Link("Terms of Use", destination: URL(string: AppDefaults.termsOfUseURL)!)
                        Text("•")
                        Link("Privacy Policy", destination: URL(string: AppDefaults.privacyPolicyURL)!)
                    }
                    .font(FinoraFont.micro)
                    .foregroundStyle(FinoraColor.textTertiary)
                }
                .padding(FinoraMetric.screenPadding)
            }
            .scrollIndicators(.hidden)
        }
        .task { await purchaseManager.fetchProduct() }
        .alert("Something went wrong", isPresented: $purchaseManager.presentErrorAlert) {
            Button("OK", role: .cancel) {}
        }
    }
    
    private var priceCard: some View {
        VStack(spacing: 6) {
            
            Text(purchaseManager.product?.displayPrice ?? AppDefaults.proPrice)
                .font(FinoraFont.amount(36, weight: .bold))
                .foregroundStyle(FinoraColor.textPrimary)
            
            Text("One-time purchase. Forever. No subscription.")
                .font(FinoraFont.caption)
                .foregroundStyle(FinoraColor.brassGold)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(FinoraColor.surface)
        .overlay(
            RoundedRectangle(cornerRadius: FinoraMetric.cardRadius, style: .continuous)
                .stroke(FinoraColor.brassGold.opacity(0.5), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: FinoraMetric.cardRadius, style: .continuous))
    }
}

#Preview {
    PaywallView(onDismiss: {})
        .environmentObject(PurchaseManager())
}
