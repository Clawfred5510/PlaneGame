import SpriteKit

// MARK: - MenuScene

final class MenuScene: SKScene {

    // MARK: - Nodes

    private var titleLabel: SKLabelNode!
    private var titleShadow: SKLabelNode!
    private var playButton: SKShapeNode!
    private var upgradeButton: SKShapeNode!
    private var shopButton: SKShapeNode!
    private var settingsButton: SKShapeNode!
    private var dailyChallengeButton: SKShapeNode?
    private var coinLabel: SKLabelNode!
    private var gemLabel: SKLabelNode!
    private var levelBadge: SKNode!
    private var bestDistanceLabel: SKLabelNode!
    private var settingsOverlay: SKNode?

    // Decorative
    private var backgroundPlane: PlaneNode?
    private var cloudNodes: [SKShapeNode] = []
    private var mountainLayers: [SKNode] = []
    private var skyGradientTop: SKShapeNode!
    private var skyGradientBottom: SKShapeNode!

    // Animation
    private var planePathTime: CGFloat = 0

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(hex: "#0F1B2E")
        buildBackground()
        buildUI()
        animateEntrance()
        AudioManager.shared.playBackgroundMusic()
    }

    override func update(_ currentTime: TimeInterval) {
        updateDecorativePlane()
    }

    // MARK: - Background

    private func buildBackground() {
        buildSkyGradient()
        buildParallaxMountains()
        buildDriftingClouds()
    }

    private func buildSkyGradient() {
        // Bottom gradient layer (horizon glow)
        skyGradientBottom = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height * 0.6))
        skyGradientBottom.fillColor = SKColor(hex: "#1A2744")
        skyGradientBottom.strokeColor = .clear
        skyGradientBottom.position = CGPoint(x: size.width / 2, y: size.height * 0.3)
        skyGradientBottom.zPosition = GameConfig.ZPosition.background
        addChild(skyGradientBottom)

        // Top gradient layer (deep sky)
        skyGradientTop = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height * 0.5))
        skyGradientTop.fillColor = SKColor(hex: "#0D1520")
        skyGradientTop.strokeColor = .clear
        skyGradientTop.position = CGPoint(x: size.width / 2, y: size.height * 0.75)
        skyGradientTop.zPosition = GameConfig.ZPosition.background
        addChild(skyGradientTop)

        // Horizon glow line
        let horizonGlow = SKShapeNode(rectOf: CGSize(width: size.width, height: 3))
        horizonGlow.fillColor = SKColor(hex: "#FF8C42").withAlphaComponent(0.3)
        horizonGlow.strokeColor = .clear
        horizonGlow.position = CGPoint(x: size.width / 2, y: size.height * 0.18)
        horizonGlow.zPosition = GameConfig.ZPosition.background + 1
        addChild(horizonGlow)

        // Subtle animated gradient pulse
        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.15, duration: 3.0),
            SKAction.fadeAlpha(to: 0.3, duration: 3.0)
        ])
        horizonGlow.run(SKAction.repeatForever(pulse))
    }

    private func buildParallaxMountains() {
        // Far mountains (darker, slower)
        let farMountains = createMountainLayer(
            yBase: size.height * 0.15,
            peakHeight: size.height * 0.22,
            color: SKColor(hex: "#1A2744").withAlphaComponent(0.8),
            segmentCount: 8,
            driftSpeed: 0.3
        )
        farMountains.zPosition = GameConfig.ZPosition.parallaxFar
        addChild(farMountains)
        mountainLayers.append(farMountains)

        // Near mountains (lighter, faster)
        let nearMountains = createMountainLayer(
            yBase: size.height * 0.1,
            peakHeight: size.height * 0.16,
            color: SKColor(hex: "#162038").withAlphaComponent(0.9),
            segmentCount: 6,
            driftSpeed: 0.6
        )
        nearMountains.zPosition = GameConfig.ZPosition.parallaxMid
        addChild(nearMountains)
        mountainLayers.append(nearMountains)

        // Closest hills
        let hills = createMountainLayer(
            yBase: size.height * 0.05,
            peakHeight: size.height * 0.1,
            color: SKColor(hex: "#0E1628"),
            segmentCount: 10,
            driftSpeed: 1.0
        )
        hills.zPosition = GameConfig.ZPosition.parallaxNear
        addChild(hills)
        mountainLayers.append(hills)
    }

    private func createMountainLayer(yBase: CGFloat, peakHeight: CGFloat, color: SKColor,
                                      segmentCount: Int, driftSpeed: CGFloat) -> SKNode {
        let container = SKNode()
        let segWidth = size.width / CGFloat(segmentCount - 1)

        let path = CGMutablePath()
        path.move(to: CGPoint(x: -size.width * 0.1, y: 0))

        for i in 0..<segmentCount {
            let x = CGFloat(i) * segWidth - size.width * 0.1
            let peakY = CGFloat.random(in: peakHeight * 0.4...peakHeight)
            let cpX = x + segWidth * 0.5
            let cpY = CGFloat.random(in: peakHeight * 0.2...peakHeight * 0.7)
            path.addQuadCurve(to: CGPoint(x: x + segWidth, y: CGFloat.random(in: 0...peakHeight * 0.3)),
                              control: CGPoint(x: cpX, y: peakY))
        }
        path.addLine(to: CGPoint(x: size.width * 1.1, y: 0))
        path.closeSubpath()

        let mountainShape = SKShapeNode(path: path)
        mountainShape.fillColor = color
        mountainShape.strokeColor = .clear
        mountainShape.position = CGPoint(x: 0, y: yBase)
        container.addChild(mountainShape)

        // Gentle drift animation
        let driftAmount: CGFloat = 8 * driftSpeed
        let drift = SKAction.sequence([
            SKAction.moveBy(x: driftAmount, y: 0, duration: 6.0 / Double(driftSpeed)),
            SKAction.moveBy(x: -driftAmount, y: 0, duration: 6.0 / Double(driftSpeed))
        ])
        drift.timingMode = .easeInEaseOut
        container.run(SKAction.repeatForever(drift))

        return container
    }

    private func buildDriftingClouds() {
        for _ in 0..<8 {
            let cloudWidth = CGFloat.random(in: 80...200)
            let cloudHeight = CGFloat.random(in: 20...50)

            let cloud = SKShapeNode(ellipseOf: CGSize(width: cloudWidth, height: cloudHeight))
            cloud.fillColor = SKColor.white.withAlphaComponent(CGFloat.random(in: 0.02...0.06))
            cloud.strokeColor = .clear
            cloud.position = CGPoint(
                x: CGFloat.random(in: -50...(size.width + 50)),
                y: CGFloat.random(in: size.height * 0.35...size.height * 0.92)
            )
            cloud.zPosition = GameConfig.ZPosition.parallaxFar + 1
            addChild(cloud)
            cloudNodes.append(cloud)

            // Continuous drift across screen
            let speed = CGFloat.random(in: 15...40)
            let duration = Double((size.width + cloudWidth + 100) / speed)

            let moveRight = SKAction.moveBy(x: size.width + cloudWidth + 100, y: 0, duration: duration)
            let reset = SKAction.moveBy(x: -(size.width + cloudWidth + 100), y: 0, duration: 0)
            cloud.run(SKAction.repeatForever(SKAction.sequence([moveRight, reset])))
        }
    }

    // MARK: - Build UI

    private func buildUI() {
        let progress = GameManager.shared.progress

        buildCurrencyBar(progress: progress)
        buildLevelBadge(progress: progress)
        buildTitle()
        buildBestDistance(progress: progress)
        buildDecorativePlane(progress: progress)
        buildButtons()
        buildDailyChallenge()
        buildSettingsGear()
    }

    private func buildCurrencyBar(progress: PlayerProgress) {
        let barY = size.height - 45

        // Coin icon
        let coinIcon = SKShapeNode(circleOfRadius: 11)
        coinIcon.fillColor = SKColor(hex: "#FFD700")
        coinIcon.strokeColor = SKColor(hex: "#FFA000")
        coinIcon.lineWidth = 1.5
        coinIcon.position = CGPoint(x: 30, y: barY)
        coinIcon.zPosition = GameConfig.ZPosition.hud
        addChild(coinIcon)

        let coinSymbol = SKLabelNode.styled(text: "$", fontSize: 12, color: SKColor(hex: "#B8860B"))
        coinIcon.addChild(coinSymbol)

        // Coin count
        coinLabel = SKLabelNode.styled(
            text: progress.coins.formattedWithCommas,
            fontSize: 18,
            fontName: GameConfig.UI.fontName,
            color: SKColor(hex: "#FFD700")
        )
        coinLabel.horizontalAlignmentMode = .left
        coinLabel.position = CGPoint(x: 48, y: barY - 6)
        coinLabel.zPosition = GameConfig.ZPosition.hud
        addChild(coinLabel)

        // Gem icon
        let gemIcon = SKShapeNode(rectOf: CGSize(width: 16, height: 16), cornerRadius: 3)
        gemIcon.fillColor = SKColor(hex: "#9C27B0")
        gemIcon.strokeColor = SKColor(hex: "#7B1FA2")
        gemIcon.lineWidth = 1.5
        gemIcon.zRotation = degreesToRadians(45)
        gemIcon.position = CGPoint(x: 130, y: barY)
        gemIcon.zPosition = GameConfig.ZPosition.hud
        addChild(gemIcon)

        // Gem count
        gemLabel = SKLabelNode.styled(
            text: "\(progress.gems)",
            fontSize: 18,
            fontName: GameConfig.UI.fontName,
            color: SKColor(hex: "#CE93D8")
        )
        gemLabel.horizontalAlignmentMode = .left
        gemLabel.position = CGPoint(x: 148, y: barY - 6)
        gemLabel.zPosition = GameConfig.ZPosition.hud
        addChild(gemLabel)
    }

    private func buildLevelBadge(progress: PlayerProgress) {
        levelBadge = SKNode()
        levelBadge.position = CGPoint(x: size.width / 2, y: size.height - 45)
        levelBadge.zPosition = GameConfig.ZPosition.hud

        // Circular badge background
        let badgeBg = SKShapeNode(circleOfRadius: 20)
        badgeBg.fillColor = SKColor(hex: GameConfig.UI.primaryColor)
        badgeBg.strokeColor = SKColor.white.withAlphaComponent(0.4)
        badgeBg.lineWidth = 2
        levelBadge.addChild(badgeBg)

        // Level number
        let lvlNum = SKLabelNode.styled(text: "\(progress.level)", fontSize: 16, color: .white)
        levelBadge.addChild(lvlNum)

        // "LV" text above badge
        let lvlText = SKLabelNode.styled(text: "LV", fontSize: 9, fontName: GameConfig.UI.fontNameRegular, color: .white)
        lvlText.position = CGPoint(x: 0, y: 26)
        levelBadge.addChild(lvlText)

        addChild(levelBadge)
    }

    private func buildTitle() {
        // Shadow
        titleShadow = SKLabelNode.styled(
            text: "PLANE GAME",
            fontSize: GameConfig.UI.titleFontSize + 2,
            color: SKColor.black.withAlphaComponent(0.4)
        )
        titleShadow.position = CGPoint(x: size.width / 2 + 2, y: size.height * 0.78 - 2)
        titleShadow.zPosition = GameConfig.ZPosition.hud - 1
        addChild(titleShadow)

        // Main title
        titleLabel = SKLabelNode.styled(
            text: "PLANE GAME",
            fontSize: GameConfig.UI.titleFontSize + 2,
            color: .white
        )
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.78)
        titleLabel.zPosition = GameConfig.ZPosition.hud
        addChild(titleLabel)

        // Subtle float animation for title
        let floatUp = SKAction.moveBy(x: 0, y: 6, duration: 2.0)
        let floatDown = SKAction.moveBy(x: 0, y: -6, duration: 2.0)
        floatUp.timingMode = .easeInEaseOut
        floatDown.timingMode = .easeInEaseOut
        let floatSeq = SKAction.repeatForever(SKAction.sequence([floatUp, floatDown]))
        titleLabel.run(floatSeq)
        titleShadow.run(floatSeq)
    }

    private func buildBestDistance(progress: PlayerProgress) {
        bestDistanceLabel = SKLabelNode.styled(
            text: "Best: \(Int(progress.bestDistance))m",
            fontSize: 16,
            fontName: GameConfig.UI.fontNameRegular,
            color: SKColor.white.withAlphaComponent(0.5)
        )
        bestDistanceLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.73)
        bestDistanceLabel.zPosition = GameConfig.ZPosition.hud
        addChild(bestDistanceLabel)
    }

    private func buildDecorativePlane(progress: PlayerProgress) {
        let plane = PlaneNode(model: progress.plane)
        plane.position = CGPoint(x: size.width * 0.3, y: size.height * 0.55)
        plane.setScale(1.8)
        plane.zPosition = GameConfig.ZPosition.plane
        addChild(plane)
        backgroundPlane = plane

        // Start exhaust trail for visual appeal
        plane.launch(with: CGVector(dx: 0.01, dy: 0.01))
    }

    private func updateDecorativePlane() {
        guard let plane = backgroundPlane else { return }

        // Gentle figure-8 / loop pattern
        planePathTime += 0.008

        let centerX = size.width * 0.5
        let centerY = size.height * 0.52
        let radiusX: CGFloat = size.width * 0.25
        let radiusY: CGFloat = size.height * 0.08

        let x = centerX + radiusX * cos(planePathTime)
        let y = centerY + radiusY * sin(planePathTime * 2)
        plane.position = CGPoint(x: x, y: y)

        // Rotate plane to face movement direction
        let nextX = centerX + radiusX * cos(planePathTime + 0.01)
        let nextY = centerY + radiusY * sin((planePathTime + 0.01) * 2)
        let angle = atan2(nextY - y, nextX - x)
        plane.zRotation = angle
    }

    private func buildButtons() {
        // PLAY button - large, vibrant green, centered
        playButton = createMenuButton(
            text: "PLAY",
            color: SKColor(hex: "#4CAF50"),
            glowColor: SKColor(hex: "#81C784"),
            width: 220,
            height: 62,
            fontSize: 26
        )
        playButton.position = CGPoint(x: size.width / 2, y: size.height * 0.32)
        playButton.name = "playButton"
        playButton.zPosition = GameConfig.ZPosition.hud
        addChild(playButton)

        // Pulsing glow effect on play button
        let glowNode = SKShapeNode(rectOf: CGSize(width: 224, height: 66), cornerRadius: 33)
        glowNode.fillColor = .clear
        glowNode.strokeColor = SKColor(hex: "#81C784").withAlphaComponent(0.4)
        glowNode.lineWidth = 3
        glowNode.glowWidth = 8
        glowNode.zPosition = -1
        playButton.addChild(glowNode)

        let glowPulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.2, duration: 0.8),
            SKAction.fadeAlpha(to: 0.6, duration: 0.8)
        ])
        glowNode.run(SKAction.repeatForever(glowPulse))

        // UPGRADES button
        upgradeButton = createMenuButton(
            text: "UPGRADES",
            color: SKColor(hex: "#2196F3"),
            glowColor: nil,
            width: 200,
            height: 50,
            fontSize: 20
        )
        upgradeButton.position = CGPoint(x: size.width / 2, y: size.height * 0.22)
        upgradeButton.name = "upgradeButton"
        upgradeButton.zPosition = GameConfig.ZPosition.hud
        addChild(upgradeButton)

        // SHOP button
        shopButton = createMenuButton(
            text: "SHOP",
            color: SKColor(hex: "#9C27B0"),
            glowColor: nil,
            width: 200,
            height: 50,
            fontSize: 20
        )
        shopButton.position = CGPoint(x: size.width / 2, y: size.height * 0.13)
        shopButton.name = "shopButton"
        shopButton.zPosition = GameConfig.ZPosition.hud
        addChild(shopButton)
    }

    private func buildDailyChallenge() {
        guard GameManager.shared.progressionSystem.isDailyChallengeAvailable else { return }

        let bannerWidth: CGFloat = 260
        let bannerHeight: CGFloat = 48

        let banner = SKShapeNode(rectOf: CGSize(width: bannerWidth, height: bannerHeight), cornerRadius: bannerHeight / 2)
        banner.fillColor = SKColor(hex: "#FF6F00")
        banner.strokeColor = SKColor(hex: "#FFA726").withAlphaComponent(0.6)
        banner.lineWidth = 2
        banner.glowWidth = 4
        banner.position = CGPoint(x: size.width / 2, y: size.height * 0.42)
        banner.name = "dailyButton"
        banner.zPosition = GameConfig.ZPosition.hud

        let challengeLabel = SKLabelNode.styled(
            text: "DAILY CHALLENGE",
            fontSize: 16,
            color: .white
        )
        challengeLabel.position = CGPoint(x: -20, y: -6)
        banner.addChild(challengeLabel)

        // Reward preview
        let rewardLabel = SKLabelNode.styled(
            text: "+\(GameConfig.DailyChallenge.rewardCoins)",
            fontSize: 13,
            fontName: GameConfig.UI.fontNameRegular,
            color: SKColor(hex: "#FFD700")
        )
        rewardLabel.position = CGPoint(x: bannerWidth / 2 - 45, y: -5)
        rewardLabel.horizontalAlignmentMode = .center
        banner.addChild(rewardLabel)

        // Subtle glow pulse
        let pulse = SKAction.sequence([
            SKAction.run { banner.glowWidth = 8 },
            SKAction.wait(forDuration: 0.6),
            SKAction.run { banner.glowWidth = 4 },
            SKAction.wait(forDuration: 0.6)
        ])
        banner.run(SKAction.repeatForever(pulse))

        addChild(banner)
        dailyChallengeButton = banner
    }

    private func buildSettingsGear() {
        settingsButton = SKShapeNode(circleOfRadius: 22)
        settingsButton.fillColor = SKColor.white.withAlphaComponent(0.1)
        settingsButton.strokeColor = SKColor.white.withAlphaComponent(0.3)
        settingsButton.lineWidth = 1.5
        settingsButton.position = CGPoint(x: size.width - 38, y: size.height - 45)
        settingsButton.name = "settingsButton"
        settingsButton.zPosition = GameConfig.ZPosition.hud

        // Gear icon using a simple shape
        let gearIcon = SKLabelNode.styled(text: "\u{2699}", fontSize: 22, color: .white)
        gearIcon.position = CGPoint(x: 0, y: -1)
        settingsButton.addChild(gearIcon)

        addChild(settingsButton)
    }

    // MARK: - Button Factory

    private func createMenuButton(text: String, color: SKColor, glowColor: SKColor?,
                                   width: CGFloat, height: CGFloat, fontSize: CGFloat) -> SKShapeNode {
        let button = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: height / 2)
        button.fillColor = color
        button.strokeColor = color.withAlphaComponent(0.3)
        button.lineWidth = 2

        let label = SKLabelNode.styled(text: text, fontSize: fontSize, color: .white)
        label.name = nil
        button.addChild(label)

        return button
    }

    // MARK: - Entrance Animation

    private func animateEntrance() {
        // Title slides down from top
        titleLabel.alpha = 0
        titleLabel.position.y += 40
        titleShadow.alpha = 0
        titleShadow.position.y += 40

        let titleDelay = SKAction.wait(forDuration: 0.1)
        let titleFade = SKAction.fadeIn(withDuration: 0.4)
        let titleSlide = SKAction.moveBy(x: 0, y: -40, duration: 0.4)
        titleSlide.timingMode = .easeOut
        let titleGroup = SKAction.group([titleFade, titleSlide])
        titleLabel.run(SKAction.sequence([titleDelay, titleGroup]))
        titleShadow.run(SKAction.sequence([titleDelay, titleGroup]))

        // Best distance fades in
        bestDistanceLabel.alpha = 0
        bestDistanceLabel.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.3),
            SKAction.fadeIn(withDuration: 0.3)
        ]))

        // Buttons slide up from bottom with stagger
        let buttons: [SKNode?] = [playButton, upgradeButton, shopButton, dailyChallengeButton]
        for (i, button) in buttons.compactMap({ $0 }).enumerated() {
            button.alpha = 0
            button.position.y -= 30
            let delay = SKAction.wait(forDuration: 0.3 + Double(i) * 0.08)
            let fade = SKAction.fadeIn(withDuration: 0.35)
            let slide = SKAction.moveBy(x: 0, y: 30, duration: 0.35)
            slide.timingMode = .easeOut
            let group = SKAction.group([fade, slide])
            button.run(SKAction.sequence([delay, group]))
        }

        // Currency bar slides in from left
        coinLabel.alpha = 0
        coinLabel.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.2),
            SKAction.fadeIn(withDuration: 0.3)
        ]))

        gemLabel.alpha = 0
        gemLabel.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.25),
            SKAction.fadeIn(withDuration: 0.3)
        ]))

        // Level badge scales in
        levelBadge.setScale(0)
        levelBadge.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.4),
            SKAction.scale(to: 1.0, duration: 0.3)
        ]))

        // Settings gear fades in
        settingsButton.alpha = 0
        settingsButton.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.fadeIn(withDuration: 0.3)
        ]))
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        // If settings overlay is showing, handle it separately
        if settingsOverlay != nil {
            handleSettingsTouch(location)
            return
        }

        let tapped = nodes(at: location)

        for node in tapped {
            let name = node.name ?? node.parent?.name
            switch name {
            case "playButton":
                HapticsManager.shared.playButtonTap()
                AudioManager.shared.playSound(GameConfig.Audio.buttonSound)
                animateButtonPress(playButton) { [weak self] in
                    guard let self = self, let view = self.view else { return }
                    GameManager.shared.startGame(in: view)
                }

            case "upgradeButton":
                HapticsManager.shared.playButtonTap()
                AudioManager.shared.playSound(GameConfig.Audio.buttonSound)
                animateButtonPress(upgradeButton) { [weak self] in
                    guard let self = self, let view = self.view else { return }
                    GameManager.shared.openUpgrades(in: view)
                }

            case "shopButton":
                HapticsManager.shared.playButtonTap()
                AudioManager.shared.playSound(GameConfig.Audio.buttonSound)
                animateButtonPress(shopButton) { [weak self] in
                    // Shop scene transition (uses same upgrade for now)
                    guard let self = self, let view = self.view else { return }
                    GameManager.shared.openUpgrades(in: view)
                }

            case "dailyButton":
                HapticsManager.shared.playButtonTap()
                AudioManager.shared.playSound(GameConfig.Audio.buttonSound)
                if let btn = dailyChallengeButton {
                    animateButtonPress(btn) { [weak self] in
                        guard let self = self, let view = self.view else { return }
                        GameManager.shared.startGame(in: view)
                    }
                }

            case "settingsButton":
                HapticsManager.shared.playButtonTap()
                AudioManager.shared.playSound(GameConfig.Audio.buttonSound)
                showSettings()

            default:
                break
            }
        }
    }

    private func animateButtonPress(_ button: SKShapeNode, completion: @escaping () -> Void) {
        let scaleDown = SKAction.scale(to: 0.92, duration: 0.06)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.06)
        scaleDown.timingMode = .easeIn
        scaleUp.timingMode = .easeOut
        button.run(SKAction.sequence([scaleDown, scaleUp, SKAction.run(completion)]))
    }

    // MARK: - Settings Overlay

    private func showSettings() {
        guard settingsOverlay == nil else { return }

        let overlay = SKNode()
        overlay.zPosition = GameConfig.ZPosition.overlay

        // Dark backdrop
        let dim = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: size.height * 2))
        dim.fillColor = SKColor.black.withAlphaComponent(0.75)
        dim.strokeColor = .clear
        dim.position = CGPoint(x: size.width / 2, y: size.height / 2)
        dim.name = "settingsDim"
        overlay.addChild(dim)

        // Card panel
        let panelWidth: CGFloat = 300
        let panelHeight: CGFloat = 340
        let panel = SKShapeNode(rectOf: CGSize(width: panelWidth, height: panelHeight), cornerRadius: 24)
        panel.fillColor = SKColor(hex: "#1E2A45")
        panel.strokeColor = SKColor.white.withAlphaComponent(0.15)
        panel.lineWidth = 1
        panel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.addChild(panel)

        // Panel header
        let headerTitle = SKLabelNode.styled(text: "SETTINGS", fontSize: 26, color: .white)
        headerTitle.position = CGPoint(x: 0, y: panelHeight / 2 - 42)
        panel.addChild(headerTitle)

        // Divider
        let divider = SKShapeNode(rectOf: CGSize(width: panelWidth - 40, height: 1))
        divider.fillColor = SKColor.white.withAlphaComponent(0.1)
        divider.strokeColor = .clear
        divider.position = CGPoint(x: 0, y: panelHeight / 2 - 65)
        panel.addChild(divider)

        // Toggle switches
        let soundToggle = createToggleRow(
            label: "Sound",
            isOn: AudioManager.shared.soundOn,
            y: 55,
            name: "toggleSound"
        )
        panel.addChild(soundToggle)

        let musicToggle = createToggleRow(
            label: "Music",
            isOn: AudioManager.shared.musicOn,
            y: 0,
            name: "toggleMusic"
        )
        panel.addChild(musicToggle)

        let hapticsToggle = createToggleRow(
            label: "Haptics",
            isOn: HapticsManager.shared.hapticsOn,
            y: -55,
            name: "toggleHaptics"
        )
        panel.addChild(hapticsToggle)

        // Close button
        let closeBtn = SKShapeNode(rectOf: CGSize(width: 140, height: 44), cornerRadius: 22)
        closeBtn.fillColor = SKColor(hex: GameConfig.UI.dangerColor)
        closeBtn.strokeColor = .clear
        closeBtn.position = CGPoint(x: 0, y: -panelHeight / 2 + 45)
        closeBtn.name = "closeSettings"

        let closeLabel = SKLabelNode.styled(text: "CLOSE", fontSize: 16, color: .white)
        closeLabel.name = "closeSettings"
        closeBtn.addChild(closeLabel)
        panel.addChild(closeBtn)

        addChild(overlay)
        settingsOverlay = overlay

        // Animate in
        overlay.alpha = 0
        panel.setScale(0.85)
        let fadeIn = SKAction.fadeIn(withDuration: 0.2)
        let scaleIn = SKAction.scale(to: 1.0, duration: 0.2)
        scaleIn.timingMode = .easeOut
        overlay.run(fadeIn)
        panel.run(scaleIn)
    }

    private func createToggleRow(label: String, isOn: Bool, y: CGFloat, name: String) -> SKNode {
        let row = SKNode()
        row.position = CGPoint(x: 0, y: y)
        row.name = name

        // Label
        let textLabel = SKLabelNode.styled(
            text: label,
            fontSize: 18,
            fontName: GameConfig.UI.fontNameRegular,
            color: .white
        )
        textLabel.horizontalAlignmentMode = .left
        textLabel.position = CGPoint(x: -110, y: -6)
        textLabel.name = name
        row.addChild(textLabel)

        // Toggle switch background
        let toggleBg = SKShapeNode(rectOf: CGSize(width: 52, height: 28), cornerRadius: 14)
        toggleBg.fillColor = isOn ? SKColor(hex: "#4CAF50") : SKColor.white.withAlphaComponent(0.15)
        toggleBg.strokeColor = isOn ? SKColor(hex: "#81C784").withAlphaComponent(0.5) : SKColor.white.withAlphaComponent(0.2)
        toggleBg.lineWidth = 1
        toggleBg.position = CGPoint(x: 90, y: 0)
        toggleBg.name = name
        row.addChild(toggleBg)

        // Toggle knob
        let knob = SKShapeNode(circleOfRadius: 10)
        knob.fillColor = .white
        knob.strokeColor = .clear
        knob.position = CGPoint(x: isOn ? 12 : -12, y: 0)
        knob.name = name
        toggleBg.addChild(knob)

        // ON/OFF text
        let stateLabel = SKLabelNode.styled(
            text: isOn ? "ON" : "OFF",
            fontSize: 12,
            fontName: GameConfig.UI.fontNameRegular,
            color: isOn ? SKColor(hex: "#4CAF50") : .gray
        )
        stateLabel.position = CGPoint(x: 40, y: -5)
        stateLabel.horizontalAlignmentMode = .left
        stateLabel.name = name
        row.addChild(stateLabel)

        return row
    }

    private func handleSettingsTouch(_ location: CGPoint) {
        let tapped = nodes(at: location)

        for node in tapped {
            switch node.name {
            case "settingsDim", "closeSettings":
                hideSettings()
                return

            case "toggleSound":
                let on = AudioManager.shared.toggleSound()
                HapticsManager.shared.playButtonTap()
                hideSettings()
                run(SKAction.sequence([
                    SKAction.wait(forDuration: 0.25),
                    SKAction.run { [weak self] in self?.showSettings() }
                ]))

            case "toggleMusic":
                let on = AudioManager.shared.toggleMusic()
                HapticsManager.shared.playButtonTap()
                hideSettings()
                run(SKAction.sequence([
                    SKAction.wait(forDuration: 0.25),
                    SKAction.run { [weak self] in self?.showSettings() }
                ]))

            case "toggleHaptics":
                let on = HapticsManager.shared.toggle()
                HapticsManager.shared.playButtonTap()
                hideSettings()
                run(SKAction.sequence([
                    SKAction.wait(forDuration: 0.25),
                    SKAction.run { [weak self] in self?.showSettings() }
                ]))

            default:
                break
            }
        }
    }

    private func hideSettings() {
        guard let overlay = settingsOverlay else { return }
        let fadeOut = SKAction.fadeOut(withDuration: 0.15)
        overlay.run(SKAction.sequence([fadeOut, SKAction.removeFromParent()]))
        settingsOverlay = nil
    }
}
