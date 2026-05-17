import SpriteKit

// MARK: - UpgradeScene

final class UpgradeScene: SKScene {

    // MARK: - Properties

    private var coinLabel: SKLabelNode!
    private var planePreview: PlaneNode!
    private var upgradeCards: [UpgradeCard] = []
    private var stageLabel: SKLabelNode!
    private var stageProgressLabel: SKLabelNode!
    private var backButton: SKShapeNode!
    private var playButton: SKShapeNode!

    // Stats bars
    private var thrustBar: StatBar!
    private var liftBar: StatBar!
    private var dragBar: StatBar!

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(hex: "#0F1B2E")
        buildBackground()
        buildUI()
        animateEntrance()
    }

    // MARK: - Background

    private func buildBackground() {
        // Dark blue gradient background
        let topGradient = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height * 0.5))
        topGradient.fillColor = SKColor(hex: "#0D1520")
        topGradient.strokeColor = .clear
        topGradient.position = CGPoint(x: size.width / 2, y: size.height * 0.75)
        topGradient.zPosition = GameConfig.ZPosition.background
        addChild(topGradient)

        let bottomGradient = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height * 0.5))
        bottomGradient.fillColor = SKColor(hex: "#152238")
        bottomGradient.strokeColor = .clear
        bottomGradient.position = CGPoint(x: size.width / 2, y: size.height * 0.25)
        bottomGradient.zPosition = GameConfig.ZPosition.background
        addChild(bottomGradient)

        // Subtle decorative grid lines
        for i in 0..<5 {
            let line = SKShapeNode(rectOf: CGSize(width: size.width, height: 0.5))
            line.fillColor = SKColor.white.withAlphaComponent(0.03)
            line.strokeColor = .clear
            line.position = CGPoint(x: size.width / 2, y: CGFloat(i + 1) * size.height / 5)
            line.zPosition = GameConfig.ZPosition.background + 1
            addChild(line)
        }
    }

    // MARK: - Build UI

    private func buildUI() {
        let progress = GameManager.shared.progress

        buildHeader(progress: progress)
        buildPlanePreview(progress: progress)
        buildStageInfo(progress: progress)
        buildUpgradeCards()
        buildStatBars()
        buildBottomButtons()
    }

    private func buildHeader(progress: PlayerProgress) {
        // Title
        let title = SKLabelNode.styled(text: "UPGRADES", fontSize: 28, color: .white)
        title.position = CGPoint(x: size.width / 2, y: size.height - 55)
        title.zPosition = GameConfig.ZPosition.hud
        addChild(title)

        // Back button (left)
        backButton = SKShapeNode(rectOf: CGSize(width: 80, height: 36), cornerRadius: 18)
        backButton.fillColor = SKColor.white.withAlphaComponent(0.08)
        backButton.strokeColor = SKColor.white.withAlphaComponent(0.2)
        backButton.lineWidth = 1
        backButton.position = CGPoint(x: 55, y: size.height - 50)
        backButton.name = "backBtn"
        backButton.zPosition = GameConfig.ZPosition.hud
        addChild(backButton)

        let backLabel = SKLabelNode.styled(text: "< BACK", fontSize: 13, fontName: GameConfig.UI.fontNameRegular, color: .white)
        backLabel.name = "backBtn"
        backButton.addChild(backLabel)

        // Coin display (right)
        let coinBg = SKShapeNode(rectOf: CGSize(width: 110, height: 32), cornerRadius: 16)
        coinBg.fillColor = SKColor.white.withAlphaComponent(0.06)
        coinBg.strokeColor = SKColor(hex: "#FFD700").withAlphaComponent(0.3)
        coinBg.lineWidth = 1
        coinBg.position = CGPoint(x: size.width - 75, y: size.height - 50)
        coinBg.zPosition = GameConfig.ZPosition.hud
        addChild(coinBg)

        let coinIcon = SKShapeNode(circleOfRadius: 9)
        coinIcon.fillColor = SKColor(hex: "#FFD700")
        coinIcon.strokeColor = SKColor(hex: "#FFA000")
        coinIcon.lineWidth = 1
        coinIcon.position = CGPoint(x: -38, y: 0)
        coinBg.addChild(coinIcon)

        let coinSymbol = SKLabelNode.styled(text: "$", fontSize: 10, color: SKColor(hex: "#B8860B"))
        coinIcon.addChild(coinSymbol)

        coinLabel = SKLabelNode.styled(
            text: progress.coins.formattedWithCommas,
            fontSize: 16,
            fontName: GameConfig.UI.fontName,
            color: SKColor(hex: "#FFD700")
        )
        coinLabel.horizontalAlignmentMode = .left
        coinLabel.position = CGPoint(x: -22, y: -5)
        coinBg.addChild(coinLabel)
    }

    private func buildPlanePreview(progress: PlayerProgress) {
        // Plane preview area with subtle background
        let previewBg = SKShapeNode(circleOfRadius: 55)
        previewBg.fillColor = SKColor.white.withAlphaComponent(0.03)
        previewBg.strokeColor = SKColor.white.withAlphaComponent(0.08)
        previewBg.lineWidth = 1
        previewBg.position = CGPoint(x: size.width / 2, y: size.height * 0.72)
        previewBg.zPosition = 0
        addChild(previewBg)

        // Plane node
        planePreview = PlaneNode(model: progress.plane)
        planePreview.position = CGPoint(x: size.width / 2, y: size.height * 0.72)
        planePreview.setScale(2.2)
        planePreview.zPosition = GameConfig.ZPosition.plane
        addChild(planePreview)

        // Slow hover animation
        let hover = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 6, duration: 1.5),
            SKAction.moveBy(x: 0, y: -6, duration: 1.5)
        ])
        hover.timingMode = .easeInEaseOut
        planePreview.run(SKAction.repeatForever(hover))

        // Slow rotation wobble
        let rotateLeft = SKAction.rotate(toAngle: degreesToRadians(3), duration: 2.0)
        let rotateRight = SKAction.rotate(toAngle: degreesToRadians(-3), duration: 2.0)
        rotateLeft.timingMode = .easeInEaseOut
        rotateRight.timingMode = .easeInEaseOut
        planePreview.run(SKAction.repeatForever(SKAction.sequence([rotateLeft, rotateRight])))
    }

    private func buildStageInfo(progress: PlayerProgress) {
        // Current stage name
        stageLabel = SKLabelNode.styled(
            text: progress.plane.currentStage.displayName.uppercased(),
            fontSize: 20,
            color: SKColor(hex: GameConfig.UI.secondaryColor)
        )
        stageLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.62)
        stageLabel.zPosition = GameConfig.ZPosition.hud
        addChild(stageLabel)

        // Stage evolution progress
        let currentStage = progress.plane.currentStage
        let totalLevel = progress.plane.totalUpgradeLevel
        let nextStageInfo = getNextStageInfo(currentStage: currentStage, totalLevel: totalLevel)

        stageProgressLabel = SKLabelNode.styled(
            text: nextStageInfo,
            fontSize: 13,
            fontName: GameConfig.UI.fontNameRegular,
            color: SKColor.white.withAlphaComponent(0.4)
        )
        stageProgressLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.59)
        stageProgressLabel.zPosition = GameConfig.ZPosition.hud
        addChild(stageProgressLabel)
    }

    private func getNextStageInfo(currentStage: PlaneStage, totalLevel: Int) -> String {
        // Find the next stage
        let allStages = PlaneStage.allCases
        guard let currentIndex = allStages.firstIndex(of: currentStage),
              currentIndex + 1 < allStages.count else {
            return "MAX EVOLUTION"
        }

        let nextStage = allStages[currentIndex + 1]
        let remaining = nextStage.upgradeThreshold - totalLevel
        return "\(remaining) more upgrades to \(nextStage.displayName)!"
    }

    private func buildUpgradeCards() {
        // Remove existing cards
        for card in upgradeCards { card.removeFromParent() }
        upgradeCards.removeAll()

        let types = UpgradeType.allCases
        let cardWidth: CGFloat = size.width - 40
        let cardHeight: CGFloat = 80
        let cardSpacing: CGFloat = 10
        let startY = size.height * 0.50

        let colors: [UpgradeType: String] = [
            .engine: "#FF6D00",
            .wings: "#2979FF",
            .fuselage: "#00C853"
        ]

        for (i, type) in types.enumerated() {
            let info = GameManager.shared.upgradeSystem.upgradeInfo(for: type)
            let card = UpgradeCard(
                type: type,
                level: info.level,
                maxLevel: info.maxLevel,
                cost: info.cost,
                canAfford: info.canAfford,
                width: cardWidth,
                height: cardHeight,
                accentColor: SKColor(hex: colors[type] ?? "#FFFFFF")
            )
            let y = startY - CGFloat(i) * (cardHeight + cardSpacing)
            card.position = CGPoint(x: size.width / 2, y: y)
            card.zPosition = GameConfig.ZPosition.hud
            addChild(card)
            upgradeCards.append(card)
        }
    }

    private func buildStatBars() {
        let stats = GameManager.shared.upgradeSystem.currentStats()
        let barsX = size.width / 2
        let barsY = size.height * 0.16
        let barSpacing: CGFloat = 26

        thrustBar = StatBar(label: "THRUST", value: stats.thrustNormalized, color: SKColor(hex: "#FF6D00"))
        thrustBar.position = CGPoint(x: barsX, y: barsY)
        thrustBar.zPosition = GameConfig.ZPosition.hud
        addChild(thrustBar)

        liftBar = StatBar(label: "LIFT", value: stats.liftNormalized, color: SKColor(hex: "#2979FF"))
        liftBar.position = CGPoint(x: barsX, y: barsY - barSpacing)
        liftBar.zPosition = GameConfig.ZPosition.hud
        addChild(liftBar)

        dragBar = StatBar(label: "AERO", value: stats.dragNormalized, color: SKColor(hex: "#00C853"))
        dragBar.position = CGPoint(x: barsX, y: barsY - barSpacing * 2)
        dragBar.zPosition = GameConfig.ZPosition.hud
        addChild(dragBar)
    }

    private func buildBottomButtons() {
        // Play button
        playButton = SKShapeNode(rectOf: CGSize(width: 200, height: 52), cornerRadius: 26)
        playButton.fillColor = SKColor(hex: "#4CAF50")
        playButton.strokeColor = .clear
        playButton.glowWidth = 3
        playButton.position = CGPoint(x: size.width / 2, y: 50)
        playButton.name = "playBtn"
        playButton.zPosition = GameConfig.ZPosition.hud
        addChild(playButton)

        let playLabel = SKLabelNode.styled(text: "PLAY", fontSize: 20, color: .white)
        playLabel.name = "playBtn"
        playButton.addChild(playLabel)
    }

    // MARK: - Entrance Animation

    private func animateEntrance() {
        // Cards slide in from right with stagger
        for (i, card) in upgradeCards.enumerated() {
            let originalX = card.position.x
            card.position.x = size.width + 200
            card.alpha = 0

            let delay = SKAction.wait(forDuration: 0.1 + Double(i) * 0.08)
            let slide = SKAction.moveTo(x: originalX, duration: 0.35)
            slide.timingMode = .easeOut
            let fade = SKAction.fadeIn(withDuration: 0.35)
            card.run(SKAction.sequence([delay, SKAction.group([slide, fade])]))
        }

        // Plane preview scales in
        planePreview.setScale(0)
        planePreview.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.2),
            SKAction.scale(to: 2.2, duration: 0.3)
        ]))

        // Play button slides up
        let playOriginalY = playButton.position.y
        playButton.position.y -= 40
        playButton.alpha = 0
        playButton.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.4),
            SKAction.group([
                SKAction.moveTo(y: playOriginalY, duration: 0.3),
                SKAction.fadeIn(withDuration: 0.3)
            ])
        ]))
    }

    // MARK: - Refresh

    private func refreshUI() {
        let progress = GameManager.shared.progress
        coinLabel.text = progress.coins.formattedWithCommas
        stageLabel.text = progress.plane.currentStage.displayName.uppercased()

        let totalLevel = progress.plane.totalUpgradeLevel
        stageProgressLabel.text = getNextStageInfo(currentStage: progress.plane.currentStage, totalLevel: totalLevel)

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
                AudioManager.shared.playSound(GameConfig.Audio.buttonSound)
                guard let view = self.view else { return }
                GameManager.shared.returnToMenu(in: view)
                return

            case "playBtn":
                HapticsManager.shared.playButtonTap()
                AudioManager.shared.playSound(GameConfig.Audio.buttonSound)
                guard let view = self.view else { return }
                GameManager.shared.startGame(in: view)
                return

            default:
                break
            }
        }

        // Check upgrade cards
        if let cardNode = findUpgradeCard(at: location) {
            attemptUpgrade(cardNode.type)
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
            // Can't afford or maxed - shake coin label and flash card red
            coinLabel.shake(intensity: 5, duration: 0.2)
            HapticsManager.shared.playButtonTap()
            return
        }

        HapticsManager.shared.playUpgrade()
        AudioManager.shared.playSound(GameConfig.Audio.upgradeSound)

        // Purchase animation
        showUpgradeEffect(for: type)

        // Check for evolution
        if let newStage = result.newStage {
            showEvolutionCelebration(stage: newStage)
        }

        refreshUI()
    }

    private func showUpgradeEffect(for type: UpgradeType) {
        // Find the card and flash it
        for card in upgradeCards where card.type == type {
            let flash = SKShapeNode(rectOf: CGSize(width: card.cardWidth, height: card.cardHeight), cornerRadius: 16)
            flash.fillColor = SKColor.white.withAlphaComponent(0.3)
            flash.strokeColor = .clear
            flash.position = card.position
            flash.zPosition = GameConfig.ZPosition.overlay
            addChild(flash)

            flash.run(SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.3),
                SKAction.removeFromParent()
            ]))
            break
        }

        // Coin subtraction animation on coin label
        let coinFly = SKLabelNode.styled(text: "-", fontSize: 16, color: SKColor(hex: "#EF5350"))
        coinFly.position = coinLabel.position
        coinFly.position.y += 20
        coinFly.zPosition = GameConfig.ZPosition.overlay
        addChild(coinFly)

        coinFly.run(SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: 0, y: 20, duration: 0.4),
                SKAction.fadeOut(withDuration: 0.4)
            ]),
            SKAction.removeFromParent()
        ]))
    }

    private func showEvolutionCelebration(stage: PlaneStage) {
        // Full-screen celebration overlay
        let overlay = SKNode()
        overlay.zPosition = GameConfig.ZPosition.overlay

        // Dark backdrop
        let dim = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: size.height * 2))
        dim.fillColor = SKColor.black.withAlphaComponent(0.6)
        dim.strokeColor = .clear
        dim.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.addChild(dim)

        // "EVOLUTION!" text
        let evolLabel = SKLabelNode.styled(
            text: "EVOLUTION!",
            fontSize: 36,
            color: SKColor(hex: GameConfig.UI.secondaryColor)
        )
        evolLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.6)
        overlay.addChild(evolLabel)

        // Stage name
        let stageNameLabel = SKLabelNode.styled(
            text: stage.displayName.uppercased(),
            fontSize: 24,
            color: .white
        )
        stageNameLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.52)
        overlay.addChild(stageNameLabel)

        // Particle explosion
        let particleCount = 40
        for _ in 0..<particleCount {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 3...7))
            let colors = ["#FFD700", "#FF6D00", "#4CAF50", "#2979FF", "#9C27B0"]
            particle.fillColor = SKColor(hex: colors.randomElement()!)
            particle.strokeColor = .clear
            particle.glowWidth = 3
            particle.position = CGPoint(x: size.width / 2, y: size.height / 2)
            particle.zPosition = 1
            overlay.addChild(particle)

            let angle = CGFloat.random(in: 0...(.pi * 2))
            let distance = CGFloat.random(in: 80...250)
            let dx = cos(angle) * distance
            let dy = sin(angle) * distance

            let move = SKAction.moveBy(x: dx, y: dy, duration: CGFloat.random(in: 0.5...1.0))
            move.timingMode = .easeOut
            let fade = SKAction.fadeOut(withDuration: 1.0)
            particle.run(SKAction.group([move, fade]))
        }

        addChild(overlay)

        // Animate in
        overlay.alpha = 0
        evolLabel.setScale(0.5)
        overlay.run(SKAction.fadeIn(withDuration: 0.2))
        evolLabel.run(SKAction.sequence([
            SKAction.scale(to: 1.3, duration: 0.2),
            SKAction.scale(to: 1.0, duration: 0.1)
        ]))

        // Auto-dismiss after 2.5 seconds
        overlay.run(SKAction.sequence([
            SKAction.wait(forDuration: 2.5),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ]))
    }
}

