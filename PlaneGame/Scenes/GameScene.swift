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
    private var distanceSuffix: SKLabelNode!
    private var coinCountLabel: SKLabelNode!
    private var coinIcon: SKShapeNode!
    private var altitudeBar: SKNode!
    private var altitudeBarFill: SKShapeNode!
    private var speedBarBg: SKShapeNode!
    private var speedBarFill: SKShapeNode!
    private var powerUpIndicators: SKNode!
    private var activePowerUps: [PowerUpType: (node: SKNode, timer: TimeInterval)] = [:]

    // Touch
    private var pitchInput: CGFloat = 0
    private var isTouchingForPitch = false
    private var touchLocation: CGPoint = .zero

    // Distance
    private var launchX: CGFloat = 0
    private var distanceTraveled: CGFloat { max(0, planeNode.position.x - launchX) }

    // Results overlay
    private var resultsOverlay: SKNode?

    // Camera zoom
    private var baseScale: CGFloat = 1.0
    private var targetScale: CGFloat = 1.0

    // Smooth landing text
    private var smoothLandingLabel: SKLabelNode?

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

        let topY = size.height / 2 - GameConfig.UI.hudPadding - 12
        let bottomY = -size.height / 2 + GameConfig.UI.hudPadding + 20

        // ---- Top-Left: Distance meter ----
        distanceLabel = SKLabelNode.styled(
            text: "0",
            fontSize: 32,
            color: .white
        )
        distanceLabel.horizontalAlignmentMode = .left
        distanceLabel.position = CGPoint(x: -size.width / 2 + GameConfig.UI.hudPadding, y: topY)
        hudNode.addChild(distanceLabel)

        distanceSuffix = SKLabelNode.styled(
            text: "m",
            fontSize: 18,
            fontName: GameConfig.UI.fontNameRegular,
            color: SKColor.white.withAlphaComponent(0.6)
        )
        distanceSuffix.horizontalAlignmentMode = .left
        distanceSuffix.position = CGPoint(x: -size.width / 2 + GameConfig.UI.hudPadding + 60, y: topY + 2)
        hudNode.addChild(distanceSuffix)

        // ---- Top-Right: Coin counter ----
        coinIcon = SKShapeNode(circleOfRadius: 9)
        coinIcon.fillColor = SKColor(hex: "#FFD700")
        coinIcon.strokeColor = SKColor(hex: "#FFA000")
        coinIcon.lineWidth = 1.5
        coinIcon.position = CGPoint(x: size.width / 2 - GameConfig.UI.hudPadding - 50, y: topY + 8)
        hudNode.addChild(coinIcon)

        let coinSymbol = SKLabelNode.styled(text: "$", fontSize: 10, color: SKColor(hex: "#B8860B"))
        coinIcon.addChild(coinSymbol)

        coinCountLabel = SKLabelNode.styled(
            text: "0",
            fontSize: 22,
            color: SKColor(hex: "#FFD700")
        )
        coinCountLabel.horizontalAlignmentMode = .left
        coinCountLabel.position = CGPoint(x: size.width / 2 - GameConfig.UI.hudPadding - 35, y: topY)
        hudNode.addChild(coinCountLabel)

        // ---- Top-Center: Altitude bar ----
        let altBarHeight: CGFloat = 100
        let altBarWidth: CGFloat = 6

        altitudeBar = SKNode()
        altitudeBar.position = CGPoint(x: 0, y: topY - altBarHeight / 2 - 10)
        hudNode.addChild(altitudeBar)

        let altBg = SKShapeNode(rectOf: CGSize(width: altBarWidth, height: altBarHeight), cornerRadius: 3)
        altBg.fillColor = SKColor.white.withAlphaComponent(0.15)
        altBg.strokeColor = .clear
        altitudeBar.addChild(altBg)

        altitudeBarFill = SKShapeNode(rectOf: CGSize(width: altBarWidth - 2, height: 1), cornerRadius: 2)
        altitudeBarFill.fillColor = SKColor(hex: "#64B5F6")
        altitudeBarFill.strokeColor = .clear
        altitudeBarFill.position = CGPoint(x: 0, y: -altBarHeight / 2)
        altitudeBar.addChild(altitudeBarFill)

        // Altitude label
        let altLabel = SKLabelNode.styled(text: "ALT", fontSize: 9, fontName: GameConfig.UI.fontNameRegular, color: SKColor.white.withAlphaComponent(0.4))
        altLabel.position = CGPoint(x: 0, y: altBarHeight / 2 + 10)
        altitudeBar.addChild(altLabel)

        // ---- Bottom: Speed indicator bar ----
        let speedBarWidth: CGFloat = 160
        let speedBarHeight: CGFloat = 8

        speedBarBg = SKShapeNode(rectOf: CGSize(width: speedBarWidth, height: speedBarHeight), cornerRadius: 4)
        speedBarBg.fillColor = SKColor.white.withAlphaComponent(0.12)
        speedBarBg.strokeColor = .clear
        speedBarBg.position = CGPoint(x: 0, y: bottomY)
        hudNode.addChild(speedBarBg)

        speedBarFill = SKShapeNode(rectOf: CGSize(width: 1, height: speedBarHeight - 2), cornerRadius: 3)
        speedBarFill.fillColor = SKColor(hex: "#4CAF50")
        speedBarFill.strokeColor = .clear
        speedBarBg.addChild(speedBarFill)

        // Speed label
        let speedLabel = SKLabelNode.styled(text: "SPEED", fontSize: 9, fontName: GameConfig.UI.fontNameRegular, color: SKColor.white.withAlphaComponent(0.4))
        speedLabel.position = CGPoint(x: 0, y: -16)
        speedBarBg.addChild(speedLabel)

        // ---- Power-up indicators area ----
        powerUpIndicators = SKNode()
        powerUpIndicators.position = CGPoint(x: -size.width / 2 + GameConfig.UI.hudPadding, y: topY - 60)
        hudNode.addChild(powerUpIndicators)

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
            updatePowerUpIndicators()
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

            // Transition to flying state when airborne
            if gameState == .launched && planeNode.isFlying {
                gameState = .flying
            }

        default:
            break
        }
    }

    // MARK: - Flight

    private func updateFlight(_ currentTime: TimeInterval) {
        let dt = 1.0 / 60.0
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

        // Subtle zoom based on speed
        let speedFraction = (planeNode.currentSpeed / GameConfig.Plane.maxSpeed).clamped(to: 0...1)
        targetScale = lerp(1.0, 0.92, speedFraction)
        let currentScale = cameraNode.xScale
        let newScale = lerp(currentScale, targetScale, 0.03)
        cameraNode.setScale(newScale)
    }

    // MARK: - HUD Update

    private func updateHUD() {
        let dist = Int(distanceTraveled)
        distanceLabel.text = "\(dist)"

        // Move suffix to follow distance text width
        let textWidth = CGFloat(String(dist).count) * 18
        distanceSuffix.position.x = -size.width / 2 + GameConfig.UI.hudPadding + textWidth + 4

        coinCountLabel.text = "\(coinSystem.coinsCollected)"

        // Altitude bar
        let maxAlt: CGFloat = 800
        let alt = max(0, planeNode.position.y - GameConfig.World.groundY)
        let altFraction = (alt / maxAlt).clamped(to: 0...1)
        let altBarHeight: CGFloat = 100
        let fillHeight = max(1, altBarHeight * altFraction)

        altitudeBarFill.removeFromParent()
        altitudeBarFill = SKShapeNode(rectOf: CGSize(width: 4, height: fillHeight), cornerRadius: 2)
        altitudeBarFill.fillColor = altFraction > 0.7 ? SKColor(hex: "#EF5350") :
                                    altFraction > 0.4 ? SKColor(hex: "#FFA726") :
                                    SKColor(hex: "#64B5F6")
        altitudeBarFill.strokeColor = .clear
        altitudeBarFill.position = CGPoint(x: 0, y: -altBarHeight / 2 + fillHeight / 2)
        altitudeBar.addChild(altitudeBarFill)

        // Speed bar
        let speedFraction = (planeNode.currentSpeed / GameConfig.Plane.maxSpeed).clamped(to: 0...1)
        let speedBarWidth: CGFloat = 160
        let fillWidth = max(1, speedBarWidth * speedFraction)

        speedBarFill.removeFromParent()
        speedBarFill = SKShapeNode(rectOf: CGSize(width: fillWidth, height: 6), cornerRadius: 3)

        // Gradient color based on speed: green -> yellow -> red
        if speedFraction > 0.75 {
            speedBarFill.fillColor = SKColor(hex: "#EF5350")
        } else if speedFraction > 0.45 {
            speedBarFill.fillColor = SKColor(hex: "#FFA726")
        } else {
            speedBarFill.fillColor = SKColor(hex: "#4CAF50")
        }
        speedBarFill.strokeColor = .clear
        speedBarFill.position = CGPoint(x: -(speedBarWidth - fillWidth) / 2, y: 0)
        speedBarBg.addChild(speedBarFill)
    }

    private func updatePowerUpIndicators() {
        // Update countdown timers - visual rings handled on collection
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
            let alphaPct = CGFloat(1.0 - Double(i) / Double(max(points.count, 1)))
            let dotRadius: CGFloat = lerp(2, 5, alphaPct)
            let dot = SKShapeNode(circleOfRadius: dotRadius)
            dot.fillColor = SKColor.white.withAlphaComponent(alphaPct * 0.7)
            dot.strokeColor = .clear
            dot.glowWidth = 1
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
                x: slingshotNode.position.x - 120,
                y: slingshotNode.position.y - 80,
                width: 240,
                height: 250
            )
            if slingshotArea.contains(location) {
                gameState = .aiming
                slingshotNode.beginPull(at: location)
                planeNode.position = slingshotNode.convert(slingshotNode.pullPosition, to: self)
            }

        case .launched, .flying:
            isTouchingForPitch = true
            touchLocation = location
            // Upper half = pitch up, lower half = pitch down
            let screenMidY = cameraNode.position.y
            let localY = location.y
            if localY > screenMidY {
                pitchInput = 1.0
            } else {
                pitchInput = -1.0
            }

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
                touchLocation = location
                let screenMidY = cameraNode.position.y
                let offset = location.y - screenMidY
                let normalized = (offset / (size.height * 0.4)).clamped(to: -1...1)
                pitchInput = normalized
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

        // Show HUD with smooth fade
        hudNode.run(SKAction.fadeIn(withDuration: 0.4))

        // Hide slingshot
        slingshotNode.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.run { [weak self] in self?.slingshotNode.isHidden = true }
        ]))
    }

    // MARK: - Collision Handlers

    private func handleCoinCollected(_ coin: CoinNode) {
        coinSystem.collectCoin(coin)
        progressionSystem.addCoins(GameConfig.Coins.baseValue)
        HapticsManager.shared.playCoinCollect()
        AudioManager.shared.playSound(GameConfig.Audio.coinSound)

        // Floating +1 text
        showFloatingText("+1", at: coin.position, color: SKColor(hex: "#FFD700"))
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
            HapticsManager.shared.playBoost()
        case .coinMagnet:
            planeNode.activateMagnet()
            HapticsManager.shared.playBoost()
        }

        NotificationCenter.default.post(name: .powerUpCollected, object: type)

        // Flash effect
        showPowerUpCollectionEffect(type: type, at: powerUp.position)

        // Show power-up indicator in HUD
        showPowerUpIndicator(type: type)
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

    // MARK: - Visual Effects

    private func showFloatingText(_ text: String, at position: CGPoint, color: SKColor) {
        let label = SKLabelNode.styled(text: text, fontSize: 16, color: color)
        label.position = position
        label.zPosition = GameConfig.ZPosition.particles

        addChild(label)

        let moveUp = SKAction.moveBy(x: 0, y: 40, duration: 0.6)
        let fadeOut = SKAction.fadeOut(withDuration: 0.6)
        moveUp.timingMode = .easeOut
        label.run(SKAction.sequence([
            SKAction.group([moveUp, fadeOut]),
            SKAction.removeFromParent()
        ]))
    }

    private func showPowerUpCollectionEffect(type: PowerUpType, at position: CGPoint) {
        // Screen flash
        let flash = SKShapeNode(rectOf: size)
        flash.fillColor = SKColor(hex: type.colorHex).withAlphaComponent(0.3)
        flash.strokeColor = .clear
        flash.position = .zero
        flash.zPosition = GameConfig.ZPosition.hud - 1
        cameraNode.addChild(flash)

        flash.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ]))

        // Brief icon display
        let iconLabel = SKLabelNode.styled(
            text: type.displayName.uppercased(),
            fontSize: 20,
            color: SKColor(hex: type.colorHex)
        )
        iconLabel.position = CGPoint(x: 0, y: size.height / 2 - 80)
        iconLabel.zPosition = GameConfig.ZPosition.hud + 1
        cameraNode.addChild(iconLabel)

        let scaleUp = SKAction.scale(to: 1.3, duration: 0.15)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
        let wait = SKAction.wait(forDuration: 0.8)
        let fade = SKAction.fadeOut(withDuration: 0.3)
        iconLabel.run(SKAction.sequence([scaleUp, scaleDown, wait, fade, SKAction.removeFromParent()]))
    }

    private func showPowerUpIndicator(type: PowerUpType) {
        let indicator = SKNode()

        // Background circle
        let bg = SKShapeNode(circleOfRadius: 16)
        bg.fillColor = SKColor(hex: type.colorHex).withAlphaComponent(0.3)
        bg.strokeColor = SKColor(hex: type.colorHex)
        bg.lineWidth = 2
        indicator.addChild(bg)

        // Icon
        let icon: String
        switch type {
        case .speedBoost: icon = ">"
        case .shield: icon = "O"
        case .coinMagnet: icon = "M"
        }
        let iconNode = SKLabelNode.styled(text: icon, fontSize: 14, color: .white)
        indicator.addChild(iconNode)

        // Position based on existing indicators
        let xOffset = CGFloat(activePowerUps.count) * 40
        indicator.position = CGPoint(x: xOffset, y: 0)
        powerUpIndicators.addChild(indicator)

        // Countdown ring animation
        let duration: TimeInterval
        switch type {
        case .speedBoost: duration = GameConfig.PowerUps.boostDuration
        case .shield: duration = GameConfig.PowerUps.shieldDuration
        case .coinMagnet: duration = GameConfig.PowerUps.magnetDuration
        }

        // Remove after duration
        indicator.run(SKAction.sequence([
            SKAction.wait(forDuration: duration),
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.3),
                SKAction.scale(to: 0.5, duration: 0.3)
            ]),
            SKAction.removeFromParent(),
            SKAction.run { [weak self] in
                self?.activePowerUps.removeValue(forKey: type)
            }
        ]))

        activePowerUps[type] = (node: indicator, timer: duration)
    }

    // MARK: - End Flight

    private func endFlight(smoothLanding: Bool) {
        guard gameState == .launched || gameState == .flying else { return }

        if smoothLanding {
            gameState = .landing
            GameManager.shared.setState(.landing)
            showSmoothLandingEffect()
        } else {
            gameState = .crashed
            GameManager.shared.setState(.crashed)
            playCrashSequence()
        }

        planeNode.stopExhaust()

        // Brief delay then show results
        let delay = smoothLanding ? 1.2 : 1.5
        run(SKAction.sequence([
            SKAction.wait(forDuration: delay),
            SKAction.run { [weak self] in
                self?.showResults(smoothLanding: smoothLanding)
            }
        ]))
    }

    private func playCrashSequence() {
        // Screen shake
        cameraNode.shake(intensity: GameConfig.Camera.shakeIntensity, duration: GameConfig.Camera.shakeDuration)

        // Crash effects on plane
        planeNode.playCrashEffect()

        // Add angular tumble
        if let body = planeNode.physicsBody {
            body.angularVelocity = CGFloat.random(in: -15...15)
        }

        // Dust/debris particle burst at crash point
        spawnDebrisParticles(at: planeNode.position)
    }

    private func spawnDebrisParticles(at position: CGPoint) {
        let particleCount = 20
        for _ in 0..<particleCount {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...5))
            particle.fillColor = SKColor(hex: "#8D6E63").withAlphaComponent(0.8)
            particle.strokeColor = .clear
            particle.position = position
            particle.zPosition = GameConfig.ZPosition.particles
            addChild(particle)

            let angle = CGFloat.random(in: 0...(.pi * 2))
            let distance = CGFloat.random(in: 30...100)
            let dx = cos(angle) * distance
            let dy = sin(angle) * distance + CGFloat.random(in: 20...60)

            let move = SKAction.moveBy(x: dx, y: dy, duration: CGFloat.random(in: 0.4...0.8))
            move.timingMode = .easeOut
            let gravity = SKAction.moveBy(x: 0, y: -dy * 1.5, duration: 0.5)
            let fade = SKAction.fadeOut(withDuration: 0.8)

            particle.run(SKAction.sequence([
                SKAction.group([move, fade]),
                SKAction.removeFromParent()
            ]))
        }
    }

    private func showSmoothLandingEffect() {
        // "SMOOTH LANDING!" text
        let label = SKLabelNode.styled(
            text: "SMOOTH LANDING!",
            fontSize: 28,
            color: SKColor(hex: "#4CAF50")
        )
        label.position = CGPoint(x: 0, y: 60)
        label.zPosition = GameConfig.ZPosition.hud + 5
        cameraNode.addChild(label)
        smoothLandingLabel = label

        // Animate text
        label.setScale(0.5)
        label.alpha = 0
        let appear = SKAction.group([
            SKAction.fadeIn(withDuration: 0.2),
            SKAction.scale(to: 1.2, duration: 0.2)
        ])
        let settle = SKAction.scale(to: 1.0, duration: 0.1)
        let hold = SKAction.wait(forDuration: 1.0)
        let disappear = SKAction.fadeOut(withDuration: 0.3)
        label.run(SKAction.sequence([appear, settle, hold, disappear, SKAction.removeFromParent()]))

        // Green particle burst
        let particleCount = 15
        for _ in 0..<particleCount {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 3...6))
            particle.fillColor = SKColor(hex: "#81C784")
            particle.strokeColor = .clear
            particle.glowWidth = 2
            particle.position = planeNode.position
            particle.zPosition = GameConfig.ZPosition.particles
            addChild(particle)

            let angle = CGFloat.random(in: 0...(.pi))
            let distance = CGFloat.random(in: 40...120)
            let dx = cos(angle) * distance
            let dy = sin(angle) * distance

            let move = SKAction.moveBy(x: dx, y: dy, duration: 0.6)
            move.timingMode = .easeOut
            let fade = SKAction.fadeOut(withDuration: 0.6)

            particle.run(SKAction.sequence([
                SKAction.group([move, fade]),
                SKAction.removeFromParent()
            ]))
        }

        // Bonus text
        let bonusLabel = SKLabelNode.styled(
            text: "+\(GameConfig.Progression.smoothLandingBonus) BONUS",
            fontSize: 18,
            fontName: GameConfig.UI.fontNameRegular,
            color: SKColor(hex: "#FFD700")
        )
        bonusLabel.position = CGPoint(x: 0, y: 25)
        bonusLabel.zPosition = GameConfig.ZPosition.hud + 5
        bonusLabel.alpha = 0
        cameraNode.addChild(bonusLabel)

        bonusLabel.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.3),
            SKAction.fadeIn(withDuration: 0.2),
            SKAction.wait(forDuration: 0.8),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - Results Screen

    private func showResults(smoothLanding: Bool) {
        gameState = .results

        let result = GameManager.shared.endFlight(smoothLanding: smoothLanding)

        let overlay = SKNode()
        overlay.zPosition = GameConfig.ZPosition.overlay

        // Semi-transparent dark backdrop
        let dim = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: size.height * 2))
        dim.fillColor = SKColor.black.withAlphaComponent(0.8)
        dim.strokeColor = .clear
        overlay.addChild(dim)

        // Card
        let cardW: CGFloat = 320
        let cardH: CGFloat = 420
        let card = SKShapeNode(rectOf: CGSize(width: cardW, height: cardH), cornerRadius: 24)
        card.fillColor = SKColor(hex: "#1E2A45")
        card.strokeColor = SKColor.white.withAlphaComponent(0.1)
        card.lineWidth = 1
        overlay.addChild(card)

        // Title
        let titleText = smoothLanding ? "SMOOTH LANDING!" : "FLIGHT OVER"
        let titleColor = smoothLanding ? SKColor(hex: "#4CAF50") : SKColor.white
        let title = SKLabelNode.styled(text: titleText, fontSize: 26, color: titleColor)
        title.position = CGPoint(x: 0, y: cardH / 2 - 42)
        card.addChild(title)

        // NEW BEST badge
        if result.isNewBest {
            let bestBadge = SKShapeNode(rectOf: CGSize(width: 120, height: 28), cornerRadius: 14)
            bestBadge.fillColor = SKColor(hex: GameConfig.UI.secondaryColor)
            bestBadge.strokeColor = .clear
            bestBadge.position = CGPoint(x: 0, y: cardH / 2 - 72)
            card.addChild(bestBadge)

            let bestLabel = SKLabelNode.styled(text: "NEW BEST!", fontSize: 14, color: .white)
            bestBadge.addChild(bestLabel)
            bestBadge.pulseForever(scale: 1.08, duration: 0.6)
        }

        // Stats section
        let statsStartY: CGFloat = result.isNewBest ? 55 : 75
        let statSpacing: CGFloat = 38

        // Distance
        addStatRow(to: card, label: "Distance", value: "\(Int(result.distance))m",
                   y: statsStartY, valueColor: .white)

        // Coins earned (animated count-up)
        let coinsRow = addStatRow(to: card, label: "Coins", value: "0",
                                   y: statsStartY - statSpacing, valueColor: SKColor(hex: "#FFD700"))
        animateCountUp(label: coinsRow, targetValue: result.coinsCollected, duration: 0.8, delay: 0.3)

        // Bonus
        if result.bonusCoins > 0 {
            addStatRow(to: card, label: "Landing Bonus", value: "+\(result.bonusCoins)",
                       y: statsStartY - statSpacing * 2, valueColor: SKColor(hex: "#81C784"))
        }

        // XP earned
        addStatRow(to: card, label: "XP Earned", value: "+\(Int(result.xpEarned))",
                   y: statsStartY - statSpacing * 3, valueColor: SKColor(hex: "#64B5F6"))

        // XP Progress bar
        let xpProgress = GameManager.shared.progress.xpProgress
        let barY: CGFloat = statsStartY - statSpacing * 4 - 10
        let barWidth: CGFloat = cardW - 60

        let xpBarBg = SKShapeNode(rectOf: CGSize(width: barWidth, height: 14), cornerRadius: 7)
        xpBarBg.fillColor = SKColor.white.withAlphaComponent(0.08)
        xpBarBg.strokeColor = SKColor.white.withAlphaComponent(0.1)
        xpBarBg.lineWidth = 1
        xpBarBg.position = CGPoint(x: 0, y: barY)
        card.addChild(xpBarBg)

        let fillW = max(1, (barWidth - 4) * xpProgress)
        let xpBarFill = SKShapeNode(rectOf: CGSize(width: fillW, height: 10), cornerRadius: 5)
        xpBarFill.fillColor = SKColor(hex: GameConfig.UI.primaryColor)
        xpBarFill.strokeColor = .clear
        xpBarFill.position.x = -(barWidth - 4 - fillW) / 2
        xpBarBg.addChild(xpBarFill)

        // Level indicator
        let lvlLabel = SKLabelNode.styled(
            text: "Level \(GameManager.shared.progress.level)",
            fontSize: 13,
            fontName: GameConfig.UI.fontNameRegular,
            color: SKColor.white.withAlphaComponent(0.5)
        )
        lvlLabel.position = CGPoint(x: 0, y: barY - 20)
        card.addChild(lvlLabel)

        // Buttons
        let btnY: CGFloat = -cardH / 2 + 60

        // RETRY button (primary, larger, green)
        let retryBtn = SKShapeNode(rectOf: CGSize(width: 150, height: 50), cornerRadius: 25)
        retryBtn.fillColor = SKColor(hex: "#4CAF50")
        retryBtn.strokeColor = .clear
        retryBtn.position = CGPoint(x: 55, y: btnY)
        retryBtn.name = "retryBtn"
        card.addChild(retryBtn)

        let retryLabel = SKLabelNode.styled(text: "RETRY", fontSize: 18, color: .white)
        retryLabel.name = "retryBtn"
        retryBtn.addChild(retryLabel)

        // Glow on retry button
        retryBtn.glowWidth = 4

        // UPGRADE button (blue, slightly smaller)
        let upgradeBtn = SKShapeNode(rectOf: CGSize(width: 130, height: 46), cornerRadius: 23)
        upgradeBtn.fillColor = SKColor(hex: "#2196F3")
        upgradeBtn.strokeColor = .clear
        upgradeBtn.position = CGPoint(x: -65, y: btnY)
        upgradeBtn.name = "upgradeBtn"
        card.addChild(upgradeBtn)

        let upgradeLabel = SKLabelNode.styled(text: "UPGRADE", fontSize: 16, color: .white)
        upgradeLabel.name = "upgradeBtn"
        upgradeBtn.addChild(upgradeLabel)

        // Menu text button (subtle)
        let menuBtn = SKLabelNode.styled(
            text: "MENU",
            fontSize: 14,
            fontName: GameConfig.UI.fontNameRegular,
            color: SKColor.white.withAlphaComponent(0.4)
        )
        menuBtn.name = "menuBtn"
        menuBtn.position = CGPoint(x: 0, y: -cardH / 2 + 22)
        card.addChild(menuBtn)

        cameraNode.addChild(overlay)
        resultsOverlay = overlay

        // Entrance animation
        overlay.alpha = 0
        card.setScale(0.85)
        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        let scaleIn = SKAction.scale(to: 1.0, duration: 0.3)
        scaleIn.timingMode = .easeOut
        overlay.run(fadeIn)
        card.run(scaleIn)
    }

    @discardableResult
    private func addStatRow(to parent: SKNode, label: String, value: String,
                            y: CGFloat, valueColor: SKColor) -> SKLabelNode {
        let cardW: CGFloat = 320

        let nameLabel = SKLabelNode.styled(
            text: label,
            fontSize: 16,
            fontName: GameConfig.UI.fontNameRegular,
            color: SKColor.white.withAlphaComponent(0.6)
        )
        nameLabel.horizontalAlignmentMode = .left
        nameLabel.position = CGPoint(x: -cardW / 2 + 30, y: y)
        parent.addChild(nameLabel)

        let valueLabel = SKLabelNode.styled(
            text: value,
            fontSize: 18,
            color: valueColor
        )
        valueLabel.horizontalAlignmentMode = .right
        valueLabel.position = CGPoint(x: cardW / 2 - 30, y: y)
        parent.addChild(valueLabel)

        return valueLabel
    }

    private func animateCountUp(label: SKLabelNode, targetValue: Int, duration: TimeInterval, delay: TimeInterval) {
        guard targetValue > 0 else {
            label.text = "0"
            return
        }

        let steps = min(targetValue, 30)
        let stepDuration = duration / Double(steps)

        var actions: [SKAction] = [SKAction.wait(forDuration: delay)]

        for i in 1...steps {
            let currentValue = Int(Double(targetValue) * (Double(i) / Double(steps)))
            actions.append(SKAction.run { label.text = "\(currentValue)" })
            actions.append(SKAction.wait(forDuration: stepDuration))
        }
        actions.append(SKAction.run { label.text = "\(targetValue)" })

        label.run(SKAction.sequence(actions))
    }

    private func handleResultsTap(_ location: CGPoint) {
        let cameraLocation = convert(location, to: cameraNode)
        let tapped = cameraNode.nodes(at: cameraLocation)

        for node in tapped {
            switch node.name {
            case "retryBtn":
                HapticsManager.shared.playButtonTap()
                AudioManager.shared.playSound(GameConfig.Audio.buttonSound)
                guard let view = self.view else { return }
                GameManager.shared.restartGame(in: view)

            case "upgradeBtn":
                HapticsManager.shared.playButtonTap()
                AudioManager.shared.playSound(GameConfig.Audio.buttonSound)
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
