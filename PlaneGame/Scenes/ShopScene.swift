import SpriteKit

// MARK: - ShopScene

final class ShopScene: SKScene {

    // MARK: - Properties

    private var coinLabel: SKLabelNode!
    private var gemLabel: SKLabelNode!
    private var backButton: SKShapeNode!
    private var shopItems: [ShopItemNode] = []

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(hex: GameConfig.UI.backgroundColor)
        buildUI()
    }

    // MARK: - Build

    private func buildUI() {
        let progress = GameManager.shared.progress

        // Title
        let title = SKLabelNode.styled(text: "SHOP", fontSize: 32, color: .white)
        title.position = CGPoint(x: size.width / 2, y: size.height - 60)
        addChild(title)

        // Currency display
        coinLabel = SKLabelNode.styled(
            text: "\(progress.coins.formattedWithCommas)",
            fontSize: 20,
            color: SKColor(hex: "#FFD700")
        )
        coinLabel.horizontalAlignmentMode = .right
        coinLabel.position = CGPoint(x: size.width - 20, y: size.height - 55)
        addChild(coinLabel)

        gemLabel = SKLabelNode.styled(
            text: "\(progress.gems)",
            fontSize: 20,
            color: SKColor(hex: "#E040FB")
        )
        gemLabel.horizontalAlignmentMode = .right
        gemLabel.position = CGPoint(x: size.width - 20, y: size.height - 80)
        addChild(gemLabel)

        // Back button
        backButton = createNavButton(text: "< BACK", name: "backBtn")
        backButton.position = CGPoint(x: 70, y: size.height - 50)
        addChild(backButton)

        // Section: Remove Ads
        let sectionY = size.height - 140
        let sectionLabel = SKLabelNode.styled(
            text: "PREMIUM",
            fontSize: 18,
            fontName: GameConfig.UI.fontNameRegular,
            color: .lightGray
        )
        sectionLabel.horizontalAlignmentMode = .left
        sectionLabel.position = CGPoint(x: 20, y: sectionY)
        addChild(sectionLabel)

        // IAP items
        let items: [(String, String, String, String)] = [
            (GameConfig.IAP.removeAds, "Remove Ads", "No more ads forever!", "removeAds"),
            (GameConfig.IAP.vipPass, "VIP Pass", "Ad-free + bonus rewards", "vip"),
        ]

        for (i, item) in items.enumerated() {
            let node = ShopItemNode(
                productID: item.0,
                title: item.1,
                description: item.2,
                width: size.width - 40,
                height: 60
            )
            node.position = CGPoint(x: size.width / 2, y: sectionY - 50 - CGFloat(i) * 75)
            node.name = item.3
            addChild(node)
            shopItems.append(node)
        }

        // Section: Gems
        let gemsY = sectionY - 50 - CGFloat(items.count) * 75 - 30
        let gemsLabel = SKLabelNode.styled(
            text: "GEMS",
            fontSize: 18,
            fontName: GameConfig.UI.fontNameRegular,
            color: .lightGray
        )
        gemsLabel.horizontalAlignmentMode = .left
        gemsLabel.position = CGPoint(x: 20, y: gemsY)
        addChild(gemsLabel)

        let gemItems: [(String, String, String, String)] = [
            (GameConfig.IAP.gemsSmall, "100 Gems", "A handful of gems", "gemsSmall"),
            (GameConfig.IAP.gemsMedium, "500 Gems", "A bag of gems", "gemsMedium"),
            (GameConfig.IAP.gemsLarge, "1500 Gems", "A chest of gems!", "gemsLarge"),
        ]

        for (i, item) in gemItems.enumerated() {
            let node = ShopItemNode(
                productID: item.0,
                title: item.1,
                description: item.2,
                width: size.width - 40,
                height: 60
            )
            node.position = CGPoint(x: size.width / 2, y: gemsY - 50 - CGFloat(i) * 75)
            node.name = item.3
            addChild(node)
            shopItems.append(node)
        }

        // Restore purchases button
        let restoreBtn = SKLabelNode.styled(
            text: "Restore Purchases",
            fontSize: 14,
            fontName: GameConfig.UI.fontNameRegular,
            color: .lightGray
        )
        restoreBtn.name = "restoreBtn"
        restoreBtn.position = CGPoint(x: size.width / 2, y: 40)
        addChild(restoreBtn)
    }

    private func createNavButton(text: String, name: String) -> SKShapeNode {
        let btn = SKShapeNode(rectOf: CGSize(width: 100, height: 36), cornerRadius: 18)
        btn.fillColor = SKColor.white.withAlphaComponent(0.1)
        btn.strokeColor = SKColor.white.withAlphaComponent(0.3)
        btn.lineWidth = 1
        btn.name = name

        let label = SKLabelNode.styled(text: text, fontSize: 16, fontName: GameConfig.UI.fontNameRegular, color: .white)
        label.name = name
        btn.addChild(label)

        return btn
    }

    // MARK: - Touch

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tapped = nodes(at: location)

        for node in tapped {
            switch node.name {
            case "backBtn":
                HapticsManager.shared.playButtonTap()
                guard let view = self.view else { return }
                GameManager.shared.returnToMenu(in: view)

            case "restoreBtn":
                HapticsManager.shared.playButtonTap()
                Task {
                    await IAPManager.shared.restorePurchases()
                    refreshUI()
                }

            default:
                // Check shop items
                if let shopItem = findShopItem(at: location) {
                    HapticsManager.shared.playButtonTap()
                    purchaseItem(shopItem)
                }
            }
        }
    }

    private func findShopItem(at location: CGPoint) -> ShopItemNode? {
        for item in shopItems {
            let itemLocation = convert(location, to: item)
            if item.hitTest(itemLocation) {
                return item
            }
        }
        return nil
    }

    private func purchaseItem(_ item: ShopItemNode) {
        Task {
            let success = await IAPManager.shared.purchase(item.productID)
            if success {
                await MainActor.run {
                    HapticsManager.shared.playUpgrade()
                    refreshUI()
                }
            }
        }
    }

    private func refreshUI() {
        let progress = GameManager.shared.progress
        coinLabel.text = "\(progress.coins.formattedWithCommas)"
        gemLabel.text = "\(progress.gems)"
    }
}