// MARK: - UpgradeCard

final class UpgradeCard: SKNode {

    let type: UpgradeType
    let cardWidth: CGFloat
    let cardHeight: CGFloat

    init(type: UpgradeType, level: Int, maxLevel: Int, cost: Int,
         canAfford: Bool, width: CGFloat, height: CGFloat, accentColor: SKColor) {
        self.type = type
        self.cardWidth = width
        self.cardHeight = height
        super.init()

        let isMaxed = level >= maxLevel

        // Card background
        let bg = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: 16)
        bg.fillColor = SKColor.white.withAlphaComponent(0.05)
        bg.strokeColor = isMaxed ? SKColor(hex: GameConfig.UI.secondaryColor).withAlphaComponent(0.3) :
                         canAfford ? accentColor.withAlphaComponent(0.4) :
                         SKColor.white.withAlphaComponent(0.1)
        bg.lineWidth = 1.5
        addChild(bg)

        // Left: Icon area with colored circle
        let iconCircle = SKShapeNode(circleOfRadius: 22)
        iconCircle.fillColor = accentColor.withAlphaComponent(0.2)
        iconCircle.strokeColor = accentColor.withAlphaComponent(0.5)
        iconCircle.lineWidth = 2
        iconCircle.position = CGPoint(x: -width / 2 + 38, y: 0)
        addChild(iconCircle)

