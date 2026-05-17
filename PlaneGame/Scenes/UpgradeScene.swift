import SpriteKit

// MARK: - UpgradeScene

final class UpgradeScene: SKScene {

    // MARK: - Properties

    private var coinLabel: SKLabelNode!
    private var planePreview: PlaneNode!
    private var upgradeCards: [UpgradeCard] = []
    private var stageLabel: SKLabelNode!
    private var backButton: SKShapeNode!
    private var playButton: SKShapeNode!

    // Stats bars
    private var thrustBar: StatBar!
    private var liftBar: StatBar!
    private var dragBar: StatBar!

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(hex: GameConfig.UI.backgroundColor)
        buildUI()
    }

    // MARK: - Build

    private func buildUI() {
        let progress = GameManager.shared.progress
        let upgradeSystem = GameManager.shared.upgradeSystem

        // Title
        let title = SKLabelNode.styled(text: "UPGRADES", fontSize: 32, color: .white)
        title.position = CGPoint(x: size.width / 2, y: size.height - 60)
        addChild(title)

        // Coin counter
        let coinIcon = SKShapeNode(circleOfRadius: 10)
        coinIcon.fillColor = SKColor(hex: "#FFD700")
        coinIcon.strokeColor = SKColor(hex: "#FFA000")
        coinIcon.lineWidth = 1
        coinIcon.position = CGPoint(x: size.width / 2 - 50, y: size.height - 95)
        addChild(coinIcon)

        coinLabel = SKLabelNode.styled(
            text: "\(progress.coins.formattedWithCommas)",
            fontSize: 22,
            color: SKColor(hex: "#FFD700")
        )
        coinLabel.horizontalAlignmentMode = .left
        coinLabel.position = CGPoint(x: size.width / 2 - 32, y: size.height - 100)
        addChild(coinLabel)

        // Plane preview
        planePreview = PlaneNode(model: progress.plane)
        planePreview.position = CGPoint(x: size.width / 2, y: size.height * 0.62)
        planePreview.setScale(2.0)
        addChild(planePreview)

        // Stage label
        stageLabel = SKLabelNode.styled(
            text: progress.plane.currentStage.displayName,
            fontSize: 20,
            fontName: GameConfig.UI.fontNameRegular,
            color: SKColor(hex: GameConfig.UI.secondaryColor)
        )
        stageLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.53)
        addChild(stageLabel)

        // Stats bars
        let stats = upgradeSystem.currentStats()
        let barsX = size.width / 2
        let barsY = size.height * 0.47

        thrustBar = StatBar(label: "THR", value: stats.thrustNormalized, color: SKColor(hex: "#FF6B35"))
        thrustBar.position = CGPoint(x: barsX, y: barsY)
        addChild(thrustBar)

        liftBar = StatBar(label: "LFT", value: stats.liftNormalized, color: SKColor(hex: "#4ECDC4"))
        liftBar.position = CGPoint(x: barsX, y: barsY - 24)
        addChild(liftBar)

        dragBar = StatBar(label: "AER", value: stats.dragNormalized, color: SKColor(hex: "#45B7D1"))
        dragBar.position = CGPoint(x: barsX, y: barsY - 48)
        addChild(dragBar)

        // Upgrade cards
        buildUpgradeCards()

        // Back button
        backButton = createNavButton(text: "< BACK", name: "backBtn")
        backButton.position = CGPoint(x: 70, y: size.height - 50)
        addChild(backButton)

        // Play button
        playButton = createActionButton(text: "PLAY", color: SKColor(hex: GameConfig.UI.accentColor), name: "playBtn")
        playButton.position = CGPoint(x: size.width / 2, y: 60)
        addChild(playButton)
    }

    private func buildUpgradeCards() {
        // Remove existing
        for card in upgradeCards { card.removeFromParent() }
        upgradeCards.removeAll()

        let types = UpgradeType.allCases
        let cardWidth: CGFloat = (size.width - 60) / CGFloat(types.count)
        let cardY = size.height * 0.22

        for (i, type) in types.enumerated() {
            let info = GameManager.shared.upgradeSystem.upgradeInfo(for: type)
            let card = UpgradeCard(
                type: type,
                level: info.level,
                maxLevel: info.maxLevel,
                cost: info.cost,
                canAfford: info.canAfford,
                width: cardWidth - 10,
                height: 160
            )
            let x = 30 + cardWidth * CGFloat(i) + cardWidth / 2
            card.position = CGPoint(x: x, y: cardY)
            addChild(card)
            upgradeCards.append(card)
        }
    }

    // MARK: - Helpers

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

    private func createActionButton(text: String, color: SKColor, name: String) -> SKShapeNode {
        let btn = SKShapeNode(rectOf: CGSize(width: 200, height: 52), cornerRadius: 26)
        btn.fillColor = color
        btn.strokeColor = .clear
        btn.name = name

        let label = SKLabelNode.styled(text: text, fontSize: 20, color: .white)
        label.name = name
        btn.addChild(label)

        return btn
    }

    // MARK: - Refresh

    private func refreshUI() {
        let progress = GameManager.shared.progress
        coinLabel.text = "\(progress.coins.formattedWithCommas)"
        stageLabel.text = progress.plane.currentStage.displayName

        let stats = GameManager.shared.upgradeSystem.currentStats()
        thrustBar.setValue(stats.thrustNormalized)
        liftBar.setValue(stats.liftNormalized)
        dragBar.setValue(stats.dragNormalized)

        planePreview.updateModel(progress.plane)
        buildUpgradeCards()
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

            case "playBtn":
                HapticsManager.shared.playButtonTap()
                guard let view = self.view else { return }
                GameManager.shared.startGame(in: view)

            default:
                // Check upgrade cards
                if let cardNode = findUpgradeCard(at: location) {
                    attemptUpgrade(cardNode.type)
                }
            }
        }
    }

    private func findUpgradeCard(at location: CGPoint) -> UpgradeCard? {
        for card in upgradeCards {
            let cardLocation = convert(location, to: card)
            if card.contains(cardLocation) {
                return card
            }
        }
        return nil
    }

    private func attemptUpgrade(_ type: UpgradeType) {
        guard let result = GameManager.shared.purchaseUpgrade(type) else {
            // Can't afford or maxed — shake the coin label
            coinLabel.shake(intensity: 5, duration: 0.2)
            return
        }

        HapticsManager.shared.playUpgrade()
        AudioManager.shared.playSound(GameConfig.Audio.upgradeSound)

        // Check for evolution
        if let newStage = result.newStage {
            showEvolutionBanner(stage: newStage)
        }

        refreshUI()
    }

    private func showEvolutionBanner(stage: PlaneStage) {
        let banner = SKShapeNode(rectOf: CGSize(width: 280, height: 60), cornerRadius: 30)
        banner.fillColor = SKColor(hex: GameConfig.UI.secondaryColor)
        banner.strokeColor = .clear
        banner.position = CGPoint(x: size.width / 2, y: size.height / 2)
        banner.zPosition = GameConfig.ZPosition.overlay

        let label = SKLabelNode.styled(
            text: "EVOLVED: \(stage.displayName.uppercased())!",
            fontSize: 20,
            color: .white
        )
        banner.addChild(label)
        addChild(banner)

        banner.setScale(0)
        let show = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.2),
            SKAction.scale(to: 1.0, duration: 0.1),
            SKAction.wait(forDuration: 1.5),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ])
        banner.run(show)
    }
}

