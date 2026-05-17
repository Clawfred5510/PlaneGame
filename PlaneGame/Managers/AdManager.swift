import UIKit

// MARK: - AdManager
// Placeholder for AdMob integration.
// Replace with actual Google Mobile Ads SDK calls when ready.

final class AdManager {

    // MARK: - Singleton

    static let shared = AdManager()

    // MARK: - Properties

    private var isInitialized = false
    private var interstitialReady = false
    private var rewardedReady = false

    var adsRemoved: Bool {
        GameManager.shared.progress.adsRemoved
    }

    // MARK: - Init

    private init() {}

    // MARK: - Setup

    /// Call this in AppDelegate / app launch.
    func initialize() {
        guard !adsRemoved else { return }

        // TODO: Replace with actual AdMob initialization
        // GADMobileAds.sharedInstance().start { [weak self] status in
        //     self?.isInitialized = true
        //     self?.loadInterstitial()
        //     self?.loadRewarded()
        // }

        isInitialized = true
        print("[AdManager] Initialized (placeholder)")
    }

    // MARK: - Banner

    /// Returns a placeholder banner view. Replace with GADBannerView.
    func createBannerView(in viewController: UIViewController) -> UIView {
        guard !adsRemoved else { return UIView() }

        let banner = UIView()
        banner.backgroundColor = UIColor.darkGray.withAlphaComponent(0.3)
        banner.translatesAutoresizingMaskIntoConstraints = false

        // Placeholder label
        let label = UILabel()
        label.text = "Ad Banner Placeholder"
        label.textColor = .lightGray
        label.font = UIFont.systemFont(ofSize: 12)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        banner.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: banner.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: banner.centerYAnchor),
            banner.heightAnchor.constraint(equalToConstant: 50)
        ])

        return banner
    }

    // MARK: - Interstitial

    func loadInterstitial() {
        guard !adsRemoved, isInitialized else { return }

        // TODO: Replace with actual interstitial loading
        // GADInterstitialAd.load(withAdUnitID: "ca-app-pub-xxx", request: GADRequest()) { ad, error in
        //     self.interstitialReady = ad != nil
        // }

        interstitialReady = true
        print("[AdManager] Interstitial loaded (placeholder)")
    }

    func showInterstitial(from viewController: UIViewController, completion: @escaping () -> Void) {
        guard !adsRemoved, interstitialReady else {
            completion()
            return
        }

        // TODO: Replace with actual interstitial presentation
        print("[AdManager] Showing interstitial (placeholder)")
        interstitialReady = false
        loadInterstitial()
        completion()
    }

    // MARK: - Rewarded

    func loadRewarded() {
        guard !adsRemoved, isInitialized else { return }

        // TODO: Replace with actual rewarded ad loading
        rewardedReady = true
        print("[AdManager] Rewarded ad loaded (placeholder)")
    }

    func showRewarded(from viewController: UIViewController,
                      completion: @escaping (Bool) -> Void) {
        guard rewardedReady else {
            completion(false)
            return
        }

        // TODO: Replace with actual rewarded ad presentation
        print("[AdManager] Showing rewarded ad (placeholder)")
        rewardedReady = false
        loadRewarded()
        completion(true) // Simulate reward granted
    }

    var isRewardedReady: Bool { rewardedReady && !adsRemoved }
}
