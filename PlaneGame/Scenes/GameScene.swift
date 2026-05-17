import SpriteKit

// MARK: - GameScene

final class GameScene: SKScene {

    // MARK: - Properties

    private var gameState: GameState = .ready

    // Nodes
    private var planeNode: PlaneNode!
    private var slingshotNode: SlingshotNode!
    private var environmentNode: EnvironmentNode!
    private var cameraNode: SKCameraNode!
    private var trajectoryDots: [SKShapeNode] = []

    // Systems
    private var physicsSystem: PhysicsSystem!
    private var coinSystem: CoinSystem!
    private var progressionSystem: ProgressionSystem!
    private var obstacleNodes: [ObstacleNode] = []
    private var lastObstacleX: CGFloat = 0

    // HUD
    private var hudNode: SKNode!
    private var distanceLabel: SKLabelNode!
    private var coinCountLabel: SKLabelNode!
    private var altitudeLabel: SKLabelNode!
    private var boostIndicator: SKShapeNode!
    private var speedBar: SKShapeNode!
    private var speedBarFill: SKShapeNode!

    // Touch
    private var pitchInput: CGFloat = 0
    private var touchStartY: CGFloat = 0
    private var isTouchingForPitch = false

    // Distance
    private var launchX: CGFloat = 0
    private var distanceTraveled: CGFloat { max(0, planeNode.position.x - launchX) }

