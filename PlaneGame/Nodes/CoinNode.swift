import SpriteKit

// MARK: - CoinNode

final class CoinNode: SKNode {

    // MARK: - Properties

    private var coinShape: SKShapeNode!
    private var innerShape: SKShapeNode!
    private var isCollected = false

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

        // Outer coin
        coinShape = SKShapeNode(circleOfRadius: radius)
        coinShape.fillColor = SKColor(hex: "#FFD700")
        coinShape.strokeColor = SKColor(hex: "#FFA000")
        coinShape.lineWidth = 2
        coinShape.glowWidth = 2
        addChild(coinShape)

        // Inner detail
        innerShape = SKShapeNode(circleOfRadius: radius * 0.6)
        innerShape.fillColor = SKColor(hex: "#FFECB3")
        innerShape.strokeColor = SKColor(hex: "#FFD700")
        innerShape.lineWidth = 1
        addChild(innerShape)

        // Dollar sign
        let label = SKLabelNode.styled(
            text: "$",
            fontSize: GameConfig.Coins.size * 0.5,
            fontName: GameConfig.UI.fontName,
            color: SKColor(hex: "#FFA000")
        )
        addChild(label)

        zPosition = GameConfig.ZPosition.coins
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
        let float = SKAction.floatUpDown(
            amplitude: GameConfig.Coins.floatAmplitude,
            duration: 1.0 / GameConfig.Coins.floatFrequency
        )
        run(float, withKey: "float")

        // Subtle rotation shimmer
        let shimmer = SKAction.sequence([
            SKAction.scaleX(to: 0.7, duration: 0.3),
            SKAction.scaleX(to: 1.0, duration: 0.3)
        ])
        run(SKAction.repeatForever(shimmer), withKey: "shimmer")
    }

    // MARK: - Collection

    func collect(flyTo target: CGPoint? = nil) {
        guard !isCollected else { return }
        isCollected = true

        physicsBody = nil
        removeAction(forKey: "float")
        removeAction(forKey: "shimmer")

        if let target = target {
            // Fly to HUD coin counter
            let flyAction = SKAction.move(to: target, duration: 0.4)
            flyAction.timingMode = .easeIn
            let shrink = SKAction.scale(to: 0.3, duration: 0.4)
            let group = SKAction.group([flyAction, shrink])
            run(SKAction.sequence([group, SKAction.removeFromParent()]))
        } else {
            // Quick sparkle and remove
            playSparkle()
            let pop = SKAction.group([
                SKAction.scale(to: 1.5, duration: 0.15),
                SKAction.fadeOut(withDuration: 0.15)
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

    // MARK: - Sparkle Effect

    private func playSparkle() {
        let sparkleCount = GameConfig.Coins.sparkleParticleCount

        for _ in 0..<sparkleCount {
            let sparkle = SKShapeNode(circleOfRadius: 3)
            sparkle.fillColor = SKColor(hex: "#FFD700")
            sparkle.strokeColor = .clear
            sparkle.glowWidth = 2
            sparkle.position = position
            sparkle.zPosition = GameConfig.ZPosition.particles
            parent?.addChild(sparkle)

            let angle = CGFloat.random(in: 0...(.pi * 2))
            let distance = CGFloat.random(in: 20...50)
            let dx = cos(angle) * distance
            let dy = sin(angle) * distance

            let move = SKAction.moveBy(x: dx, y: dy, duration: 0.3)
            let fade = SKAction.fadeOut(withDuration: 0.3)
            sparkle.run(SKAction.sequence([
                SKAction.group([move, fade]),
                SKAction.removeFromParent()
            ]))
        }
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

        shapeNode = SKShapeNode(rectOf: CGSize(width: size, height: size), cornerRadius: 8)
        shapeNode.fillColor = SKColor(hex: type.colorHex)
        shapeNode.strokeColor = .white
        shapeNode.lineWidth = 2
        shapeNode.glowWidth = 4
        addChild(shapeNode)

        let icon: String
        switch type {
        case .speedBoost: icon = ">"
        case .shield:     icon = "O"
        case .coinMagnet: icon = "M"
        }

        iconLabel = SKLabelNode.styled(
            text: icon,
            fontSize: size * 0.5,
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

        let expand = SKAction.scale(to: 1.8, duration: 0.2)
        let fade = SKAction.fadeOut(withDuration: 0.2)
        run(SKAction.sequence([SKAction.group([expand, fade]), SKAction.removeFromParent()]))
    }
}