// MARK: - UpgradeCard

final class UpgradeCard: SKNode {

    let type: UpgradeType
    private let cardWidth: CGFloat
    private let cardHeight: CGFloat

    init(type: UpgradeType, level: Int, maxLevel: Int, cost: Int,
         canAfford: Bool, width: CGFloat, height: CGFloat) {
        self.type = type
        self.cardWidth = width
        self.cardHeight = height
        super.init()

        let isMaxed = level >= maxLevel

        // Card background
        let bg = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 12)
        bg.fillColor = SKColor.white.withAlphaComponent(0.08)
        bg.strokeColor = canAfford && !isMaxed ?
            SKColor(hex: GameConfig.UI.accentColor).withAlphaComponent(0.5) :
            SKColor.white.withAlphaComponent(0.15)
        bg.lineWidth = 1.5
        addChild(bg)

        // Icon area
        let iconBg = SKShapeNode(circleOfRadius: 22)
        iconBg.fillColor = SKColor.white.withAlphaComponent(0.1)
        iconBg.strokeColor = .clear
        iconBg.position = CGPoint(x: 0, y: height / 2 - 38)
        addChild(iconBg)

        let iconText: String
        switch type {
        case .engine: iconText = "E"
        case .wings: iconText = "W"
        case .fuselage: iconText = "F"
        }
        let icon = SKLabelNode.styled(text: iconText, fontSize: 20, color: .white)
        icon.position = iconBg.position
        addChild(icon)