// MARK: - ShopItemNode

final class ShopItemNode: SKNode {

    let productID: String
    private let itemWidth: CGFloat
    private let itemHeight: CGFloat

    init(productID: String, title: String, description: String, width: CGFloat, height: CGFloat) {
        self.productID = productID
        self.itemWidth = width
        self.itemHeight = height
        super.init()

        let bg = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 12)
        bg.fillColor = SKColor.white.withAlphaComponent(0.06)
        bg.strokeColor = SKColor.white.withAlphaComponent(0.15)
        bg.lineWidth = 1
        addChild(bg)

        let titleLabel = SKLabelNode.styled(text: title, fontSize: 18, color: .white)
        titleLabel.horizontalAlignmentMode = .left
        titleLabel.position = CGPoint(x: -width / 2 + 16, y: 8)
        addChild(titleLabel)

        let descLabel = SKLabelNode.styled(
            text: description,
            fontSize: 13,
            fontName: GameConfig.UI.fontNameRegular,
            color: .lightGray
        )
        descLabel.horizontalAlignmentMode = .left
        descLabel.position = CGPoint(x: -width / 2 + 16, y: -12)
        addChild(descLabel)

        // Price from StoreKit (or placeholder)
        let price = IAPManager.shared.formattedPrice(for: productID)
        let priceBtn = SKShapeNode(rectOf: CGSize(width: 70, height: 30), cornerRadius: 15)
        priceBtn.fillColor = SKColor(hex: GameConfig.UI.primaryColor)
        priceBtn.strokeColor = .clear
        priceBtn.position = CGPoint(x: width / 2 - 55, y: 0)
        addChild(priceBtn)

        let priceLabel = SKLabelNode.styled(text: price, fontSize: 14, color: .white)
        priceBtn.addChild(priceLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    func hitTest(_ p: CGPoint) -> Bool {
        let rect = CGRect(x: -itemWidth / 2, y: -itemHeight / 2, width: itemWidth, height: itemHeight)
        return rect.contains(p)
    }
}
