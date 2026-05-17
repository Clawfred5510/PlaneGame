import SpriteKit

// MARK: - CoinNode

final class CoinNode: SKNode {

    // MARK: - Properties

    private var coinShape: SKShapeNode!
    private var innerShape: SKShapeNode!
    private var isCollected = false
    private var sparkleEmitter: SKEmitterNode?

    // MARK: - Init

    override init() {
        super.init()
        buildCoin()
        setupPhysics()
        startAnimation()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    // MARK: - Build

    private func buildCoin() {
        let radius = GameConfig.Coins.size / 2

        // Outer coin body - golden circle with rich border
        coinShape = SKShapeNode(circleOfRadius: radius)
        coinShape.fillColor = SKColor(hex: "#FFD700")
        coinShape.strokeColor = SKColor(hex: "#B8860B")
        coinShape.lineWidth = 2.5
        coinShape.glowWidth = 3
        addChild(coinShape)

        // Rim highlight (lighter edge on top-left for 3D look)
        let rimHighlight = SKShapeNode(circleOfRadius: radius - 1)
        rimHighlight.fillColor = .clear
        rimHighlight.strokeColor = SKColor(hex: "#FFECB3").withAlphaComponent(0.4)
        rimHighlight.lineWidth = 1.5
        coinShape.addChild(rimHighlight)

        // Inner circle detail (recessed area like a real coin)
        innerShape = SKShapeNode(circleOfRadius: radius * 0.65)
        innerShape.fillColor = SKColor(hex: "#FFC107")
        innerShape.strokeColor = SKColor(hex: "#FF8F00")
        innerShape.lineWidth = 1.5
        addChild(innerShape)

        // Star symbol in center (more game-like than $)
        let starPath = createStarPath(radius: radius * 0.35, points: 5)
        let star = SKShapeNode(path: starPath)
        star.fillColor = SKColor(hex: "#FF8F00")
        star.strokeColor = SKColor(hex: "#E65100").withAlphaComponent(0.6)
        star.lineWidth = 0.5
        addChild(star)

        // Subtle sparkle emitter
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 3
        emitter.particleLifetime = 0.6
        emitter.particleLifetimeRange = 0.2
        emitter.particleSpeed = 15
        emitter.particleSpeedRange = 10
        emitter.emissionAngleRange = .pi * 2
        emitter.particleScale = 0.06
        emitter.particleScaleRange = 0.03
        emitter.particleScaleSpeed = -0.08
        emitter.particleAlpha = 0.8
        emitter.particleAlphaSpeed = -1.2
        emitter.particleColor = SKColor(hex: "#FFD700")
        emitter.particleColorBlendFactor = 1.0
        emitter.particleColorSequence = SKKeyframeSequence(
            keyframeValues: [SKColor.white, SKColor(hex: "#FFD700"), SKColor(hex: "#FFA000")],
            times: [0 as NSNumber, 0.3 as NSNumber, 1.0 as NSNumber]
        )
        let tex = SKTexture.placeholder(color: .white, size: CGSize(width: 6, height: 6))
        emitter.particleTexture = tex
        emitter.zPosition = 1
        addChild(emitter)
        sparkleEmitter = emitter

        zPosition = GameConfig.ZPosition.coins
    }

    private func createStarPath(radius: CGFloat, points: Int) -> CGPath {
        let path = CGMutablePath()
        let innerRadius = radius * 0.4
        let angleStep = .pi / CGFloat(points)

        for i in 0..<(points * 2) {
            let r = i % 2 == 0 ? radius : innerRadius
            let angle = CGFloat(i) * angleStep - .pi / 2
            let point = CGPoint(x: cos(angle) * r, y: sin(angle) * r)
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }

    // MARK: - Physics

    private func setupPhysics() {
        let body = SKPhysicsBody(circleOfRadius: GameConfig.Coins.collectRadius)
        body.isDynamic = false
        body.categoryBitMask = GameConfig.PhysicsCategory.coin
        body.contactTestBitMask = GameConfig.PhysicsCategory.plane
        body.collisionBitMask = GameConfig.PhysicsCategory.none
        physicsBody = body
    }

    // MARK: - Animation

    private func startAnimation() {
        // Float up/down
        let float = SKAction.floatUpDown(
            amplitude: GameConfig.Coins.floatAmplitude,
            duration: 1.0 / GameConfig.Coins.floatFrequency
        )
        run(float, withKey: "float")

        // 3D rotation simulation via X-scale oscillation
        let spinDuration: TimeInterval = 1.8
        let squishIn = SKAction.scaleX(to: 0.3, duration: spinDuration / 4)
        squishIn.timingMode = .easeInEaseOut
        let squishOut = SKAction.scaleX(to: 1.0, duration: spinDuration / 4)
        squishOut.timingMode = .easeInEaseOut
        let pause = SKAction.scaleX(to: 1.0, duration: spinDuration / 4)

        let spin = SKAction.sequence([
            pause,
            squishIn,
            squishOut,
            pause
        ])
        run(SKAction.repeatForever(spin), withKey: "shimmer")
    }

    // MARK: - Collection

    func collect(flyTo target: CGPoint? = nil) {
        guard !isCollected else { return }
        isCollected = true

        physicsBody = nil
        removeAction(forKey: "float")
        removeAction(forKey: "shimmer")
        sparkleEmitter?.particleBirthRate = 0

        if let target = target {
            // Fly to HUD coin counter with arc path
            let midPoint = CGPoint(
                x: (position.x + target.x) / 2,
                y: max(position.y, target.y) + 50
            )

            let flyPath = CGMutablePath()
            flyPath.move(to: position)
            flyPath.addQuadCurve(to: target, control: midPoint)

            let flyAction = SKAction.follow(flyPath, asOffset: false, orientToPath: false, duration: 0.5)
            flyAction.timingMode = .easeIn
            let shrink = SKAction.scale(to: 0.3, duration: 0.5)
            let group = SKAction.group([flyAction, shrink])
            run(SKAction.sequence([group, SKAction.removeFromParent()]))
        } else {
            // Burst of golden particles on collection
            playCollectionBurst()

            // Scale up then disappear
            let pop = SKAction.group([
                SKAction.scale(to: 1.8, duration: 0.12),
                SKAction.fadeOut(withDuration: 0.18)
            ])
            run(SKAction.sequence([pop, SKAction.removeFromParent()]))
        }
    }

    // MARK: - Magnet attraction

    func attractToward(_ target: CGPoint, speed: CGFloat, dt: TimeInterval) {
        guard !isCollected else { return }
        let direction = (target - position).normalized
        let move = direction * speed * CGFloat(dt)
        position += move
    }

    // MARK: - Collection Burst Effect

    private func playCollectionBurst() {
        let sparkleCount = GameConfig.Coins.sparkleParticleCount

        for i in 0..<sparkleCount {
            let sparkle = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...4))
            sparkle.fillColor = SKColor(hex: "#FFD700")
            sparkle.strokeColor = .clear
            sparkle.glowWidth = 3
            sparkle.position = position
            sparkle.zPosition = GameConfig.ZPosition.particles
            parent?.addChild(sparkle)

            let angle = (CGFloat(i) / CGFloat(sparkleCount)) * .pi * 2 + CGFloat.random(in: -0.2...0.2)
            let distance = CGFloat.random(in: 25...55)
            let dx = cos(angle) * distance
            let dy = sin(angle) * distance

            let move = SKAction.moveBy(x: dx, y: dy, duration: 0.35)
            move.timingMode = .easeOut
            let fade = SKAction.fadeOut(withDuration: 0.35)
            let scaleDown = SKAction.scale(to: 0.2, duration: 0.35)
            sparkle.run(SKAction.sequence([
                SKAction.group([move, fade, scaleDown]),
                SKAction.removeFromParent()
            ]))
        }

        // Central flash
        let flash = SKShapeNode(circleOfRadius: GameConfig.Coins.size * 0.8)
        flash.fillColor = SKColor(hex: "#FFECB3").withAlphaComponent(0.6)
        flash.strokeColor = .clear
        flash.glowWidth = 8
        flash.position = position
        flash.zPosition = GameConfig.ZPosition.particles
        parent?.addChild(flash)

        let expand = SKAction.scale(to: 2.0, duration: 0.2)
        let fadeFlash = SKAction.fadeOut(withDuration: 0.2)
        flash.run(SKAction.sequence([
            SKAction.group([expand, fadeFlash]),
            SKAction.removeFromParent()
        ]))
    }
}

