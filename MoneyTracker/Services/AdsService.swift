

import SwiftUI
import GoogleMobileAds
internal import Combine

enum AdsService {
    static func start() {
        MobileAds.shared.start()
    }
}


struct BannerAdView: View {
    @State private var adLoaded = false

    var body: some View {
        let adSize = largeAnchoredAdaptiveBanner(width: UIScreen.main.bounds.width - FinoraMetric.screenPadding * 2)
        BannerViewRepresentable(adSize: adSize, adLoaded: $adLoaded)
            .frame(width: adSize.size.width, height: adSize.size.height)
            .opacity(adLoaded ? 1 : 0)
            .frame(height: adLoaded ? adSize.size.height : 0)
            .animation(.easeOut(duration: 0.25), value: adLoaded)
    }
}

private struct BannerViewRepresentable: UIViewRepresentable {
    let adSize: AdSize
    @Binding var adLoaded: Bool

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: adSize)
        banner.adUnitID = AppDefaults.bannerAdUnitID
        banner.rootViewController = UIApplication.shared.topViewController
        banner.delegate = context.coordinator
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(adLoaded: $adLoaded) }

    final class Coordinator: NSObject, BannerViewDelegate {
        @Binding var adLoaded: Bool
        init(adLoaded: Binding<Bool>) { _adLoaded = adLoaded }

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            adLoaded = true
        }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            print("Money List: banner ad failed to load — \(error.localizedDescription)")
            adLoaded = false
        }
    }
}


@MainActor
final class InterstitialAdManager: NSObject, ObservableObject, FullScreenContentDelegate {
    private var interstitialAd: InterstitialAd?
    private var isLoading = false

    func preload() {
        guard interstitialAd == nil, !isLoading else { return }
        isLoading = true
        Task {
            do {
                interstitialAd = try await InterstitialAd.load(with: AppDefaults.interstitialAdUnitID, request: Request())
                interstitialAd?.fullScreenContentDelegate = self
            } catch {
                print("Money List: interstitial failed to load — \(error.localizedDescription)")
            }
            isLoading = false
        }
    }

    
    func showIfReady() {
        guard let interstitialAd else {
            preload()
            return
        }
        guard let root = UIApplication.shared.topViewController else { return }
        interstitialAd.present(from: root)
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        interstitialAd = nil
        preload()
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Money List: interstitial failed to present — \(error.localizedDescription)")
        interstitialAd = nil
        preload()
    }
}


private extension UIApplication {

    var topViewController: UIViewController? {
        let scenes = connectedScenes.compactMap { $0 as? UIWindowScene }
        guard let root = scenes.first?.windows.first(where: \.isKeyWindow)?.rootViewController else {
            return nil
        }
        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }
}
