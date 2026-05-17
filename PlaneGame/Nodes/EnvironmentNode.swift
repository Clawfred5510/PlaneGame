import SpriteKit

// MARK: - EnvironmentNode

final class EnvironmentNode: SKNode {

    // MARK: - Properties

    private let environment: EnvironmentModel
    private var parallaxLayers: [ParallaxLayer] = []
    private var groundNode: SKNode!
    private var groundSegments: [SKShapeNode] = []
    private let screenSize: CGSize

    private var lastCameraX: CGFloat = 0

    // MARK: - Init

    init(environment: EnvironmentModel, screenSize: CGSize) {
        self.environment = environment
        self.screenSize = screenSize
        super.init()
        buildEnvironment()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    // MARK: - Build

    private func buildEnvironment() {
        buildSky()
        buildParallaxLayers()
        buildGround()
    }

    private func buildSky() {
        let skySize = CGSize(width: screenSize.width * 3, height: screenSize.height * 2)
        let skyNode = SKShapeNode(rectOf: skySize)

        let topColor = SKColor(hex: environment.skyColorTop)
        let bottomColor = SKColor(hex: environment.skyColorBottom)

        // Use a gradient approximation: two overlapping rects
        let topHalf = SKShapeNode(rectOf: CGSize(width: skySize.width, height: skySize.height / 2))
        topHalf.fillColor = topColor
        topHalf.strokeColor = .clear
        topHalf.position = CGPoint(x: 0, y: skySize.height / 4)
        topHalf.zPosition = GameConfig.ZPosition.background

        let bottomHalf = SKShapeNode(rectOf: CGSize(width: skySize.width, height: skySize.height / 2))
        bottomHalf.fillColor = bottomColor
        bottomHalf.strokeColor = .clear
        bottomHalf.position = CGPoint(x: 0, y: -skySize.height / 4)
        bottomHalf.zPosition = GameConfig.ZPosition.background

        skyNode.addChild(topHalf)
        skyNode.addChild(bottomHalf)
        skyNode.strokeColor = .clear
        skyNode.fillColor = .clear
        skyNode.position = CGPoint(x: screenSize.width / 2, y: screenSize.height)
        skyNode.zPosition = GameConfig.ZPosition.background
        addChild(skyNode)
    }

    private func buildParallaxLayers() {
        let configs = environment.parallaxLayers

        for (index, config) in configs.enumerated() {
            let zPos: CGFloat
            switch index {
            case 0: zPos = GameConfig.ZPosition.parallaxFar
            case 1: zPos = GameConfig.ZPosition.parallaxMid
            default: zPos = GameConfig.ZPosition.parallaxNear + CGFloat(index)
            }

            let layer = ParallaxLayer(
                config: config,
                screenSize: screenSize,
                zPos: zPos,
                environment: environment.type
            )
            addChild(layer)
            parallaxLayers.append(layer)
        }
    }

    private func buildGround() {
        groundNode = SKNode()
        groundNode.zPosition = GameConfig.ZPosition.ground
        addChild(groundNode)

        // Initial ground segments
        for i in -1...3 {
            addGroundSegment(at: CGFloat(i) * screenSize.width)
        }

        // Physics ground
        let groundBody = SKPhysicsBody(
            edgeFrom: CGPoint(x: -10000, y: GameConfig.World.groundY),
            to: CGPoint(x: 100000, y: GameConfig.World.groundY)
        )
        groundBody.categoryBitMask = GameConfig.PhysicsCategory.ground
        groundBody.contactTestBitMask = GameConfig.PhysicsCategory.plane
        groundBody.friction = 0.8
        groundBody.restitution = GameConfig.Plane.groundBounceRestitution
        groundNode.physicsBody = groundBody
    }

    private func addGroundSegment(at x: CGFloat) {
        let segWidth = screenSize.width + 2 // slight overlap
        let segHeight = GameConfig.World.groundY

        let segment = SKShapeNode(rectOf: CGSize(width: segWidth, height: segHeight))
        segment.fillColor = SKColor(hex: environment.groundColor)
        segment.strokeColor = .clear
        segment.position = CGPoint(x: x + segWidth / 2, y: segHeight / 2)
        groundNode.addChild(segment)
        groundSegments.append(segment)

        // Ground detail - grass tufts or terrain
        addGroundDetail(to: segment, width: segWidth, height: segHeight)
    }

    private func addGroundDetail(to segment: SKShapeNode, width: CGFloat, height: CGFloat) {
        let detailCount = Int(width / 30)
        for _ in 0..<detailCount {
            let tuft = SKShapeNode(circleOfRadius: CGFloat.random(in: 3...8))
            let darkerGround = SKColor(hex: environment.groundColor).withAlphaComponent(0.7)
            tuft.fillColor = darkerGround
            tuft.strokeColor = .clear
            tuft.position = CGPoint(
                x: CGFloat.random(in: -width/2...width/2),
                y: height / 2 + CGFloat.random(in: -5...5)
            )
            segment.addChild(tuft)
        }
    }

    // MARK: - Update (Camera-based parallax)

    func update(cameraX: CGFloat) {
        let delta = cameraX - lastCameraX
        lastCameraX = cameraX

        for layer in parallaxLayers {
            layer.scroll(delta: delta)
        }

        // Recycle ground segments
        recycleGroundIfNeeded(cameraX: cameraX)
    }

    private func recycleGroundIfNeeded(cameraX: CGFloat) {
        let leftBound = cameraX - screenSize.width
        let rightBound = cameraX + screenSize.width * 2

        for segment in groundSegments {
            if segment.position.x + screenSize.width / 2 < leftBound {
                // Move to right side
                if let maxX = groundSegments.map({ $0.position.x }).max() {
                    segment.position.x = maxX + screenSize.width
                }
            }
        }

        // Add new segments if needed
        if let maxX = groundSegments.map({ $0.position.x }).max(), maxX < rightBound {
            addGroundSegment(at: maxX + screenSize.width / 2)
        }
    }
}

// MARK: - ParallaxLayer

final class ParallaxLayer: SKNode {