        let iconText: String
        switch type {
        case .engine: iconText = "E"
        case .wings: iconText = "W"
        case .fuselage: iconText = "F"
        }
        let icon = SKLabelNode.styled(text: iconText, fontSize: 18, color: accentColor)
        icon.position = iconCircle.position
        addChild(icon)

        // Center: Name + Description
        let nameLabel = SKLabelNode.styled(
            text: type.displayName,
            fontSize: 16,
            color: .white
        )
        nameLabel.horizontalAlignmentMode = .left
        nameLabel.position = CGPoint(x: -width / 2 + 72, y: 14)
        addChild(nameLabel)

        let descLabel = SKLabelNode.styled(
            text: type.description,
            fontSize: 11,
            fontName: GameConfig.UI.fontNameRegular,
            color: SKColor.white.withAlphaComponent(0.5)
        )
        descLabel.horizontalAlignmentMode = .left
        descLabel.position = CGPoint(x: -width / 2 + 72, y: -4)
        addChild(descLabel)

        // Level indicator
        let levelText = isMaxed ? "MAX" : "Lv.\(level)/\(maxLevel)"
        let levelColor = isMaxed ? SKColor(hex: GameConfig.UI.secondaryColor) : SKColor.white.withAlphaComponent(0.6)
        let lvlLabel = SKLabelNode.styled(
            text: levelText,
            fontSize: 11,
            fontName: GameConfig.UI.fontNameRegular,
            color: levelColor
        )
        lvlLabel.horizontalAlignmentMode = .left
        lvlLabel.position = CGPoint(x: -width / 2 + 72, y: -20)
        addChild(lvlLabel)