        // Name
        let name = SKLabelNode.styled(
            text: type.displayName,
            fontSize: 14,
            color: .white
        )
        name.position = CGPoint(x: 0, y: height / 2 - 70)
        addChild(name)

        // Level indicator
        let levelText = isMaxed ? "MAX" : "Lv. \(level)/\(maxLevel)"
        let lvl = SKLabelNode.styled(
            text: levelText,
            fontSize: 12,
            fontName: GameConfig.UI.fontNameRegular,
            color: isMaxed ? SKColor(hex: GameConfig.UI.secondaryColor) : .lightGray
        )
        lvl.position = CGPoint(x: 0, y: height / 2 - 90)
        addChild(lvl)

        // Level progress dots
        let dotSpacing: CGFloat = 8
        let totalDotsWidth = dotSpacing * CGFloat(maxLevel - 1)
        let dotsStartX = -totalDotsWidth / 2

        for i in 0..<maxLevel {
            let dot = SKShapeNode(circleOfRadius: 3)
            dot.fillColor = i < level ?
                SKColor(hex: GameConfig.UI.accentColor) :
                SKColor.white.withAlphaComponent(0.2)
            dot.strokeColor = .clear
            dot.position = CGPoint(x: dotsStartX + CGFloat(i) * dotSpacing, y: height / 2 - 108)
            addChild(dot)
        }

        // Cost button
        if !isMaxed {
            let costBtn = SKShapeNode(rectOf: CGSize(width: width - 20, height: 30), cornerRadius: 15)
            costBtn.fillColor = canAfford ?
                SKColor(hex: GameConfig.UI.accentColor) :
                SKColor.white.withAlphaComponent(0.1)
            costBtn.strokeColor = .clear
            costBtn.position = CGPoint(x: 0, y: -height / 2 + 25)
            addChild(costBtn)

            let costLabel = SKLabelNode.styled(
                text: "\(cost.formattedWithCommas)",
                fontSize: 13,
                color: canAfford ? .white : .gray
            )
            costBtn.addChild(costLabel)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    override func contains(_ p: CGPoint) -> Bool {
        let rect = CGRect(x: -cardWidth / 2, y: -cardHeight / 2, width: cardWidth, height: cardHeight)
        return rect.contains(p)
    }
}

// MARK: - StatBar

final class StatBar: SKNode {

    private var fillNode: SKShapeNode!
    private let barWidth: CGFloat = 160
    private let barHeight: CGFloat = 10

    init(label: String, value: CGFloat, color: SKColor) {
        super.init()

        let lbl = SKLabelNode.styled(
            text: label,
            fontSize: 12,
            fontName: GameConfig.UI.fontNameRegular,
            color: .lightGray
        )
        lbl.horizontalAlignmentMode = .right
        lbl.position = CGPoint(x: -barWidth / 2 - 10, y: -4)
        addChild(lbl)

        let bg = SKShapeNode(rectOf: CGSize(width: barWidth, height: barHeight), cornerRadius: 5)
        bg.fillColor = SKColor.white.withAlphaComponent(0.1)
        bg.strokeColor = .clear
        addChild(bg)

        let fillW = max(1, barWidth * value.clamped(to: 0...1))
        fillNode = SKShapeNode(rectOf: CGSize(width: fillW, height: barHeight - 2), cornerRadius: 4)
        fillNode.fillColor = color
        fillNode.strokeColor = .clear
        fillNode.position.x = -(barWidth - fillW) / 2
        addChild(fillNode)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    func setValue(_ value: CGFloat) {
        let fillW = max(1, barWidth * value.clamped(to: 0...1))
        let previousColor = fillNode.fillColor
        fillNode.removeFromParent()
        fillNode = SKShapeNode(rectOf: CGSize(width: fillW, height: barHeight - 2), cornerRadius: 4)
        fillNode.fillColor = previousColor
        fillNode.strokeColor = .clear
        fillNode.position.x = -(barWidth - fillW) / 2
        addChild(fillNode)
    }
}
