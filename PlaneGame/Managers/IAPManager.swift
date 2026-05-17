import StoreKit

// MARK: - IAPManager

final class IAPManager: NSObject {

    // MARK: - Singleton

    static let shared = IAPManager()

    // MARK: - Properties

    private var products: [String: Product] = [:]
    private var purchaseTask: Task<Void, Never>?

    var onPurchaseComplete: ((String) -> Void)?
    var onPurchaseFailed: ((String) -> Void)?

    static let allProductIDs: Set<String> = [
        GameConfig.IAP.removeAds,
        GameConfig.IAP.gemsSmall,
        GameConfig.IAP.gemsMedium,
        GameConfig.IAP.gemsLarge,
        GameConfig.IAP.vipPass
    ]

    // MARK: - Init

    private override init() {
        super.init()
    }

    // MARK: - Load Products

    func loadProducts() async {
        do {
            let storeProducts = try await Product.products(for: IAPManager.allProductIDs)
            for product in storeProducts {
                products[product.id] = product
            }
            print("[IAPManager] Loaded \(products.count) products")
        } catch {
            print("[IAPManager] Failed to load products: \(error)")
        }
    }

    func product(for id: String) -> Product? {
        products[id]
    }

    // MARK: - Purchase

    func purchase(_ productID: String) async -> Bool {
        guard let product = products[productID] else {
            print("[IAPManager] Product not found: \(productID)")
            return false
        }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await handlePurchase(productID: productID)
                await transaction.finish()
                onPurchaseComplete?(productID)
                return true

            case .userCancelled:
                print("[IAPManager] User cancelled purchase")
                return false

            case .pending:
                print("[IAPManager] Purchase pending")
                return false

            @unknown default:
                return false
            }
        } catch {
            print("[IAPManager] Purchase failed: \(error)")
            onPurchaseFailed?(error.localizedDescription)
            return false
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        do {
            try await AppStore.sync()

            for await result in Transaction.currentEntitlements {
                if case .verified(let transaction) = result {
                    await handlePurchase(productID: transaction.productID)
                }
            }
            print("[IAPManager] Restore complete")
        } catch {
            print("[IAPManager] Restore failed: \(error)")
        }
    }

    // MARK: - Transaction Handling

    private func handlePurchase(productID: String) async {
        var progress = PlayerProgress.load()

        switch productID {
        case GameConfig.IAP.removeAds:
            progress.adsRemoved = true
        case GameConfig.IAP.gemsSmall:
            progress.gems += 100
        case GameConfig.IAP.gemsMedium:
            progress.gems += 500
        case GameConfig.IAP.gemsLarge:
            progress.gems += 1500
        case GameConfig.IAP.vipPass:
            progress.isVIP = true
            progress.adsRemoved = true
        default:
            break
        }

        progress.save()
        GameManager.shared.refreshSystems()
    }

    // MARK: - Verification

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Transaction Listener

    func startTransactionListener() {
        purchaseTask = Task {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await handlePurchase(productID: transaction.productID)
                    await transaction.finish()
                }
            }
        }
    }

    func stopTransactionListener() {
        purchaseTask?.cancel()
        purchaseTask = nil
    }

    // MARK: - Price Formatting

    func formattedPrice(for productID: String) -> String {
        guard let product = products[productID] else { return "--" }
        return product.displayPrice
    }
}
