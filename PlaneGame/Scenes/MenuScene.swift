import SpriteKit

// MARK: - MenuScene

final class MenuScene: SKScene {

    // MARK: - Nodes

    private var titleLabel: SKLabelNode!
    private var playButton: SKShapeNode!
    private var upgradeButton: SKShapeNode!
    private var settingsButton: SKShapeNode!
    private var dailyChallengeButton: SKShapeNode!
    private var coinLabel: SKLabelNode!
    private var levelLabel: SKLabelNode!
    private var bestDistanceLabel: SKLabelNode!
    private var settingsOverlay: SKNode?

    // Decorative
    private var backgroundPlane: PlaneNode?
    private var cloudNodes: [SKShapeNode] = []

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(hex: GameConfig.UI.backgroundColor)
        buildUI()
        animateEntrance()
        AudioManager.shared.playBackgroundMusic()
    }

    // MARK: - Build UI

    private func buildUI() {
        let progress = GameManager.shared.progress

        // Decorative clouds in background
        buildBackgroundClouds()

        // Title
        titleLabel = SKLabelNode.styled(
            text: "PLANE GAME",
            fontSize: GameConfig.UI.titleFontSize,
            color: .white
        )
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.82)
        addChild(titleLabel)

        // Subtitle with plane stage
        let stageLabel = SKLabelNode.styled(
            text: progress.plane.currentStage.displayName,
            fontSize: GameConfig.UI.bodyFontSize,
            fontName: GameConfig.UI.fontNameRegular,
            color: SKColor(hex: GameConfig.UI.secondaryColor)
        )
        stageLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.77)
        addChild(stageLabel)

        // Coin display
        coinLabel = SKLabelNode.styled(
            text: "\(progress.coins.formattedWithCommas) coins",
            fontSize: GameConfig.UI.hudFontSize,
            fontName: GameConfig.UI.fontNameRegular,
            color: SKColor(hex: "#FFD700")
        )
        coinLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.72)
        addChild(coinLabel)

        // Level display
        levelLabel = SKLabelNode.styled(
            text: "Level \(progress.level)",
            fontSize: GameConfig.UI.bodyFontSize,
            fontName: GameConfig.UI.fontNameRegular,
            color: .lightGray
        )
        levelLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.68)
        addChild(levelLabel)

        // Best distance
        bestDistanceLabel = SKLabelNode.styled(
            text: "Best: \(Int(progress.bestDistance))m",
            fontSize: GameConfig.UI.bodyFontSize,
            fontName: GameConfig.UI.fontNameRegular,
            color: .lightGray
        )
        bestDistanceLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.64)
        addChild(bestDistanceLabel)

        // Decorative plane
        let plane = PlaneNode(model: progress.plane)
        plane.position = CGPoint(x: size.width / 2, y: size.height * 0.50)
        plane.setScale(1.5)
        addChild(plane)
        backgroundPlane = plane
        plane.pulseForever(scale: 1.55, duration: 2.0)

        // Play Button
        playButton = createButton(
            text: "PLAY",
            color: SKColor(hex: GameConfig.UI.accentColor),
            width: 200,
            height: 60
        )
        playButton.position = CGPoint(x: size.width / 2, y: size.height * 0.32)
        playButton.name = "playButton"
        addChild(playButton)

        // Upgrade Button
        upgradeButton = createButton(
            text: "UPGRADES",
            color: SKColor(hex: GameConfig.UI.primaryColor),
            width: 200,
            height: 50
        )
        upgradeButton.position = CGPoint(x: size.width / 2, y: size.height * 0.22)
        upgradeButton.name = "upgradeButton"
        addChild(upgradeButton)

        // Daily Challenge Button (if available)
        if GameManager.shared.progressionSystem.isDailyChallengeAvailable {
            dailyChallengeButton = createButton(
                text: "DAILY CHALLENGE",
                color: SKColor(hex: GameConfig.UI.secondaryColor),
                width: 200,
                height: 44
            )
            dailyChallengeButton.position = CGPoint(x: size.width / 2, y: size.height * 0.14)
            dailyChallengeButton.name = "dailyButton"
            dailyChallengeButton.pulseForever()
            addChild(dailyChallengeButton)
        }

        // Settings gear (top-right)
        settingsButton = SKShapeNode(circleOfRadius: 22)
        settingsButton.fillColor = SKColor.white.withAlphaComponent(0.15)
        settingsButton.strokeColor = .white
        settingsButton.lineWidth = 1.5
        settingsButton.position = CGPoint(x: size.width - 40, y: size.height - 50)
        settingsButton.name = "settingsButton"

        let gearLabel = SKLabelNode.styled(text: "S", fontSize: 18, color: .white)
        settingsButton.addChild(gearLabel)
        addChild(settingsButton)
    }

    private func buildBackgroundClouds() {
        for _ in 0..<6 {
            let cloud = SKShapeNode(ellipseOf: CGSize(
                width: CGFloat.random(in: 60...140),
                height: CGFloat.random(in: 25...50)
            ))
            cloud.fillColor = SKColor.white.withAlphaComponent(CGFloat.random(in: 0.03...0.08))
            cloud.strokeColor = .clear
            cloud.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: size.height * 0.3...size.height * 0.95)
            )
            cloud.zPosition = -10
            addChild(cloud)
            cloudNodes.append(cloud)

            // Slow drift
            let drift = SKAction.moveBy(x: CGFloat.random(in: -20...20), y: 0, duration: CGFloat.random(in: 4...8))
            let driftBack = drift.reversed()
            cloud.run(SKAction.repeatForever(SKAction.sequence([drift, driftBack])))
        }
    }

    // MARK: - Button Factory

    private func createButton(text: String, color: SKColor, width: CGFloat, height: CGFloat) -> SKShapeNode {
        let button = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: height / 2)
        button.fillColor = color
        button.strokeColor = color.withAlphaComponent(0.5)
        button.lineWidth = 2

        let label = SKLabelNode.styled(text: text, fontSize: height * 0.38, color: .white)
        label.name = nil // so touches pass through to button
        button.addChild(label)

        return button
    }

    // MARK: - Animation

    private func animateEntrance() {
        let nodes: [SKNode] = [titleLabel, coinLabel, playButton, upgradeButton].compactMap { $0 }
        for (i, node) in nodes.enumerated() {
            node.alpha = 0
            node.position.y -= 20
            let delay = SKAction.wait(forDuration: Double(i) * 0.1)
            let fadeIn = SKAction.fadeIn(withDuration: 0.3)
            let moveUp = SKAction.moveBy(x: 0, y: 20, duration: 0.3)
            let group = SKAction.group([fadeIn, moveUp])
            group.timingMode = .easeOut
            node.run(SKAction.sequence([delay, group]))
        }
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tapped = nodes(at: location)

        for node in tapped {
            switch node.name ?? node.parent?.name {
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

            case "dailyButton":
                HapticsManager.shared.playButtonTap()
                AudioManager.shared.playSound(GameConfig.Audio.buttonSound)
                animateButtonPress(dailyChallengeButton) { [weak self] in
                    guard let self = self, let view = self.view else { return }
                    GameManager.shared.startGame(in: view)
                }

            case "settingsButton":
                HapticsManager.shared.playButtonTap()
                showSettings()

            default:
                break
            }
        }
    }

    private func animateButtonPress(_ button: SKShapeNode, completion: @escaping () -> Void) {
        let scaleDown = SKAction.scale(to: 0.92, duration: 0.08)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.08)
        button.run(SKAction.sequence([scaleDown, scaleUp, SKAction.run(completion)]))
    }

    // MARK: - Settings Overlay

    private func showSettings() {
        guard settingsOverlay == nil else { return }

        let overlay = SKNode()
        overlay.zPosition = GameConfig.ZPosition.overlay

        // Dim background
        let dim = SKShapeNode(rectOf: size)
        dim.fillColor = SKColor.black.withAlphaComponent(0.7)
        dim.strokeColor = .clear
        dim.position = CGPoint(x: size.width / 2, y: size.height / 2)
        dim.name = "settingsDim"
        overlay.addChild(dim)

        // Panel
        let panelSize = CGSize(width: 280, height: 320)
        let panel = SKShapeNode(rectOf: panelSize, cornerRadius: 20)
        panel.fillColor = SKColor(hex: "#2A2A4A")
        panel.strokeColor = SKColor.white.withAlphaComponent(0.2)
        panel.lineWidth = 1
        panel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.addChild(panel)

        // Title
        let title = SKLabelNode.styled(text: "SETTINGS", fontSize: 24, color: .white)
        title.position = CGPoint(x: 0, y: panelSize.height / 2 - 40)
        panel.addChild(title)

        // Sound toggle
        let soundBtn = createToggleButton(
            text: "Sound: \(AudioManager.shared.soundOn ? "ON" : "OFF")",
            y: 50,
            name: "toggleSound"
        )
        panel.addChild(soundBtn)

        // Music toggle
        let musicBtn = createToggleButton(
            text: "Music: \(AudioManager.shared.musicOn ? "ON" : "OFF")",
            y: 0,
            name: "toggleMusic"
        )
        panel.addChild(musicBtn)

        // Haptics toggle
        let hapticsBtn = createToggleButton(
            text: "Haptics: \(HapticsManager.shared.hapticsOn ? "ON" : "OFF")",
            y: -50,
            name: "toggleHaptics"
        )
        panel.addChild(hapticsBtn)

        // Close button
        let closeBtn = createButton(text: "CLOSE", color: SKColor(hex: GameConfig.UI.dangerColor),
                                     width: 120, height: 40)
        closeBtn.position = CGPoint(x: 0, y: -panelSize.height / 2 + 40)
        closeBtn.name = "closeSettings"
        panel.addChild(closeBtn)

        addChild(overlay)
        settingsOverlay = overlay

        overlay.alpha = 0
        overlay.run(SKAction.fadeIn(withDuration: 0.2))
    }

    private func createToggleButton(text: String, y: CGFloat, name: String) -> SKShapeNode {
        let btn = SKShapeNode(rectOf: CGSize(width: 220, height: 36), cornerRadius: 18)
        btn.fillColor = SKColor.white.withAlphaComponent(0.1)
        btn.strokeColor = SKColor.white.withAlphaComponent(0.3)
        btn.lineWidth = 1
        btn.position = CGPoint(x: 0, y: y)
        btn.name = name

        let label = SKLabelNode.styled(text: text, fontSize: 16, fontName: GameConfig.UI.fontNameRegular, color: .white)
        label.name = name
        btn.addChild(label)

        return btn
    }

    private func hideSettings() {
        settingsOverlay?.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.15),
            SKAction.removeFromParent()
        ]))
        settingsOverlay = nil
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, settingsOverlay != nil else { return }
        let location = touch.location(in: self)
        let tapped = nodes(at: location)

        for node in tapped {
            switch node.name {
            case "settingsDim":
                hideSettings()

            case "closeSettings":
                hideSettings()

            case "toggleSound":
                let on = AudioManager.shared.toggleSound()
                if let label = node.children.first as? SKLabelNode ?? (node as? SKLabelNode) {
                    label.text = "Sound: \(on ? "ON" : "OFF")"
                }

            case "toggleMusic":
                let on = AudioManager.shared.toggleMusic()
                if let label = node.children.first as? SKLabelNode ?? (node as? SKLabelNode) {
                    label.text = "Music: \(on ? "ON" : "OFF")"
                }

            case "toggleHaptics":
                let on = HapticsManager.shared.toggle()
                if let label = node.children.first as? SKLabelNode ?? (node as? SKLabelNode) {
                    label.text = "Haptics: \(on ? "ON" : "OFF")"
                }

            default:
                break
            }
        }
    }
}
