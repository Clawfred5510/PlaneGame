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
    private var weatherEmitter: SKEmitterNode?

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
        buildCelestialBody()
        buildParallaxLayers()
        buildGround()
        buildWeatherEffects()
    }

    // MARK: - Sky (Multi-band gradient)

    private func buildSky() {
        let skyWidth = screenSize.width * 4
        let skyHeight = screenSize.height * 2.5

        // Create multi-band gradient sky using layered rectangles
        let bandCount = 8
        let bandHeight = skyHeight / CGFloat(bandCount)

        let topColor = SKColor(hex: environment.skyColorTop)
        let bottomColor = SKColor(hex: environment.skyColorBottom)

        let skyContainer = SKNode()
        skyContainer.zPosition = GameConfig.ZPosition.background

        for i in 0..<bandCount {
            let t = CGFloat(i) / CGFloat(bandCount - 1)
            let bandColor = interpolateColor(from: topColor, to: bottomColor, fraction: t)

            let band = SKShapeNode(rectOf: CGSize(width: skyWidth, height: bandHeight + 2))
            band.fillColor = bandColor
            band.strokeColor = .clear
            band.position = CGPoint(x: screenSize.width / 2,
                                    y: skyHeight - CGFloat(i) * bandHeight - bandHeight / 2)
            skyContainer.addChild(band)
        }

        addChild(skyContainer)
    }

    // MARK: - Celestial Body (Sun or Moon)

    private func buildCelestialBody() {
        switch environment.type {
        case .countryside:
            // Bright sun with rays
            let sun = SKShapeNode(circleOfRadius: 35)
            sun.fillColor = SKColor(hex: "#FFF176")
            sun.strokeColor = .clear
            sun.glowWidth = 20
            sun.position = CGPoint(x: screenSize.width * 0.8, y: screenSize.height * 1.6)
            sun.zPosition = GameConfig.ZPosition.background + 1

            // Sun corona
            let corona = SKShapeNode(circleOfRadius: 50)
            corona.fillColor = SKColor(hex: "#FFF9C4").withAlphaComponent(0.2)
            corona.strokeColor = .clear
            corona.glowWidth = 30
            sun.addChild(corona)

            // Subtle pulse
            let pulse = SKAction.sequence([
                SKAction.scale(to: 1.05, duration: 2.0),
                SKAction.scale(to: 0.95, duration: 2.0)
            ])
            sun.run(SKAction.repeatForever(pulse))

            addChild(sun)

        case .mountains:
            // Sunset/dusk - large orange/pink sun near horizon
            let sun = SKShapeNode(circleOfRadius: 45)
            sun.fillColor = SKColor(hex: "#FF8A65")
            sun.strokeColor = .clear
            sun.glowWidth = 25
            sun.position = CGPoint(x: screenSize.width * 0.7, y: screenSize.height * 0.9)
            sun.zPosition = GameConfig.ZPosition.background + 1

            let halo = SKShapeNode(circleOfRadius: 70)
            halo.fillColor = SKColor(hex: "#FFAB91").withAlphaComponent(0.15)
            halo.strokeColor = .clear
            halo.glowWidth = 40
            sun.addChild(halo)

            addChild(sun)

        case .city:
            // Golden hour sun, lower in sky
            let sun = SKShapeNode(circleOfRadius: 40)
            sun.fillColor = SKColor(hex: "#FFCC02")
            sun.strokeColor = .clear
            sun.glowWidth = 30
            sun.position = CGPoint(x: screenSize.width * 0.3, y: screenSize.height * 1.2)
            sun.zPosition = GameConfig.ZPosition.background + 1

            let haze = SKShapeNode(circleOfRadius: 65)
            haze.fillColor = SKColor(hex: "#FFE082").withAlphaComponent(0.12)
            haze.strokeColor = .clear
            haze.glowWidth = 35
            sun.addChild(haze)

            addChild(sun)
        }
    }

    // MARK: - Parallax Layers

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

    // MARK: - Ground

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
        let segWidth = screenSize.width + 2
        let segHeight = GameConfig.World.groundY

        // Main ground fill
        let segment = SKShapeNode(rectOf: CGSize(width: segWidth, height: segHeight))
        segment.fillColor = SKColor(hex: environment.groundColor)
        segment.strokeColor = .clear
        segment.position = CGPoint(x: x + segWidth / 2, y: segHeight / 2)
        groundNode.addChild(segment)
        groundSegments.append(segment)

        // Surface detail layer based on environment type
        addGroundSurface(to: segment, width: segWidth, height: segHeight)
        addGroundDetail(to: segment, width: segWidth, height: segHeight)
    }

    private func addGroundSurface(to segment: SKShapeNode, width: CGFloat, height: CGFloat) {
        // Top surface strip (slightly different shade for depth)
        let surfaceHeight: CGFloat = 8
        let surface = SKShapeNode(rectOf: CGSize(width: width, height: surfaceHeight))
        surface.position = CGPoint(x: 0, y: height / 2 - surfaceHeight / 2)
        surface.strokeColor = .clear

        switch environment.type {
        case .countryside:
            surface.fillColor = SKColor(hex: "#388E3C") // darker green top line
        case .mountains:
            surface.fillColor = SKColor(hex: "#6D4C41") // darker brown
        case .city:
            surface.fillColor = SKColor(hex: "#616161") // asphalt dark
        }
        segment.addChild(surface)
    }

    private func addGroundDetail(to segment: SKShapeNode, width: CGFloat, height: CGFloat) {
        switch environment.type {
        case .countryside:
            addCountrysideGroundDetail(to: segment, width: width, height: height)
        case .mountains:
            addMountainsGroundDetail(to: segment, width: width, height: height)
        case .city:
            addCityGroundDetail(to: segment, width: width, height: height)
        }
    }

    private func addCountrysideGroundDetail(to segment: SKShapeNode, width: CGFloat, height: CGFloat) {
        // Grass blades on top
        let grassCount = Int(width / 8)
        for _ in 0..<grassCount {
            let grassHeight = CGFloat.random(in: 4...10)
            let grassPath = CGMutablePath()
            let baseX = CGFloat.random(in: -width / 2...width / 2)
            let baseY = height / 2
            grassPath.move(to: CGPoint(x: baseX, y: baseY))
            grassPath.addQuadCurve(to: CGPoint(x: baseX + CGFloat.random(in: -3...3), y: baseY + grassHeight),
                                    control: CGPoint(x: baseX + CGFloat.random(in: -2...2), y: baseY + grassHeight * 0.6))

            let grass = SKShapeNode(path: grassPath)
            grass.strokeColor = SKColor(hex: "#2E7D32").withAlphaComponent(CGFloat.random(in: 0.5...0.9))
            grass.lineWidth = CGFloat.random(in: 1...2)
            grass.lineCap = .round
            segment.addChild(grass)
        }

        // Small flowers scattered
        let flowerCount = Int(width / 60)
        for _ in 0..<flowerCount {
            let flower = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...3))
            let colors = ["#FF5722", "#FFC107", "#E91E63", "#9C27B0", "#FFFFFF"]
            flower.fillColor = SKColor(hex: colors.randomElement()!)
            flower.strokeColor = .clear
            flower.position = CGPoint(x: CGFloat.random(in: -width / 2...width / 2),
                                       y: height / 2 + CGFloat.random(in: 2...8))
            segment.addChild(flower)
        }

        // Occasional fence posts
        if Bool.random() {
            let postX = CGFloat.random(in: -width / 3...width / 3)
            let post = SKShapeNode(rectOf: CGSize(width: 3, height: 18))
            post.fillColor = SKColor(hex: "#795548")
            post.strokeColor = .clear
            post.position = CGPoint(x: postX, y: height / 2 + 9)
            segment.addChild(post)

            // Horizontal rail
            let rail = SKShapeNode(rectOf: CGSize(width: 40, height: 2))
            rail.fillColor = SKColor(hex: "#795548")
            rail.strokeColor = .clear
            rail.position = CGPoint(x: postX, y: height / 2 + 14)
            segment.addChild(rail)
        }
    }

    private func addMountainsGroundDetail(to segment: SKShapeNode, width: CGFloat, height: CGFloat) {
        // Rocky terrain - scattered stones
        let stoneCount = Int(width / 25)
        for _ in 0..<stoneCount {
            let stoneW = CGFloat.random(in: 4...12)
            let stoneH = CGFloat.random(in: 3...7)
            let stone = SKShapeNode(ellipseOf: CGSize(width: stoneW, height: stoneH))
            stone.fillColor = SKColor(hex: "#9E9E9E").withAlphaComponent(CGFloat.random(in: 0.4...0.8))
            stone.strokeColor = .clear
            stone.position = CGPoint(x: CGFloat.random(in: -width / 2...width / 2),
                                      y: height / 2 + CGFloat.random(in: -3...3))
            segment.addChild(stone)
        }

        // Small bushes
        let bushCount = Int(width / 80)
        for _ in 0..<bushCount {
            let bush = SKShapeNode(ellipseOf: CGSize(width: CGFloat.random(in: 10...18),
                                                      height: CGFloat.random(in: 6...10)))
            bush.fillColor = SKColor(hex: "#33691E").withAlphaComponent(0.7)
            bush.strokeColor = .clear
            bush.position = CGPoint(x: CGFloat.random(in: -width / 2...width / 2),
                                     y: height / 2 + CGFloat.random(in: 2...6))
            segment.addChild(bush)
        }
    }

    private func addCityGroundDetail(to segment: SKShapeNode, width: CGFloat, height: CGFloat) {
        // Road lane markings (dashed white lines)
        let dashCount = Int(width / 50)
        for i in 0..<dashCount {
            let dash = SKShapeNode(rectOf: CGSize(width: 25, height: 3), cornerRadius: 1)
            dash.fillColor = SKColor(hex: "#FFFFFF").withAlphaComponent(0.7)
            dash.strokeColor = .clear
            dash.position = CGPoint(x: -width / 2 + CGFloat(i) * 50 + 25,
                                     y: height / 2 - 15)
            segment.addChild(dash)
        }

        // Sidewalk curb
        let curb = SKShapeNode(rectOf: CGSize(width: width, height: 4))
        curb.fillColor = SKColor(hex: "#9E9E9E")
        curb.strokeColor = .clear
        curb.position = CGPoint(x: 0, y: height / 2 - 2)
        segment.addChild(curb)

        // Manhole cover or grate occasionally
        if Bool.random() {
            let manhole = SKShapeNode(circleOfRadius: 6)
            manhole.fillColor = SKColor(hex: "#424242")
            manhole.strokeColor = SKColor(hex: "#616161")
            manhole.lineWidth = 1
            manhole.position = CGPoint(x: CGFloat.random(in: -width / 3...width / 3),
                                        y: height / 2 - 10)
            segment.addChild(manhole)
        }
    }

    // MARK: - Weather Effects

    private func buildWeatherEffects() {
        switch environment.type {
        case .countryside:
            buildButterflyParticles()
        case .mountains:
            buildSnowParticles()
        case .city:
            buildLeafParticles()
        }
    }

    private func buildButterflyParticles() {
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 1.5
        emitter.particleLifetime = 5.0
        emitter.particleLifetimeRange = 2.0
        emitter.particleSpeed = 15
        emitter.particleSpeedRange = 10
        emitter.emissionAngle = .pi / 4
        emitter.emissionAngleRange = .pi
        emitter.particleScale = 0.06
        emitter.particleScaleRange = 0.03
        emitter.particleAlpha = 0.7
        emitter.particleAlphaSpeed = -0.1
        emitter.particleColor = SKColor(hex: "#FFEB3B")
        emitter.particleColorBlendFactor = 1.0
        emitter.particleColorSequence = SKKeyframeSequence(
            keyframeValues: [SKColor(hex: "#FF9800"), SKColor(hex: "#FFEB3B"), SKColor(hex: "#8BC34A")],
            times: [0 as NSNumber, 0.5 as NSNumber, 1.0 as NSNumber]
        )
        let tex = SKTexture.placeholder(color: .white, size: CGSize(width: 6, height: 6))
        emitter.particleTexture = tex
        emitter.position = CGPoint(x: screenSize.width / 2, y: screenSize.height * 0.7)
        emitter.particlePositionRange = CGVector(dx: screenSize.width * 2, dy: screenSize.height * 0.5)
        emitter.zPosition = GameConfig.ZPosition.particles - 5
        addChild(emitter)
        weatherEmitter = emitter
    }

    private func buildSnowParticles() {
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 20
        emitter.particleLifetime = 8.0
        emitter.particleLifetimeRange = 3.0
        emitter.particleSpeed = 25
        emitter.particleSpeedRange = 15
        emitter.emissionAngle = -.pi / 2 - 0.2 // slightly angled
        emitter.emissionAngleRange = 0.4
        emitter.particleScale = 0.05
        emitter.particleScaleRange = 0.04
        emitter.particleAlpha = 0.8
        emitter.particleAlphaRange = 0.2
        emitter.particleAlphaSpeed = -0.08
        emitter.particleColor = .white
        emitter.particleColorBlendFactor = 1.0
        let tex = SKTexture.placeholder(color: .white, size: CGSize(width: 6, height: 6))
        emitter.particleTexture = tex
        emitter.position = CGPoint(x: screenSize.width / 2, y: screenSize.height * 2)
        emitter.particlePositionRange = CGVector(dx: screenSize.width * 3, dy: 0)
        emitter.zPosition = GameConfig.ZPosition.particles - 5
        emitter.targetNode = self
        addChild(emitter)
        weatherEmitter = emitter
    }

    private func buildLeafParticles() {
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 3
        emitter.particleLifetime = 6.0
        emitter.particleLifetimeRange = 2.0
        emitter.particleSpeed = 30
        emitter.particleSpeedRange = 20
        emitter.emissionAngle = .pi + 0.3 // blowing left with slight downward
        emitter.emissionAngleRange = 0.6
        emitter.particleScale = 0.06
        emitter.particleScaleRange = 0.04
        emitter.particleAlpha = 0.6
        emitter.particleAlphaSpeed = -0.08
        emitter.particleRotation = 0
        emitter.particleRotationRange = .pi
        emitter.particleRotationSpeed = 2.0
        emitter.particleColor = SKColor(hex: "#8D6E63")
        emitter.particleColorBlendFactor = 1.0
        emitter.particleColorSequence = SKKeyframeSequence(
            keyframeValues: [SKColor(hex: "#F5F5F5"), SKColor(hex: "#BCAAA4"), SKColor(hex: "#8D6E63")],
            times: [0 as NSNumber, 0.4 as NSNumber, 1.0 as NSNumber]
        )
        let tex = SKTexture.placeholder(color: .white, size: CGSize(width: 8, height: 5))
        emitter.particleTexture = tex
        emitter.position = CGPoint(x: screenSize.width * 1.5, y: screenSize.height * 0.8)
        emitter.particlePositionRange = CGVector(dx: screenSize.width, dy: screenSize.height * 0.5)
        emitter.zPosition = GameConfig.ZPosition.particles - 5
        addChild(emitter)
        weatherEmitter = emitter
    }

    // MARK: - Color Interpolation

    private func interpolateColor(from: SKColor, to: SKColor, fraction: CGFloat) -> SKColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        from.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        to.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

        let t = fraction.clamped(to: 0...1)
        return SKColor(red: r1 + (r2 - r1) * t,
                       green: g1 + (g2 - g1) * t,
                       blue: b1 + (b2 - b1) * t,
                       alpha: a1 + (a2 - a1) * t)
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
        let segCount = 4

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

        switch environment {
        case .countryside:
            createCountrysideSegment(node: node, height: height)
        case .mountains:
            createMountainsSegment(node: node, height: height)
        case .city:
            createCitySegment(node: node, height: height)
        }

        return node
    }

    // MARK: - Countryside Parallax Segments

    private func createCountrysideSegment(node: SKNode, height: CGFloat) {
        if config.speedRatio < 0.2 {
            // Far layer - distant rolling hills
            let hillPath = CGMutablePath()
            hillPath.move(to: CGPoint(x: -segmentWidth / 2, y: 0))

            var x: CGFloat = -segmentWidth / 2
            while x < segmentWidth / 2 {
                let peakHeight = CGFloat.random(in: height * 0.4...height * 0.8)
                let hillWidth = CGFloat.random(in: 80...160)
                hillPath.addQuadCurve(to: CGPoint(x: x + hillWidth, y: 0),
                                       control: CGPoint(x: x + hillWidth / 2, y: peakHeight))
                x += hillWidth
            }
            hillPath.addLine(to: CGPoint(x: segmentWidth / 2, y: 0))
            hillPath.closeSubpath()

            let hills = SKShapeNode(path: hillPath)
            hills.fillColor = SKColor(hex: "#81C784").withAlphaComponent(0.5)
            hills.strokeColor = .clear
            node.addChild(hills)

        } else if config.speedRatio < 0.4 {
            // Mid layer - trees and farmhouses silhouette
            let bgRect = SKShapeNode(rectOf: CGSize(width: segmentWidth, height: height * 0.3))
            bgRect.fillColor = SKColor(hex: "#66BB6A").withAlphaComponent(0.3)
            bgRect.strokeColor = .clear
            bgRect.position = CGPoint(x: 0, y: height * 0.15)
            node.addChild(bgRect)

            // Tree silhouettes
            let treeCount = Int.random(in: 3...6)
            for _ in 0..<treeCount {
                let treeX = CGFloat.random(in: -segmentWidth / 2...segmentWidth / 2)
                let treeH = CGFloat.random(in: 25...50)

                // Trunk
                let trunk = SKShapeNode(rectOf: CGSize(width: 4, height: treeH * 0.4))
                trunk.fillColor = SKColor(hex: "#5D4037").withAlphaComponent(0.6)
                trunk.strokeColor = .clear
                trunk.position = CGPoint(x: treeX, y: treeH * 0.2)
                node.addChild(trunk)

                // Canopy
                let canopy = SKShapeNode(circleOfRadius: treeH * 0.35)
                canopy.fillColor = SKColor(hex: "#388E3C").withAlphaComponent(0.6)
                canopy.strokeColor = .clear
                canopy.position = CGPoint(x: treeX, y: treeH * 0.55)
                node.addChild(canopy)
            }

            // Small farmhouse
            if Bool.random() {
                let houseX = CGFloat.random(in: -segmentWidth / 3...segmentWidth / 3)
                let house = SKShapeNode(rectOf: CGSize(width: 20, height: 15))
                house.fillColor = SKColor(hex: "#FFECB3").withAlphaComponent(0.5)
                house.strokeColor = .clear
                house.position = CGPoint(x: houseX, y: 10)
                node.addChild(house)

                let roofPath = CGMutablePath()
                roofPath.move(to: CGPoint(x: houseX - 12, y: 18))
                roofPath.addLine(to: CGPoint(x: houseX, y: 28))
                roofPath.addLine(to: CGPoint(x: houseX + 12, y: 18))
                roofPath.closeSubpath()
                let roof = SKShapeNode(path: roofPath)
                roof.fillColor = SKColor(hex: "#8D6E63").withAlphaComponent(0.5)
                roof.strokeColor = .clear
                node.addChild(roof)
            }

        } else if config.speedRatio < 0.8 {
            // Near layer - grass, flowers, fence posts closer
            let grassLineCount = Int.random(in: 5...10)
            for _ in 0..<grassLineCount {
                let grassX = CGFloat.random(in: -segmentWidth / 2...segmentWidth / 2)
                let grassH = CGFloat.random(in: 8...20)
                let grassPath = CGMutablePath()
                grassPath.move(to: CGPoint(x: grassX, y: 0))
                grassPath.addQuadCurve(to: CGPoint(x: grassX + CGFloat.random(in: -4...4), y: grassH),
                                        control: CGPoint(x: grassX + CGFloat.random(in: -3...3), y: grassH * 0.6))
                let grass = SKShapeNode(path: grassPath)
                grass.strokeColor = SKColor(hex: "#43A047").withAlphaComponent(0.7)
                grass.lineWidth = 2
                grass.lineCap = .round
                node.addChild(grass)
            }
        }
    }

    // MARK: - Mountains Parallax Segments

    private func createMountainsSegment(node: SKNode, height: CGFloat) {
        if config.speedRatio < 0.2 {
            // Far layer - snow-capped mountain range silhouette
            let mountainPath = CGMutablePath()
            mountainPath.move(to: CGPoint(x: -segmentWidth / 2, y: 0))

            var x: CGFloat = -segmentWidth / 2
            while x < segmentWidth / 2 {
                let peakHeight = CGFloat.random(in: height * 0.5...height * 0.9)
                let mountainWidth = CGFloat.random(in: 60...140)
                // Jagged peaks
                mountainPath.addLine(to: CGPoint(x: x + mountainWidth * 0.4,
                                                  y: peakHeight * 0.7))
                mountainPath.addLine(to: CGPoint(x: x + mountainWidth * 0.5,
                                                  y: peakHeight))
                mountainPath.addLine(to: CGPoint(x: x + mountainWidth * 0.6,
                                                  y: peakHeight * 0.75))
                mountainPath.addLine(to: CGPoint(x: x + mountainWidth, y: 0))
                x += mountainWidth
            }
            mountainPath.addLine(to: CGPoint(x: segmentWidth / 2, y: 0))
            mountainPath.closeSubpath()

            let mountains = SKShapeNode(path: mountainPath)
            mountains.fillColor = SKColor(hex: "#546E7A").withAlphaComponent(0.6)
            mountains.strokeColor = .clear
            node.addChild(mountains)

            // Snow caps (white tips on top 20%)
            let snowPath = CGMutablePath()
            snowPath.move(to: CGPoint(x: -segmentWidth / 3, y: height * 0.7))
            snowPath.addLine(to: CGPoint(x: -segmentWidth / 3 + 15, y: height * 0.85))
            snowPath.addLine(to: CGPoint(x: -segmentWidth / 3 + 30, y: height * 0.72))
            snowPath.closeSubpath()

            let snow = SKShapeNode(path: snowPath)
            snow.fillColor = SKColor.white.withAlphaComponent(0.5)
            snow.strokeColor = .clear
            node.addChild(snow)

        } else if config.speedRatio < 0.4 {
            // Mid layer - pine tree silhouettes, rocky outcrops
            let pineCount = Int.random(in: 3...7)
            for _ in 0..<pineCount {
                let pineX = CGFloat.random(in: -segmentWidth / 2...segmentWidth / 2)
                let pineH = CGFloat.random(in: 20...50)

                let pinePath = CGMutablePath()
                pinePath.move(to: CGPoint(x: pineX - pineH * 0.3, y: 0))
                pinePath.addLine(to: CGPoint(x: pineX, y: pineH))
                pinePath.addLine(to: CGPoint(x: pineX + pineH * 0.3, y: 0))
                pinePath.closeSubpath()

                let pine = SKShapeNode(path: pinePath)
                pine.fillColor = SKColor(hex: "#1B5E20").withAlphaComponent(0.6)
                pine.strokeColor = .clear
                node.addChild(pine)
            }

            // Rocky outcrops
            if Bool.random() {
                let rockX = CGFloat.random(in: -segmentWidth / 3...segmentWidth / 3)
                let rockPath = CGMutablePath()
                rockPath.move(to: CGPoint(x: rockX - 15, y: 0))
                rockPath.addLine(to: CGPoint(x: rockX - 8, y: 20))
                rockPath.addLine(to: CGPoint(x: rockX + 5, y: 25))
                rockPath.addLine(to: CGPoint(x: rockX + 15, y: 10))
                rockPath.addLine(to: CGPoint(x: rockX + 12, y: 0))
                rockPath.closeSubpath()

                let rock = SKShapeNode(path: rockPath)
                rock.fillColor = SKColor(hex: "#78909C").withAlphaComponent(0.5)
                rock.strokeColor = .clear
                node.addChild(rock)
            }

        } else if config.speedRatio < 0.7 {
            // Closer layer - boulders, small bushes
            let boulderCount = Int.random(in: 2...4)
            for _ in 0..<boulderCount {
                let bx = CGFloat.random(in: -segmentWidth / 2...segmentWidth / 2)
                let bSize = CGFloat.random(in: 8...18)
                let boulder = SKShapeNode(ellipseOf: CGSize(width: bSize * 1.3, height: bSize))
                boulder.fillColor = SKColor(hex: "#78909C").withAlphaComponent(0.6)
                boulder.strokeColor = SKColor(hex: "#546E7A").withAlphaComponent(0.3)
                boulder.lineWidth = 1
                boulder.position = CGPoint(x: bx, y: bSize * 0.4)
                node.addChild(boulder)
            }
        }
    }

    // MARK: - City Parallax Segments

    private func createCitySegment(node: SKNode, height: CGFloat) {
        if config.speedRatio < 0.2 {
            // Far layer - city skyline silhouette
            var x: CGFloat = -segmentWidth / 2
            while x < segmentWidth / 2 {
                let bWidth = CGFloat.random(in: 25...60)
                let bHeight = CGFloat.random(in: height * 0.3...height * 0.9)

                let buildingPath = CGMutablePath()
                buildingPath.addRect(CGRect(x: x, y: 0, width: bWidth, height: bHeight))
                let building = SKShapeNode(path: buildingPath)
                building.fillColor = SKColor(hex: "#37474F").withAlphaComponent(0.7)
                building.strokeColor = .clear
                node.addChild(building)

                // Random lit windows on distant buildings
                let windowCount = Int.random(in: 2...6)
                for _ in 0..<windowCount {
                    let winX = x + CGFloat.random(in: 3...bWidth - 3)
                    let winY = CGFloat.random(in: 5...bHeight - 5)
                    let win = SKShapeNode(rectOf: CGSize(width: 3, height: 4))
                    win.fillColor = SKColor(hex: "#FFF176").withAlphaComponent(CGFloat.random(in: 0.3...0.8))
                    win.strokeColor = .clear
                    win.position = CGPoint(x: winX, y: winY)
                    node.addChild(win)
                }

                x += bWidth + CGFloat.random(in: 2...8)
            }

        } else if config.speedRatio < 0.4 {
            // Mid layer - medium buildings, billboards, water towers
            var x: CGFloat = -segmentWidth / 2
            while x < segmentWidth / 2 {
                let bWidth = CGFloat.random(in: 30...55)
                let bHeight = CGFloat.random(in: height * 0.4...height * 0.85)

                let building = SKShapeNode(rectOf: CGSize(width: bWidth, height: bHeight))
                building.fillColor = SKColor(hex: "#546E7A").withAlphaComponent(0.6)
                building.strokeColor = SKColor(hex: "#455A64").withAlphaComponent(0.4)
                building.lineWidth = 1
                building.position = CGPoint(x: x + bWidth / 2, y: bHeight / 2)
                node.addChild(building)

                // Windows
                let winCols = Int(bWidth / 12)
                let winRows = Int(bHeight / 16)
                for row in 0..<winRows {
                    for col in 0..<winCols {
                        if Bool.random() {
                            let win = SKShapeNode(rectOf: CGSize(width: 5, height: 7))
                            win.fillColor = SKColor(hex: "#FFF9C4").withAlphaComponent(CGFloat.random(in: 0.3...0.9))
                            win.strokeColor = .clear
                            win.position = CGPoint(x: x + 8 + CGFloat(col) * 11,
                                                    y: 8 + CGFloat(row) * 15)
                            node.addChild(win)
                        }
                    }
                }

                x += bWidth + CGFloat.random(in: 5...15)
            }

            // Water tower
            if Bool.random() {
                let wtX = CGFloat.random(in: -segmentWidth / 4...segmentWidth / 4)
                let wtPole = SKShapeNode(rectOf: CGSize(width: 4, height: 25))
                wtPole.fillColor = SKColor(hex: "#78909C").withAlphaComponent(0.5)
                wtPole.strokeColor = .clear
                wtPole.position = CGPoint(x: wtX, y: height * 0.7 + 12)
                node.addChild(wtPole)

                let wtTank = SKShapeNode(ellipseOf: CGSize(width: 18, height: 14))
                wtTank.fillColor = SKColor(hex: "#607D8B").withAlphaComponent(0.5)
                wtTank.strokeColor = .clear
                wtTank.position = CGPoint(x: wtX, y: height * 0.7 + 30)
                node.addChild(wtTank)
            }

        } else if config.speedRatio < 0.8 {
            // Near layer - street lamps, signs, fire hydrants
            let lampCount = Int.random(in: 1...3)
            for _ in 0..<lampCount {
                let lampX = CGFloat.random(in: -segmentWidth / 2...segmentWidth / 2)

                // Lamp pole
                let pole = SKShapeNode(rectOf: CGSize(width: 3, height: 35))
                pole.fillColor = SKColor(hex: "#455A64").withAlphaComponent(0.7)
                pole.strokeColor = .clear
                pole.position = CGPoint(x: lampX, y: 17)
                node.addChild(pole)

                // Lamp head
                let lamp = SKShapeNode(circleOfRadius: 5)
                lamp.fillColor = SKColor(hex: "#FFF9C4").withAlphaComponent(0.8)
                lamp.strokeColor = .clear
                lamp.glowWidth = 8
                lamp.position = CGPoint(x: lampX, y: 37)
                node.addChild(lamp)
            }

            // Fire hydrant
            if Bool.random() {
                let hx = CGFloat.random(in: -segmentWidth / 3...segmentWidth / 3)
                let hydrant = SKShapeNode(rectOf: CGSize(width: 6, height: 10), cornerRadius: 2)
                hydrant.fillColor = SKColor(hex: "#F44336").withAlphaComponent(0.6)
                hydrant.strokeColor = .clear
                hydrant.position = CGPoint(x: hx, y: 5)
                node.addChild(hydrant)
            }
        }
    }

    // MARK: - Scroll

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