    // Results overlay
    private var resultsOverlay: SKNode?

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(hex: GameConfig.UI.backgroundColor)
        setupCamera()
        setupEnvironment()
        setupSlingshot()
        setupPlane()
        setupPhysics()
        setupSystems()
        setupHUD()
        gameState = .ready
    }

    // MARK: - Setup

    private func setupCamera() {
        cameraNode = SKCameraNode()
        addChild(cameraNode)
        camera = cameraNode
        cameraNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
    }

    private func setupEnvironment() {
        let progress = GameManager.shared.progress
        let envModel = EnvironmentModel(
            type: progress.selectedEnvironment,
            isUnlocked: true
        )
        environmentNode = EnvironmentNode(environment: envModel, screenSize: size)
        addChild(environmentNode)
    }

    private func setupSlingshot() {
        slingshotNode = SlingshotNode()
        slingshotNode.position = CGPoint(
            x: GameConfig.Slingshot.anchorOffset.x,
            y: GameConfig.Slingshot.anchorOffset.y
        )
        addChild(slingshotNode)
    }

    private func setupPlane() {
        let progress = GameManager.shared.progress
        planeNode = PlaneNode(model: progress.plane)
        planeNode.position = CGPoint(
            x: slingshotNode.position.x,
            y: slingshotNode.position.y + GameConfig.Slingshot.forkHeight
        )
        addChild(planeNode)
        launchX = planeNode.position.x
    }

    private func setupPhysics() {
        PhysicsSystem.configureWorld(for: self)
        physicsSystem = PhysicsSystem()
        physicsWorld.contactDelegate = physicsSystem

        physicsSystem.onCoinCollected = { [weak self] coin in
            self?.handleCoinCollected(coin)
        }
        physicsSystem.onPowerUpCollected = { [weak self] powerUp in
            self?.handlePowerUpCollected(powerUp)
        }
        physicsSystem.onObstacleHit = { [weak self] obstacle in
            self?.handleObstacleHit(obstacle)
        }
        physicsSystem.onGroundHit = { [weak self] speed in
            self?.handleGroundHit(speed: speed)
        }
    }

    private func setupSystems() {
        coinSystem = CoinSystem(scene: self)
        progressionSystem = GameManager.shared.progressionSystem
    }

    private func setupHUD() {
        hudNode = SKNode()
        hudNode.zPosition = GameConfig.ZPosition.hud
        cameraNode.addChild(hudNode)

        let hudY = size.height / 2 - GameConfig.UI.hudPadding - 15

        // Distance
        distanceLabel = SKLabelNode.styled(
            text: "0m",
            fontSize: GameConfig.UI.hudFontSize,
            color: .white
        )
        distanceLabel.horizontalAlignmentMode = .left
        distanceLabel.position = CGPoint(x: -size.width / 2 + GameConfig.UI.hudPadding, y: hudY)
        hudNode.addChild(distanceLabel)

        // Coins
        coinCountLabel = SKLabelNode.styled(
            text: "0",
            fontSize: GameConfig.UI.hudFontSize,
            color: SKColor(hex: "#FFD700")
        )
        coinCountLabel.horizontalAlignmentMode = .right
        coinCountLabel.position = CGPoint(x: size.width / 2 - GameConfig.UI.hudPadding, y: hudY)
        hudNode.addChild(coinCountLabel)

        // Coin icon
        let coinIcon = SKShapeNode(circleOfRadius: 8)
        coinIcon.fillColor = SKColor(hex: "#FFD700")
        coinIcon.strokeColor = SKColor(hex: "#FFA000")
        coinIcon.lineWidth = 1
        coinIcon.position = CGPoint(x: size.width / 2 - GameConfig.UI.hudPadding - 40, y: hudY)
        hudNode.addChild(coinIcon)

        // Altitude
        altitudeLabel = SKLabelNode.styled(
            text: "ALT: 0",
            fontSize: 16,
            fontName: GameConfig.UI.fontNameRegular,
            color: .lightGray
        )
        altitudeLabel.horizontalAlignmentMode = .left
        altitudeLabel.position = CGPoint(x: -size.width / 2 + GameConfig.UI.hudPadding, y: hudY - 28)
        hudNode.addChild(altitudeLabel)

        // Speed bar
        let barWidth: CGFloat = 100
        let barHeight: CGFloat = 8
        speedBar = SKShapeNode(rectOf: CGSize(width: barWidth, height: barHeight), cornerRadius: 4)
        speedBar.fillColor = SKColor.white.withAlphaComponent(0.2)
        speedBar.strokeColor = .clear
        speedBar.position = CGPoint(x: -size.width / 2 + GameConfig.UI.hudPadding + barWidth / 2, y: hudY - 52)
        hudNode.addChild(speedBar)

        speedBarFill = SKShapeNode(rectOf: CGSize(width: 1, height: barHeight - 2), cornerRadius: 3)
        speedBarFill.fillColor = SKColor(hex: GameConfig.UI.accentColor)
        speedBarFill.strokeColor = .clear
        speedBar.addChild(speedBarFill)

        // Boost indicator (hidden by default)
        boostIndicator = SKShapeNode(rectOf: CGSize(width: 80, height: 28), cornerRadius: 14)
        boostIndicator.fillColor = SKColor(hex: "#FF6B35").withAlphaComponent(0.8)
        boostIndicator.strokeColor = .clear
        boostIndicator.position = CGPoint(x: 0, y: hudY - 50)
        boostIndicator.isHidden = true

        let boostLabel = SKLabelNode.styled(text: "BOOST!", fontSize: 14, color: .white)
        boostIndicator.addChild(boostLabel)
        hudNode.addChild(boostIndicator)

        // Initial state: hide HUD until launched
        hudNode.alpha = 0
    }

    // MARK: - Update Loop

    override func update(_ currentTime: TimeInterval) {
        switch gameState {
        case .ready, .aiming:
            updateTrajectoryPreview()

        case .launched, .flying:
            updateFlight(currentTime)
            updateCamera()
            updateHUD()
            updateObstacles()
            coinSystem.update(
                cameraX: cameraNode.position.x,
                planeY: planeNode.position.y,
                distanceTraveled: distanceTraveled
            )
            coinSystem.applyMagnet(
                planePosition: planeNode.position,
                magnetRadius: planeNode.model.magnetRadius,
                hasMagnetPowerUp: planeNode.hasMagnet,
                dt: 1.0 / 60.0
            )
            progressionSystem.updateDistance(currentX: planeNode.position.x)
            environmentNode.update(cameraX: cameraNode.position.x)

            // Check if flying state (off slingshot and airborne)
            if gameState == .launched && planeNode.isFlying {
                gameState = .flying
            }

        default:
            break
        }
    }

    // MARK: - Flight

    private func updateFlight(_ currentTime: TimeInterval) {
        let dt = 1.0 / 60.0 // fixed timestep
        planeNode.updateFlight(dt: dt, pitchInput: pitchInput)

        // Check if plane has stopped or gone below ground
        if planeNode.position.y <= GameConfig.World.groundY + 5 &&
           planeNode.currentSpeed < 10 &&
           (gameState == .flying || gameState == .launched) {
            endFlight(smoothLanding: false)
        }
    }

    // MARK: - Camera

    private func updateCamera() {
        let targetX = planeNode.position.x + GameConfig.Camera.leadAheadX
        let targetY = max(
            size.height / 2,
            planeNode.position.y + GameConfig.Camera.leadAheadY
        )

        cameraNode.position.x = lerp(
            cameraNode.position.x, targetX, GameConfig.Camera.followSmoothing
        )
        cameraNode.position.y = lerp(
            cameraNode.position.y, targetY, GameConfig.Camera.followSmoothing * 0.5
        )
    }

    // MARK: - HUD

    private func updateHUD() {
        let dist = Int(distanceTraveled)
        distanceLabel.text = "\(dist)m"
        coinCountLabel.text = "\(coinSystem.coinsCollected)"

        let alt = max(0, Int(planeNode.position.y - GameConfig.World.groundY))
        altitudeLabel.text = "ALT: \(alt)"

        // Speed bar
        let speedFraction = (planeNode.currentSpeed / GameConfig.Plane.maxSpeed).clamped(to: 0...1)
        let barWidth: CGFloat = 96 * speedFraction
        speedBarFill.xScale = max(0.01, speedFraction)
        speedBarFill.position.x = -(96 - barWidth) / 2

        // Boost indicator
        boostIndicator.isHidden = !planeNode.hasBoost
    }

    // MARK: - Obstacles

    private func updateObstacles() {
        let cameraX = cameraNode.position.x
        let spawnX = cameraX + size.width

        // Spawn new obstacles
        if distanceTraveled > GameConfig.Obstacles.firstSpawnDistance {
            let threshold = lastObstacleX + CGFloat.random(
                in: GameConfig.Obstacles.minSpacing...GameConfig.Obstacles.maxSpacing
            )

            if spawnX > threshold {
                spawnObstacle(at: spawnX)
                lastObstacleX = spawnX
            }
        }

        // Despawn old obstacles
        let leftBound = cameraX + GameConfig.World.despawnOffsetX
        obstacleNodes.removeAll { node in
            if node.position.x < leftBound {
                node.removeFromParent()
                return true
            }
            return false
        }
    }

    private func spawnObstacle(at x: CGFloat) {
        let progress = GameManager.shared.progress
        let envModel = EnvironmentModel(type: progress.selectedEnvironment, isUnlocked: true)
        let kinds = envModel.obstacleTypes

        guard let kind = kinds.randomElement() else { return }

        let obstacle = ObstacleNode(kind: kind)

        let y: CGFloat
        if kind.isFlying {
            y = CGFloat.random(in: 200...600)
        } else {
            y = GameConfig.World.groundY
        }

        obstacle.position = CGPoint(x: x, y: y)
        addChild(obstacle)
        obstacleNodes.append(obstacle)
    }

    // MARK: - Trajectory Preview

    private func updateTrajectoryPreview() {
        clearTrajectory()

        let points = slingshotNode.trajectoryPoints()
        for (i, point) in points.enumerated() {
            let dot = SKShapeNode(circleOfRadius: 3)
            dot.fillColor = SKColor.white.withAlphaComponent(CGFloat(1.0 - Double(i) / Double(max(points.count, 1))))
            dot.strokeColor = .clear
            dot.position = point
            dot.zPosition = GameConfig.ZPosition.slingshot - 1
            addChild(dot)
            trajectoryDots.append(dot)
        }
    }

    private func clearTrajectory() {
        for dot in trajectoryDots { dot.removeFromParent() }
        trajectoryDots.removeAll()
    }

    // MARK: - Touch Input

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        switch gameState {
        case .ready:
            // Check if touching near slingshot area
            let slingshotArea = CGRect(
                x: slingshotNode.position.x - 100,
                y: slingshotNode.position.y - 50,
                width: 200,
                height: 200
            )
            if slingshotArea.contains(location) {
                gameState = .aiming
                slingshotNode.beginPull(at: location)
                // Move plane to pouch
                planeNode.position = slingshotNode.convert(slingshotNode.pullPosition, to: self)
            }

        case .launched, .flying:
            isTouchingForPitch = true
            touchStartY = location.y

        case .results:
            handleResultsTap(location)

        default:
            break
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        switch gameState {
        case .aiming:
            slingshotNode.updatePull(to: location)
            planeNode.position = slingshotNode.convert(slingshotNode.pullPosition, to: self)

        case .launched, .flying:
            if isTouchingForPitch {
                let deltaY = location.y - touchStartY
                pitchInput = (deltaY / 100.0).clamped(to: -1...1)
            }

        default:
            break
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch gameState {
        case .aiming:
            if let impulse = slingshotNode.release() {
                clearTrajectory()
                launchPlane(with: impulse)
            } else {
                gameState = .ready
                planeNode.position = CGPoint(
                    x: slingshotNode.position.x,
                    y: slingshotNode.position.y + GameConfig.Slingshot.forkHeight
                )
            }

        case .launched, .flying:
            isTouchingForPitch = false
            pitchInput = 0

        default:
            break
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }

    // MARK: - Launch

    private func launchPlane(with impulse: CGVector) {
        gameState = .launched
        GameManager.shared.setState(.launched)

        progressionSystem.startFlight(at: planeNode.position.x)
        planeNode.launch(with: impulse)

        // Show HUD
        hudNode.run(SKAction.fadeIn(withDuration: 0.3))

        // Hide slingshot
        slingshotNode.run(SKAction.fadeOut(withDuration: 0.3))
    }

    // MARK: - Collision Handlers

    private func handleCoinCollected(_ coin: CoinNode) {
        coinSystem.collectCoin(coin)
        progressionSystem.addCoins(GameConfig.Coins.baseValue)
        HapticsManager.shared.playCoinCollect()
        AudioManager.shared.playSound(GameConfig.Audio.coinSound)
    }

    private func handlePowerUpCollected(_ powerUp: PowerUpNode) {
        let type = coinSystem.collectPowerUp(powerUp)

        switch type {
        case .speedBoost:
            planeNode.activateBoost()
            HapticsManager.shared.playBoost()
            AudioManager.shared.playSound(GameConfig.Audio.boostSound)
        case .shield:
            planeNode.activateShield()
        case .coinMagnet:
            planeNode.activateMagnet()
        }

        NotificationCenter.default.post(name: .powerUpCollected, object: type)
    }

    private func handleObstacleHit(_ obstacle: ObstacleNode) {
        guard gameState == .launched || gameState == .flying else { return }

        // Destructible obstacles
        if obstacle.kind.isDestructible {
            obstacle.destroy()
            obstacleNodes.removeAll { $0 === obstacle }
            return
        }

        // Shield check
        if planeNode.handleObstacleHit() {
            // Shield absorbed it
            obstacle.destroy()
            obstacleNodes.removeAll { $0 === obstacle }
            return
        }

        // Crash
        endFlight(smoothLanding: false)
    }

    private func handleGroundHit(speed: CGFloat) {
        guard gameState == .launched || gameState == .flying else { return }

        let angle = abs(radiansToDegrees(planeNode.zRotation))
        let isSmooth = speed < GameConfig.Plane.smoothLandingSpeed &&
                       angle < GameConfig.Plane.smoothLandingAngle

        endFlight(smoothLanding: isSmooth)
    }

    // MARK: - End Flight

    private func endFlight(smoothLanding: Bool) {
        guard gameState == .launched || gameState == .flying else { return }

        if smoothLanding {
            gameState = .landing
            GameManager.shared.setState(.landing)
        } else {
            gameState = .crashed
            GameManager.shared.setState(.crashed)
            planeNode.playCrashEffect()
            cameraNode.shake()
        }

        planeNode.stopExhaust()

        // Brief delay then show results
        run(SKAction.sequence([
            SKAction.wait(forDuration: smoothLanding ? 0.5 : 1.0),
            SKAction.run { [weak self] in
                self?.showResults(smoothLanding: smoothLanding)
            }
        ]))
    }

    // MARK: - Results Screen

    private func showResults(smoothLanding: Bool) {
        gameState = .results

        let result = GameManager.shared.endFlight(smoothLanding: smoothLanding)

        let overlay = SKNode()
        overlay.zPosition = GameConfig.ZPosition.overlay

        // Dim
        let dim = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: size.height * 2))
        dim.fillColor = SKColor.black.withAlphaComponent(0.75)
        dim.strokeColor = .clear
        overlay.addChild(dim)

        // Panel
        let panelW: CGFloat = 300
        let panelH: CGFloat = 400
        let panel = SKShapeNode(rectOf: CGSize(width: panelW, height: panelH), cornerRadius: 20)
        panel.fillColor = SKColor(hex: "#2A2A4A")
        panel.strokeColor = SKColor.white.withAlphaComponent(0.2)
        panel.lineWidth = 1
        overlay.addChild(panel)

        // Title
        let titleText = smoothLanding ? "SMOOTH LANDING!" : "FLIGHT OVER"
        let titleColor = smoothLanding ? SKColor(hex: GameConfig.UI.accentColor) : SKColor.white
        let title = SKLabelNode.styled(text: titleText, fontSize: 28, color: titleColor)
        title.position = CGPoint(x: 0, y: panelH / 2 - 45)
        panel.addChild(title)

        // New best indicator
        if result.isNewBest {
            let bestLabel = SKLabelNode.styled(
                text: "NEW BEST!",
                fontSize: 20,
                color: SKColor(hex: GameConfig.UI.secondaryColor)
            )
            bestLabel.position = CGPoint(x: 0, y: panelH / 2 - 75)
            panel.addChild(bestLabel)
            bestLabel.pulseForever(scale: 1.1, duration: 0.6)
        }

        // Stats
        let statsY: CGFloat = result.isNewBest ? 50 : 70
        let stats: [(String, String)] = [
            ("Distance", "\(Int(result.distance))m"),
            ("Coins", "\(result.coinsCollected)"),
            ("Bonus", "+\(result.bonusCoins)"),
            ("XP", "+\(Int(result.xpEarned))"),
        ]

        for (i, stat) in stats.enumerated() {
            let y = statsY - CGFloat(i) * 36

            let nameLabel = SKLabelNode.styled(
                text: stat.0,
                fontSize: 18,
                fontName: GameConfig.UI.fontNameRegular,
                color: .lightGray
            )
            nameLabel.horizontalAlignmentMode = .left
            nameLabel.position = CGPoint(x: -panelW / 2 + 30, y: y)
            panel.addChild(nameLabel)

            let valueLabel = SKLabelNode.styled(
                text: stat.1,
                fontSize: 18,
                color: .white
            )
            valueLabel.horizontalAlignmentMode = .right
            valueLabel.position = CGPoint(x: panelW / 2 - 30, y: y)
            panel.addChild(valueLabel)
        }

        // XP Progress bar
        let xpProgress = GameManager.shared.progress.xpProgress
        let barY: CGFloat = statsY - CGFloat(stats.count) * 36 - 20
        let xpBarBg = SKShapeNode(rectOf: CGSize(width: panelW - 60, height: 12), cornerRadius: 6)
        xpBarBg.fillColor = SKColor.white.withAlphaComponent(0.1)
        xpBarBg.strokeColor = .clear
        xpBarBg.position = CGPoint(x: 0, y: barY)
        panel.addChild(xpBarBg)

        let fillWidth = (panelW - 64) * xpProgress
        let xpBarFill = SKShapeNode(rectOf: CGSize(width: max(1, fillWidth), height: 8), cornerRadius: 4)
        xpBarFill.fillColor = SKColor(hex: GameConfig.UI.primaryColor)
        xpBarFill.strokeColor = .clear
        xpBarFill.position.x = -(panelW - 64 - fillWidth) / 2
        xpBarBg.addChild(xpBarFill)

        let lvlLabel = SKLabelNode.styled(
            text: "Lv. \(GameManager.shared.progress.level)",
            fontSize: 14,
            fontName: GameConfig.UI.fontNameRegular,
            color: .lightGray
        )
        lvlLabel.position = CGPoint(x: 0, y: barY - 22)
        panel.addChild(lvlLabel)

        // Buttons
        let retryBtn = createResultButton(text: "RETRY", color: SKColor(hex: GameConfig.UI.accentColor), name: "retryBtn")
        retryBtn.position = CGPoint(x: -70, y: -panelH / 2 + 50)
        panel.addChild(retryBtn)

        let upgradeBtn = createResultButton(text: "UPGRADE", color: SKColor(hex: GameConfig.UI.primaryColor), name: "upgradeBtn")
        upgradeBtn.position = CGPoint(x: 70, y: -panelH / 2 + 50)
        panel.addChild(upgradeBtn)

        // Menu button (small)
        let menuBtn = SKLabelNode.styled(
            text: "MENU",
            fontSize: 16,
            fontName: GameConfig.UI.fontNameRegular,
            color: .lightGray
        )
        menuBtn.name = "menuBtn"
        menuBtn.position = CGPoint(x: 0, y: -panelH / 2 + 18)
        panel.addChild(menuBtn)

        cameraNode.addChild(overlay)
        resultsOverlay = overlay

        overlay.alpha = 0
        overlay.setScale(0.8)
        let show = SKAction.group([
            SKAction.fadeIn(withDuration: 0.3),
            SKAction.scale(to: 1.0, duration: 0.3)
        ])
        show.timingMode = .easeOut
        overlay.run(show)
    }

    private func createResultButton(text: String, color: SKColor, name: String) -> SKShapeNode {
        let btn = SKShapeNode(rectOf: CGSize(width: 120, height: 44), cornerRadius: 22)
        btn.fillColor = color
        btn.strokeColor = .clear
        btn.name = name

        let label = SKLabelNode.styled(text: text, fontSize: 16, color: .white)
        label.name = name
        btn.addChild(label)

        return btn
    }

    private func handleResultsTap(_ location: CGPoint) {
        let cameraLocation = convert(location, to: cameraNode)
        let tapped = cameraNode.nodes(at: cameraLocation)

        for node in tapped {
            switch node.name {
            case "retryBtn":
                HapticsManager.shared.playButtonTap()
                guard let view = self.view else { return }
                GameManager.shared.restartGame(in: view)

            case "upgradeBtn":
                HapticsManager.shared.playButtonTap()
                guard let view = self.view else { return }
                GameManager.shared.openUpgrades(in: view)

            case "menuBtn":
                HapticsManager.shared.playButtonTap()
                guard let view = self.view else { return }
                GameManager.shared.returnToMenu(in: view)

            default:
                break
            }
        }
    }
}