// MARK: - PowerUpNode

final class PowerUpNode: SKNode {

    // MARK: - Properties

    let type: PowerUpType
    private var shapeNode: SKShapeNode!
    private var iconLabel: SKLabelNode!
    private var isCollected = false

    // MARK: - Init

    init(type: PowerUpType) {
        self.type = type
        super.init()
        buildPowerUp()
        setupPhysics()
        startAnimation()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    // MARK: - Build

    private func buildPowerUp() {
        let size = GameConfig.PowerUps.size

        // Outer container with rounded corners
        shapeNode = SKShapeNode(rectOf: CGSize(width: size, height: size), cornerRadius: 10)
        shapeNode.fillColor = SKColor(hex: type.colorHex)
        shapeNode.strokeColor = .white
        shapeNode.lineWidth = 2
        shapeNode.glowWidth = 5
        addChild(shapeNode)

        // Inner diamond decoration
        let innerPath = CGMutablePath()
        let inset: CGFloat = size * 0.2
        innerPath.move(to: CGPoint(x: 0, y: size / 2 - inset))
        innerPath.addLine(to: CGPoint(x: size / 2 - inset, y: 0))
        innerPath.addLine(to: CGPoint(x: 0, y: -(size / 2 - inset)))
        innerPath.addLine(to: CGPoint(x: -(size / 2 - inset), y: 0))
        innerPath.closeSubpath()

        let innerDiamond = SKShapeNode(path: innerPath)
        innerDiamond.fillColor = SKColor(hex: type.colorHex).withAlphaComponent(0.3)
        innerDiamond.strokeColor = .white.withAlphaComponent(0.5)
        innerDiamond.lineWidth = 1
        addChild(innerDiamond)

        // Icon
        let icon: String
        switch type {
        case .speedBoost: icon = ">"
        case .shield:     icon = "O"
        case .coinMagnet: icon = "M"
        }

        iconLabel = SKLabelNode.styled(
            text: icon,
            fontSize: size * 0.45,
            fontName: GameConfig.UI.fontName,
            color: .white
        )
        addChild(iconLabel)

        zPosition = GameConfig.ZPosition.powerUps
    }

    // MARK: - Physics

    private func setupPhysics() {
        let body = SKPhysicsBody(rectangleOf: CGSize(width: GameConfig.PowerUps.size,
                                                      height: GameConfig.PowerUps.size))
        body.isDynamic = false
        body.categoryBitMask = GameConfig.PhysicsCategory.powerUp
        body.contactTestBitMask = GameConfig.PhysicsCategory.plane
        body.collisionBitMask = GameConfig.PhysicsCategory.none
        physicsBody = body
    }

    // MARK: - Animation

    private func startAnimation() {
        let float = SKAction.floatUpDown(amplitude: 10, duration: 0.8)
        run(float, withKey: "float")
        pulseForever(scale: 1.15, duration: 1.0)
    }

    // MARK: - Collection

    func collect() {
        guard !isCollected else { return }
        isCollected = true
        physicsBody = nil
        removeAllActions()

        // Flash effect
        let flash = SKShapeNode(circleOfRadius: GameConfig.PowerUps.size * 0.8)
        flash.fillColor = SKColor(hex: type.colorHex).withAlphaComponent(0.4)
        flash.strokeColor = .clear
        flash.glowWidth = 10
        flash.position = position
        flash.zPosition = GameConfig.ZPosition.particles
        parent?.addChild(flash)

        let expandFlash = SKAction.scale(to: 3.0, duration: 0.3)
        let fadeFlash = SKAction.fadeOut(withDuration: 0.3)
        flash.run(SKAction.sequence([
            SKAction.group([expandFlash, fadeFlash]),
            SKAction.removeFromParent()
        ]))

        let expand = SKAction.scale(to: 1.8, duration: 0.2)
        let fade = SKAction.fadeOut(withDuration: 0.2)
        run(SKAction.sequence([SKAction.group([expand, fade]), SKAction.removeFromParent()]))
    }
}
