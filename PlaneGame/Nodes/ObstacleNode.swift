import SpriteKit

// MARK: - ObstacleNode

final class ObstacleNode: SKNode {

    // MARK: - Properties

    let kind: ObstacleKind
    private var shapeNode: SKShapeNode!
    private var detailNode: SKNode?

    // MARK: - Init

    init(kind: ObstacleKind) {
        self.kind = kind
        super.init()
        buildObstacle()
        setupPhysics()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    // MARK: - Build

    private func buildObstacle() {
        let size = kind.size

        switch kind {
        case .tree:
            buildTree(size: size)
        case .barn:
            buildBarn(size: size)
        case .bird:
            buildBird(size: size)
        case .windmill:
            buildWindmill(size: size)
        case .peak:
            buildPeak(size: size)
        case .cloud:
            buildCloud(size: size)
        case .pine:
            buildPine(size: size)
        case .building:
            buildBuilding(size: size)
        case .crane:
            buildCrane(size: size)
        case .antenna:
            buildAntenna(size: size)
        }

        zPosition = GameConfig.ZPosition.obstacles

        if kind.isFlying {
            startFlyingAnimation()
        }
    }

    // MARK: - Obstacle Builders

    private func buildTree(size: CGSize) {
        // Trunk
        let trunk = SKShapeNode(rectOf: CGSize(width: 12, height: size.height * 0.4))
        trunk.fillColor = SKColor(hex: "#5D4037")
        trunk.strokeColor = .clear
        trunk.position = CGPoint(x: 0, y: size.height * 0.2)
        addChild(trunk)

        // Canopy
        let canopy = SKShapeNode(circleOfRadius: size.width * 0.45)
        canopy.fillColor = SKColor(hex: kind.colorHex)
        canopy.strokeColor = SKColor(hex: "#1B5E20")
        canopy.lineWidth = 1.5
        canopy.position = CGPoint(x: 0, y: size.height * 0.55)
        addChild(canopy)
        shapeNode = canopy
    }

    private func buildBarn(size: CGSize) {
        // Main body
        let body = SKShapeNode(rectOf: size)
        body.fillColor = SKColor(hex: "#C62828")
        body.strokeColor = SKColor(hex: "#8E0000")
        body.lineWidth = 1.5
        body.position = CGPoint(x: 0, y: size.height / 2)
        addChild(body)

        // Roof
        let roofPath = CGMutablePath()
        roofPath.move(to: CGPoint(x: -size.width * 0.55, y: size.height))
        roofPath.addLine(to: CGPoint(x: 0, y: size.height * 1.35))
        roofPath.addLine(to: CGPoint(x: size.width * 0.55, y: size.height))
        roofPath.closeSubpath()

        let roof = SKShapeNode(path: roofPath)
        roof.fillColor = SKColor(hex: "#5D4037")
        roof.strokeColor = .clear
        addChild(roof)
        shapeNode = body
    }

    private func buildBird(size: CGSize) {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -size.width / 2, y: size.height * 0.3))
        path.addQuadCurve(to: CGPoint(x: 0, y: 0),
                          control: CGPoint(x: -size.width * 0.2, y: size.height * 0.5))
        path.addQuadCurve(to: CGPoint(x: size.width / 2, y: size.height * 0.3),
                          control: CGPoint(x: size.width * 0.2, y: size.height * 0.5))
        path.addLine(to: CGPoint(x: size.width * 0.55, y: size.height * 0.1))