        // Progress bar
        let barWidth: CGFloat = 100
        let barHeight: CGFloat = 5
        let barX: CGFloat = -width / 2 + 72
        let barY: CGFloat = -32

        let barBg = SKShapeNode(rectOf: CGSize(width: barWidth, height: barHeight), cornerRadius: 2.5)
        barBg.fillColor = SKColor.white.withAlphaComponent(0.1)
        barBg.strokeColor = .clear
        barBg.position = CGPoint(x: barX + barWidth / 2, y: barY)
        addChild(barBg)

        let fillFraction = CGFloat(level) / CGFloat(maxLevel)
        let fillW = max(1, barWidth * fillFraction)
        let barFill = SKShapeNode(rectOf: CGSize(width: fillW, height: barHeight - 1), cornerRadius: 2)
        barFill.fillColor = accentColor
        barFill.strokeColor = .clear
        barFill.position = CGPoint(x: -(barWidth - fillW) / 2, y: 0)
        barBg.addChild(barFill)

        // Right: Cost button
        let costBtnWidth: CGFloat = 72
        let costBtnHeight: CGFloat = 34

        if isMaxed {
            let maxBadge = SKShapeNode(rectOf: CGSize(width: costBtnWidth, height: costBtnHeight), cornerRadius: costBtnHeight / 2)
            maxBadge.fillColor = SKColor(hex: GameConfig.UI.secondaryColor).withAlphaComponent(0.2)
            maxBadge.strokeColor = SKColor(hex: GameConfig.UI.secondaryColor).withAlphaComponent(0.5)
            maxBadge.lineWidth = 1
            maxBadge.position = CGPoint(x: width / 2 - 52, y: 0)
            addChild(maxBadge)

            let maxLabel = SKLabelNode.styled(text: "MAX", fontSize: 13, color: SKColor(hex: GameConfig.UI.secondaryColor))
            maxBadge.addChild(maxLabel)
        } else {
            let costBtn = SKShapeNode(rectOf: CGSize(width: costBtnWidth, height: costBtnHeight), cornerRadius: costBtnHeight / 2)
            costBtn.fillColor = canAfford ? SKColor(hex: "#4CAF50") : SKColor.white.withAlphaComponent(0.08)
            costBtn.strokeColor = canAfford ? SKColor(hex: "#81C784").withAlphaComponent(0.5) : SKColor.white.withAlphaComponent(0.15)
            costBtn.lineWidth = 1
            costBtn.position = CGPoint(x: width / 2 - 52, y: 0)
            addChild(costBtn)

            // Small coin icon in button
            let miniCoin = SKShapeNode(circleOfRadius: 5)
            miniCoin.fillColor = SKColor(hex: "#FFD700")
            miniCoin.strokeColor = .clear
            miniCoin.position = CGPoint(x: -18, y: 0)
            costBtn.addChild(miniCoin)

            let costLabel = SKLabelNode.styled(
                text: cost.abbreviated,
                fontSize: 12,
                fontName: GameConfig.UI.fontName,
                color: canAfford ? .white : SKColor.white.withAlphaComponent(0.4)
            )
            costLabel.horizontalAlignmentMode = .left
            costLabel.position = CGPoint(x: -10, y: -4)
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
    private var fillColor: SKColor!
    private let barWidth: CGFloat = 180
    private let barHeight: CGFloat = 8

    init(label: String, value: CGFloat, color: SKColor) {
        super.init()
        self.fillColor = color

        // Label
        let lbl = SKLabelNode.styled(
            text: label,
            fontSize: 10,
            fontName: GameConfig.UI.fontNameRegular,
            color: SKColor.white.withAlphaComponent(0.5)
        )
        lbl.horizontalAlignmentMode = .right
        lbl.position = CGPoint(x: -barWidth / 2 - 12, y: -4)
        addChild(lbl)

        // Background bar
        let bg = SKShapeNode(rectOf: CGSize(width: barWidth, height: barHeight), cornerRadius: barHeight / 2)
        bg.fillColor = SKColor.white.withAlphaComponent(0.08)
        bg.strokeColor = .clear
        addChild(bg)

        // Fill bar
        let fillW = max(1, barWidth * value.clamped(to: 0...1))
        fillNode = SKShapeNode(rectOf: CGSize(width: fillW, height: barHeight - 2), cornerRadius: (barHeight - 2) / 2)
        fillNode.fillColor = color
        fillNode.strokeColor = .clear
        fillNode.position.x = -(barWidth - fillW) / 2
        addChild(fillNode)

        // Percentage label
        let pctLabel = SKLabelNode.styled(
            text: "\(Int(value * 100))%",
            fontSize: 9,
            fontName: GameConfig.UI.fontNameRegular,
            color: SKColor.white.withAlphaComponent(0.4)
        )
        pctLabel.horizontalAlignmentMode = .left
        pctLabel.position = CGPoint(x: barWidth / 2 + 8, y: -4)
        addChild(pctLabel)
        pctLabel.name = "pctLabel"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    func setValue(_ value: CGFloat) {
        let fillW = max(1, barWidth * value.clamped(to: 0...1))
        let previousColor = fillNode.fillColor
        fillNode.removeFromParent()
        fillNode = SKShapeNode(rectOf: CGSize(width: fillW, height: barHeight - 2), cornerRadius: (barHeight - 2) / 2)
        fillNode.fillColor = previousColor
        fillNode.strokeColor = .clear
        fillNode.position.x = -(barWidth - fillW) / 2
        addChild(fillNode)

        // Update percentage
        if let pctLabel = childNode(withName: "pctLabel") as? SKLabelNode {
            pctLabel.text = "\(Int(value * 100))%"
        }
    }
}