    private let config: ParallaxLayerConfig
    private let screenSize: CGSize
    private var segments: [SKNode] = []
    private let segmentWidth: CGFloat

    init(config: ParallaxLayerConfig, screenSize: CGSize, zPos: CGFloat, environment: EnvironmentType) {
        self.config = config
        self.screenSize = screenSize
        self.segmentWidth = screenSize.width + 4
        super.init()

        zPosition = zPos
        buildSegments(environment: environment)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    private func buildSegments(environment: EnvironmentType) {
        let segCount = 4 // enough to cover screen + buffer

        for i in 0..<segCount {
            let segment = createSegment(environment: environment)
            segment.position = CGPoint(x: CGFloat(i) * segmentWidth, y: config.yOffset * screenSize.height)
            addChild(segment)
            segments.append(segment)
        }
    }

    private func createSegment(environment: EnvironmentType) -> SKNode {
        let node = SKNode()
        let height = config.height * screenSize.height

        let bg = SKShapeNode(rectOf: CGSize(width: segmentWidth, height: height))
        bg.fillColor = SKColor(hex: config.colorHex).withAlphaComponent(0.4)
        bg.strokeColor = .clear
        bg.position = CGPoint(x: 0, y: height / 2)
        node.addChild(bg)

        // Add silhouette details based on layer depth and environment
        if config.speedRatio > 0.4 {
            addSilhouettes(to: node, height: height, environment: environment)
        }

        return node
    }

    private func addSilhouettes(to node: SKNode, height: CGFloat, environment: EnvironmentType) {
        let count = Int.random(in: 2...5)
        for _ in 0..<count {
            let silhouette: SKShapeNode
            switch environment {
            case .countryside:
                let w = CGFloat.random(in: 20...40)
                let h = CGFloat.random(in: 30...60)
                silhouette = SKShapeNode(rectOf: CGSize(width: w, height: h), cornerRadius: w * 0.3)
            case .mountains:
                let path = CGMutablePath()
                let w = CGFloat.random(in: 40...100)
                let h = CGFloat.random(in: 40...90)
                path.move(to: CGPoint(x: -w/2, y: 0))
                path.addLine(to: CGPoint(x: 0, y: h))
                path.addLine(to: CGPoint(x: w/2, y: 0))
                path.closeSubpath()
                silhouette = SKShapeNode(path: path)
            case .city:
                let w = CGFloat.random(in: 15...45)
                let h = CGFloat.random(in: 40...120)
                silhouette = SKShapeNode(rectOf: CGSize(width: w, height: h))
            }

            silhouette.fillColor = SKColor(hex: config.colorHex).withAlphaComponent(0.6)
            silhouette.strokeColor = .clear
            silhouette.position = CGPoint(
                x: CGFloat.random(in: -segmentWidth/2...segmentWidth/2),
                y: CGFloat.random(in: 0...height * 0.6)
            )
            node.addChild(silhouette)
        }
    }

    func scroll(delta: CGFloat) {
        let scrollAmount = delta * config.speedRatio

        for segment in segments {
            segment.position.x -= scrollAmount
        }

        // Recycle segments
        let leftBound = -segmentWidth * 1.5
        let rightBound = segmentWidth * CGFloat(segments.count)

        for segment in segments {
            if segment.position.x < leftBound {
                if let maxX = segments.map({ $0.position.x }).max() {
                    segment.position.x = maxX + segmentWidth
                }
            } else if segment.position.x > rightBound {
                if let minX = segments.map({ $0.position.x }).min() {
                    segment.position.x = minX - segmentWidth
                }
            }
        }
    }
}