        let bird = SKShapeNode(path: path)
        bird.fillColor = SKColor(hex: kind.colorHex)
        bird.strokeColor = .clear
        addChild(bird)
        shapeNode = bird
    }

    private func buildWindmill(size: CGSize) {
        // Tower
        let tower = SKShapeNode(rectOf: CGSize(width: 10, height: size.height))
        tower.fillColor = SKColor(hex: "#BDBDBD")
        tower.strokeColor = .clear
        tower.position = CGPoint(x: 0, y: size.height / 2)
        addChild(tower)

        // Blades
        let blades = SKNode()
        for i in 0..<4 {
            let blade = SKShapeNode(rectOf: CGSize(width: 6, height: 30))
            blade.fillColor = .white
            blade.strokeColor = .clear
            blade.position = CGPoint(x: 0, y: 15)
            blade.zRotation = CGFloat(i) * .pi / 2
            blades.addChild(blade)
        }
        blades.position = CGPoint(x: 0, y: size.height)
        addChild(blades)

        let spin = SKAction.rotate(byAngle: .pi * 2, duration: 3.0)
        blades.run(SKAction.repeatForever(spin))

        shapeNode = tower
        detailNode = blades
    }

    private func buildPeak(size: CGSize) {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -size.width / 2, y: 0))
        path.addLine(to: CGPoint(x: -size.width * 0.1, y: size.height * 0.85))
        path.addLine(to: CGPoint(x: 0, y: size.height))
        path.addLine(to: CGPoint(x: size.width * 0.15, y: size.height * 0.8))
        path.addLine(to: CGPoint(x: size.width / 2, y: 0))
        path.closeSubpath()

        let peak = SKShapeNode(path: path)
        peak.fillColor = SKColor(hex: kind.colorHex)
        peak.strokeColor = SKColor(hex: "#3E2723")
        peak.lineWidth = 1
        addChild(peak)

        // Snow cap
        let snowPath = CGMutablePath()
        snowPath.move(to: CGPoint(x: -size.width * 0.12, y: size.height * 0.82))
        snowPath.addLine(to: CGPoint(x: 0, y: size.height))
        snowPath.addLine(to: CGPoint(x: size.width * 0.15, y: size.height * 0.78))
        snowPath.closeSubpath()

        let snow = SKShapeNode(path: snowPath)
        snow.fillColor = .white
        snow.strokeColor = .clear
        addChild(snow)

        shapeNode = peak
    }

    private func buildCloud(size: CGSize) {
        let cloud = SKNode()

        let radii: [CGFloat] = [18, 24, 20, 16]
        let positions: [CGPoint] = [
            CGPoint(x: -25, y: 0),
            CGPoint(x: -5, y: 8),
            CGPoint(x: 18, y: 2),
            CGPoint(x: 32, y: -4)
        ]

        for (i, radius) in radii.enumerated() {
            let circle = SKShapeNode(circleOfRadius: radius)
            circle.fillColor = SKColor(hex: kind.colorHex).withAlphaComponent(0.85)
            circle.strokeColor = .clear
            circle.position = positions[i]
            cloud.addChild(circle)
        }

        addChild(cloud)
        shapeNode = SKShapeNode(circleOfRadius: size.width / 2)
    }

    private func buildPine(size: CGSize) {
        // Trunk
        let trunk = SKShapeNode(rectOf: CGSize(width: 8, height: size.height * 0.3))
        trunk.fillColor = SKColor(hex: "#5D4037")
        trunk.strokeColor = .clear
        trunk.position = CGPoint(x: 0, y: size.height * 0.15)
        addChild(trunk)

        // Triangular layers
        for i in 0..<3 {
            let yBase = size.height * (0.25 + CGFloat(i) * 0.25)
            let layerWidth = size.width * (1.0 - CGFloat(i) * 0.2)
            let layerHeight = size.height * 0.35

            let path = CGMutablePath()
            path.move(to: CGPoint(x: -layerWidth / 2, y: yBase))
            path.addLine(to: CGPoint(x: 0, y: yBase + layerHeight))
            path.addLine(to: CGPoint(x: layerWidth / 2, y: yBase))
            path.closeSubpath()

            let layer = SKShapeNode(path: path)
            layer.fillColor = SKColor(hex: kind.colorHex)
            layer.strokeColor = SKColor(hex: "#0D3311")
            layer.lineWidth = 0.5
            addChild(layer)
        }

        shapeNode = SKShapeNode(rectOf: size)
    }

    private func buildBuilding(size: CGSize) {
        let body = SKShapeNode(rectOf: size)
        body.fillColor = SKColor(hex: kind.colorHex)
        body.strokeColor = SKColor(hex: "#37474F")
        body.lineWidth = 1
        body.position = CGPoint(x: 0, y: size.height / 2)
        addChild(body)

        // Windows
        let windowRows = Int(size.height / 25)
        let windowCols = Int(size.width / 22)
        for row in 0..<windowRows {
            for col in 0..<windowCols {
                let window = SKShapeNode(rectOf: CGSize(width: 10, height: 12))
                let isLit = Bool.random()
                window.fillColor = isLit ? SKColor(hex: "#FFF176") : SKColor(hex: "#263238")
                window.strokeColor = .clear
                window.position = CGPoint(
                    x: -size.width / 2 + 14 + CGFloat(col) * 20,
                    y: 10 + CGFloat(row) * 24
                )
                addChild(window)
            }
        }

        shapeNode = body
    }

    private func buildCrane(size: CGSize) {
        // Tower
        let tower = SKShapeNode(rectOf: CGSize(width: 8, height: size.height))
        tower.fillColor = SKColor(hex: kind.colorHex)
        tower.strokeColor = .clear
        tower.position = CGPoint(x: 0, y: size.height / 2)
        addChild(tower)

        // Arm
        let arm = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: 6))
        arm.fillColor = SKColor(hex: kind.colorHex)
        arm.strokeColor = .clear
        arm.position = CGPoint(x: size.width * 0.4, y: size.height)
        addChild(arm)

        shapeNode = tower
    }

    private func buildAntenna(size: CGSize) {
        let pole = SKShapeNode(rectOf: CGSize(width: 4, height: size.height))
        pole.fillColor = SKColor(hex: kind.colorHex)
        pole.strokeColor = .clear
        pole.position = CGPoint(x: 0, y: size.height / 2)
        addChild(pole)

        // Blinking light
        let light = SKShapeNode(circleOfRadius: 4)
        light.fillColor = .red
        light.strokeColor = .clear
        light.glowWidth = 4
        light.position = CGPoint(x: 0, y: size.height)
        addChild(light)

        let blink = SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.fadeIn(withDuration: 0.5)
        ])
        light.run(SKAction.repeatForever(blink))

        shapeNode = pole
    }

    // MARK: - Physics

    private func setupPhysics() {
        let size = kind.size
        let body: SKPhysicsBody

        if kind.isFlying {
            body = SKPhysicsBody(circleOfRadius: max(size.width, size.height) * 0.4)
        } else {
            body = SKPhysicsBody(rectangleOf: CGSize(width: size.width * 0.8, height: size.height * 0.9),
                                 center: CGPoint(x: 0, y: size.height / 2))
        }

        body.isDynamic = false
        body.categoryBitMask = GameConfig.PhysicsCategory.obstacle
        body.contactTestBitMask = GameConfig.PhysicsCategory.plane
        body.collisionBitMask = GameConfig.PhysicsCategory.none
        physicsBody = body
    }

    // MARK: - Flying Animation

    private func startFlyingAnimation() {
        if kind == .bird {
            let moveLeft = SKAction.moveBy(x: -GameConfig.Obstacles.birdSpeed, y: 0, duration: 1.0)
            let oscillate = SKAction.moveBy(x: 0, y: GameConfig.Obstacles.birdOscillation, duration: 0.5)
            let oscillateBack = SKAction.moveBy(x: 0, y: -GameConfig.Obstacles.birdOscillation, duration: 0.5)
            let wingFlap = SKAction.sequence([oscillate, oscillateBack])

            run(SKAction.repeatForever(SKAction.group([moveLeft, wingFlap])))
        } else if kind == .cloud {
            let drift = SKAction.moveBy(x: -30, y: 0, duration: 2.0)
            let driftBack = SKAction.moveBy(x: 30, y: 0, duration: 2.0)
            run(SKAction.repeatForever(SKAction.sequence([drift, driftBack])))
        }
    }

    // MARK: - Destruction

    func destroy() {
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let scale = SKAction.scale(to: 1.3, duration: 0.3)
        let remove = SKAction.removeFromParent()
        run(SKAction.sequence([SKAction.group([fadeOut, scale]), remove]))
    }
}
