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

    // MARK: - Tree (Countryside - round canopy on trunk)

    private func buildTree(size: CGSize) {
        // Brown trunk with bark texture
        let trunkPath = CGMutablePath()
        trunkPath.move(to: CGPoint(x: -7, y: 0))
        trunkPath.addLine(to: CGPoint(x: -5, y: size.height * 0.45))
        trunkPath.addLine(to: CGPoint(x: 5, y: size.height * 0.45))
        trunkPath.addLine(to: CGPoint(x: 7, y: 0))
        trunkPath.closeSubpath()

        let trunk = SKShapeNode(path: trunkPath)
        trunk.fillColor = SKColor(hex: "#5D4037")
        trunk.strokeColor = SKColor(hex: "#3E2723")
        trunk.lineWidth = 1
        addChild(trunk)

        // Bark detail lines
        for i in 0..<3 {
            let barkLine = SKShapeNode(rectOf: CGSize(width: 1, height: 8))
            barkLine.fillColor = SKColor(hex: "#3E2723").withAlphaComponent(0.5)
            barkLine.strokeColor = .clear
            barkLine.position = CGPoint(x: CGFloat(i - 1) * 3, y: size.height * 0.2 + CGFloat(i) * 5)
            addChild(barkLine)
        }

        // Multi-circle canopy for lush look
        let canopyCenter = CGPoint(x: 0, y: size.height * 0.6)
        let canopyColors: [String] = ["#2E7D32", "#388E3C", "#43A047", "#4CAF50"]

        // Large base circles
        let positions: [(CGPoint, CGFloat)] = [
            (CGPoint(x: -10, y: canopyCenter.y - 5), size.width * 0.35),
            (CGPoint(x: 8, y: canopyCenter.y - 3), size.width * 0.32),
            (CGPoint(x: 0, y: canopyCenter.y + 8), size.width * 0.38),
            (CGPoint(x: -5, y: canopyCenter.y + 15), size.width * 0.28),
            (CGPoint(x: 7, y: canopyCenter.y + 12), size.width * 0.25),
        ]

        for (i, (pos, radius)) in positions.enumerated() {
            let circle = SKShapeNode(circleOfRadius: radius)
            circle.fillColor = SKColor(hex: canopyColors[i % canopyColors.count])
            circle.strokeColor = SKColor(hex: "#1B5E20").withAlphaComponent(0.4)
            circle.lineWidth = 0.8
            circle.position = pos
            addChild(circle)
            if i == 2 { shapeNode = circle }
        }

        // Highlight circle (sun-lit top)
        let highlight = SKShapeNode(circleOfRadius: size.width * 0.2)
        highlight.fillColor = SKColor(hex: "#66BB6A").withAlphaComponent(0.5)
        highlight.strokeColor = .clear
        highlight.position = CGPoint(x: 3, y: canopyCenter.y + 18)
        addChild(highlight)
    }

    // MARK: - Barn (Red with white X door)

    private func buildBarn(size: CGSize) {
        // Main barn body
        let bodyPath = CGMutablePath()
        bodyPath.addRect(CGRect(x: -size.width / 2, y: 0, width: size.width, height: size.height))
        let body = SKShapeNode(path: bodyPath)
        body.fillColor = SKColor(hex: "#C62828")
        body.strokeColor = SKColor(hex: "#8E0000")
        body.lineWidth = 2
        addChild(body)
        shapeNode = body

        // Darker side panel (3D depth)
        let sidePanel = SKShapeNode(rectOf: CGSize(width: size.width * 0.15, height: size.height))
        sidePanel.fillColor = SKColor(hex: "#8E0000")
        sidePanel.strokeColor = .clear
        sidePanel.position = CGPoint(x: -size.width * 0.425, y: size.height / 2)
        addChild(sidePanel)

        // Triangular roof
        let roofPath = CGMutablePath()
        roofPath.move(to: CGPoint(x: -size.width * 0.58, y: size.height))
        roofPath.addLine(to: CGPoint(x: 0, y: size.height * 1.4))
        roofPath.addLine(to: CGPoint(x: size.width * 0.58, y: size.height))
        roofPath.closeSubpath()

        let roof = SKShapeNode(path: roofPath)
        roof.fillColor = SKColor(hex: "#5D4037")
        roof.strokeColor = SKColor(hex: "#3E2723")
        roof.lineWidth = 1.5
        addChild(roof)

        // Roof ridge line
        let ridgeLine = SKShapeNode(rectOf: CGSize(width: size.width * 0.6, height: 3))
        ridgeLine.fillColor = SKColor(hex: "#4E342E")
        ridgeLine.strokeColor = .clear
        ridgeLine.position = CGPoint(x: 0, y: size.height * 1.38)
        addChild(ridgeLine)

        // White X on barn door
        let doorFrame = SKShapeNode(rectOf: CGSize(width: size.width * 0.4, height: size.height * 0.5),
                                     cornerRadius: 2)
        doorFrame.fillColor = SKColor(hex: "#A52714")
        doorFrame.strokeColor = SKColor(hex: "#FFE0B2")
        doorFrame.lineWidth = 2
        doorFrame.position = CGPoint(x: 0, y: size.height * 0.28)
        addChild(doorFrame)

        // X marks
        let xPath1 = CGMutablePath()
        let dw = size.width * 0.18
        let dh = size.height * 0.22
        xPath1.move(to: CGPoint(x: -dw, y: size.height * 0.28 - dh))
        xPath1.addLine(to: CGPoint(x: dw, y: size.height * 0.28 + dh))
        let x1 = SKShapeNode(path: xPath1)
        x1.strokeColor = SKColor(hex: "#FFFFFF").withAlphaComponent(0.9)
        x1.lineWidth = 3
        x1.lineCap = .round
        addChild(x1)

        let xPath2 = CGMutablePath()
        xPath2.move(to: CGPoint(x: dw, y: size.height * 0.28 - dh))
        xPath2.addLine(to: CGPoint(x: -dw, y: size.height * 0.28 + dh))
        let x2 = SKShapeNode(path: xPath2)
        x2.strokeColor = SKColor(hex: "#FFFFFF").withAlphaComponent(0.9)
        x2.lineWidth = 3
        x2.lineCap = .round
        addChild(x2)

        // Small windows on upper floor
        for xPos: CGFloat in [-size.width * 0.22, size.width * 0.22] {
            let window = SKShapeNode(rectOf: CGSize(width: 10, height: 10))
            window.fillColor = SKColor(hex: "#FFF176")
            window.strokeColor = SKColor(hex: "#FFFFFF")
            window.lineWidth = 1
            window.position = CGPoint(x: xPos, y: size.height * 0.75)
            addChild(window)
        }
    }

    // MARK: - Bird (V-shaped flapping wings)

    private func buildBird(size: CGSize) {
        let birdBody = SKNode()

        // Bird body (small oval)
        let bodyShape = SKShapeNode(ellipseOf: CGSize(width: size.width * 0.3, height: size.height * 0.5))
        bodyShape.fillColor = SKColor(hex: "#263238")
        bodyShape.strokeColor = .clear
        birdBody.addChild(bodyShape)

        // Left wing
        let leftWingPath = CGMutablePath()
        leftWingPath.move(to: CGPoint(x: -size.width * 0.08, y: 0))
        leftWingPath.addQuadCurve(to: CGPoint(x: -size.width * 0.5, y: size.height * 0.4),
                                   control: CGPoint(x: -size.width * 0.35, y: size.height * 0.5))
        leftWingPath.addLine(to: CGPoint(x: -size.width * 0.3, y: size.height * 0.1))
        leftWingPath.closeSubpath()

        let leftWing = SKShapeNode(path: leftWingPath)
        leftWing.fillColor = SKColor(hex: "#37474F")
        leftWing.strokeColor = SKColor(hex: "#263238")
        leftWing.lineWidth = 0.5
        leftWing.name = "leftWing"
        birdBody.addChild(leftWing)

        // Right wing
        let rightWingPath = CGMutablePath()
        rightWingPath.move(to: CGPoint(x: size.width * 0.08, y: 0))
        rightWingPath.addQuadCurve(to: CGPoint(x: size.width * 0.5, y: size.height * 0.4),
                                    control: CGPoint(x: size.width * 0.35, y: size.height * 0.5))
        rightWingPath.addLine(to: CGPoint(x: size.width * 0.3, y: size.height * 0.1))
        rightWingPath.closeSubpath()

        let rightWing = SKShapeNode(path: rightWingPath)
        rightWing.fillColor = SKColor(hex: "#37474F")
        rightWing.strokeColor = SKColor(hex: "#263238")
        rightWing.lineWidth = 0.5
        rightWing.name = "rightWing"
        birdBody.addChild(rightWing)

        // Beak
        let beakPath = CGMutablePath()
        beakPath.move(to: CGPoint(x: 0, y: 0))
        beakPath.addLine(to: CGPoint(x: size.width * 0.15, y: -size.height * 0.1))
        beakPath.addLine(to: CGPoint(x: 0, y: -size.height * 0.15))
        beakPath.closeSubpath()

        let beak = SKShapeNode(path: beakPath)
        beak.fillColor = SKColor(hex: "#FF8F00")
        beak.strokeColor = .clear
        beak.position = CGPoint(x: size.width * 0.12, y: -size.height * 0.05)
        birdBody.addChild(beak)

        // Eye
        let eye = SKShapeNode(circleOfRadius: 1.5)
        eye.fillColor = .white
        eye.strokeColor = .clear
        eye.position = CGPoint(x: size.width * 0.05, y: size.height * 0.05)
        birdBody.addChild(eye)

        addChild(birdBody)
        shapeNode = bodyShape

        // Wing flapping animation
        let flapUp = SKAction.run {
            leftWing.zRotation = 0.3
            rightWing.zRotation = -0.3
        }
        let flapDown = SKAction.run {
            leftWing.zRotation = -0.2
            rightWing.zRotation = 0.2
        }
        let flapSequence = SKAction.sequence([
            flapUp,
            SKAction.wait(forDuration: 0.2),
            flapDown,
            SKAction.wait(forDuration: 0.2)
        ])
        birdBody.run(SKAction.repeatForever(flapSequence), withKey: "flap")
    }

    // MARK: - Windmill / Wind Turbine (rotating blades)

    private func buildWindmill(size: CGSize) {
        // Tapered tower
        let towerPath = CGMutablePath()
        towerPath.move(to: CGPoint(x: -8, y: 0))
        towerPath.addLine(to: CGPoint(x: -5, y: size.height))
        towerPath.addLine(to: CGPoint(x: 5, y: size.height))
        towerPath.addLine(to: CGPoint(x: 8, y: 0))
        towerPath.closeSubpath()

        let tower = SKShapeNode(path: towerPath)
        tower.fillColor = SKColor(hex: "#ECEFF1")
        tower.strokeColor = SKColor(hex: "#B0BEC5")
        tower.lineWidth = 1
        addChild(tower)
        shapeNode = tower

        // Tower stripe details
        for i in 1..<4 {
            let yPos = CGFloat(i) * size.height * 0.25
            let lineWidth: CGFloat = 8 - CGFloat(i) * 0.5
            let stripe = SKShapeNode(rectOf: CGSize(width: lineWidth, height: 2))
            stripe.fillColor = SKColor(hex: "#CFD8DC")
            stripe.strokeColor = .clear
            stripe.position = CGPoint(x: 0, y: yPos)
            addChild(stripe)
        }

        // Nacelle (hub housing)
        let nacelle = SKShapeNode(ellipseOf: CGSize(width: 14, height: 10))
        nacelle.fillColor = SKColor(hex: "#ECEFF1")
        nacelle.strokeColor = SKColor(hex: "#90A4AE")
        nacelle.lineWidth = 1
        nacelle.position = CGPoint(x: 0, y: size.height)
        addChild(nacelle)

        // Three blades (modern wind turbine style)
        let blades = SKNode()
        for i in 0..<3 {
            let bladePath = CGMutablePath()
            bladePath.move(to: CGPoint(x: 0, y: 2))
            bladePath.addLine(to: CGPoint(x: -3, y: 35))
            bladePath.addCurve(to: CGPoint(x: 1, y: 35),
                               control1: CGPoint(x: -2, y: 36),
                               control2: CGPoint(x: 0, y: 36))
            bladePath.addLine(to: CGPoint(x: 2, y: 2))
            bladePath.closeSubpath()

            let blade = SKShapeNode(path: bladePath)
            blade.fillColor = .white
            blade.strokeColor = SKColor(hex: "#E0E0E0")
            blade.lineWidth = 0.5
            blade.zRotation = CGFloat(i) * .pi * 2.0 / 3.0
            blades.addChild(blade)
        }

        // Center hub
        let hub = SKShapeNode(circleOfRadius: 4)
        hub.fillColor = SKColor(hex: "#78909C")
        hub.strokeColor = .clear
        blades.addChild(hub)

        blades.position = CGPoint(x: 0, y: size.height)
        addChild(blades)
        detailNode = blades

        let spin = SKAction.rotate(byAngle: .pi * 2, duration: 2.5)
        blades.run(SKAction.repeatForever(spin))
    }

    // MARK: - Mountain Peak (Jagged with snow cap)

    private func buildPeak(size: CGSize) {
        // Main mountain body with jagged edges
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -size.width / 2, y: 0))
        path.addLine(to: CGPoint(x: -size.width * 0.35, y: size.height * 0.3))
        path.addLine(to: CGPoint(x: -size.width * 0.25, y: size.height * 0.25))
        path.addLine(to: CGPoint(x: -size.width * 0.15, y: size.height * 0.7))
        path.addLine(to: CGPoint(x: -size.width * 0.05, y: size.height * 0.65))
        path.addLine(to: CGPoint(x: 0, y: size.height))
        path.addLine(to: CGPoint(x: size.width * 0.08, y: size.height * 0.85))
        path.addLine(to: CGPoint(x: size.width * 0.2, y: size.height * 0.6))
        path.addLine(to: CGPoint(x: size.width * 0.3, y: size.height * 0.35))
        path.addLine(to: CGPoint(x: size.width * 0.35, y: size.height * 0.4))
        path.addLine(to: CGPoint(x: size.width / 2, y: 0))
        path.closeSubpath()

        let peak = SKShapeNode(path: path)
        peak.fillColor = SKColor(hex: "#5D4037")
        peak.strokeColor = SKColor(hex: "#3E2723")
        peak.lineWidth = 1.5
        addChild(peak)
        shapeNode = peak

        // Rocky texture - darker patches
        let rockPath = CGMutablePath()
        rockPath.move(to: CGPoint(x: -size.width * 0.2, y: size.height * 0.2))
        rockPath.addLine(to: CGPoint(x: -size.width * 0.1, y: size.height * 0.35))
        rockPath.addLine(to: CGPoint(x: 0, y: size.height * 0.25))
        rockPath.closeSubpath()

        let rock = SKShapeNode(path: rockPath)
        rock.fillColor = SKColor(hex: "#4E342E").withAlphaComponent(0.5)
        rock.strokeColor = .clear
        addChild(rock)

        // Snow cap (white irregular shape at top)
        let snowPath = CGMutablePath()
        snowPath.move(to: CGPoint(x: -size.width * 0.15, y: size.height * 0.7))
        snowPath.addCurve(to: CGPoint(x: -size.width * 0.05, y: size.height * 0.78),
                          control1: CGPoint(x: -size.width * 0.12, y: size.height * 0.72),
                          control2: CGPoint(x: -size.width * 0.08, y: size.height * 0.76))
        snowPath.addLine(to: CGPoint(x: 0, y: size.height))
        snowPath.addLine(to: CGPoint(x: size.width * 0.08, y: size.height * 0.85))
        snowPath.addCurve(to: CGPoint(x: size.width * 0.15, y: size.height * 0.65),
                          control1: CGPoint(x: size.width * 0.1, y: size.height * 0.8),
                          control2: CGPoint(x: size.width * 0.12, y: size.height * 0.7))
        snowPath.addCurve(to: CGPoint(x: -size.width * 0.15, y: size.height * 0.7),
                          control1: CGPoint(x: size.width * 0.05, y: size.height * 0.6),
                          control2: CGPoint(x: -size.width * 0.05, y: size.height * 0.62))
        snowPath.closeSubpath()

        let snow = SKShapeNode(path: snowPath)
        snow.fillColor = .white
        snow.strokeColor = SKColor(hex: "#E3F2FD").withAlphaComponent(0.8)
        snow.lineWidth = 1
        snow.glowWidth = 2
        addChild(snow)
    }

    // MARK: - Cloud (Fluffy multi-circle)

    private func buildCloud(size: CGSize) {
        let cloud = SKNode()

        // Multiple overlapping circles for fluffy appearance
        let cloudData: [(CGPoint, CGFloat)] = [
            (CGPoint(x: -30, y: -3), 18),
            (CGPoint(x: -15, y: 5), 22),
            (CGPoint(x: 5, y: 8), 25),
            (CGPoint(x: 22, y: 4), 20),
            (CGPoint(x: 35, y: -2), 16),
            (CGPoint(x: -8, y: -6), 15),
            (CGPoint(x: 12, y: -4), 17),
        ]

        for (pos, radius) in cloudData {
            let circle = SKShapeNode(circleOfRadius: radius)
            circle.fillColor = SKColor.white.withAlphaComponent(0.85)
            circle.strokeColor = SKColor(hex: "#E0E0E0").withAlphaComponent(0.3)
            circle.lineWidth = 0.5
            circle.position = pos
            cloud.addChild(circle)
        }

        // Bottom flat edge (darker shadow)
        let shadowPath = CGMutablePath()
        shadowPath.addEllipse(in: CGRect(x: -35, y: -15, width: 70, height: 12))
        let shadow = SKShapeNode(path: shadowPath)
        shadow.fillColor = SKColor(hex: "#BDBDBD").withAlphaComponent(0.3)
        shadow.strokeColor = .clear
        cloud.addChild(shadow)

        addChild(cloud)
        shapeNode = SKShapeNode(circleOfRadius: size.width / 2)
    }

    // MARK: - Pine Tree (Layered triangles)

    private func buildPine(size: CGSize) {
        // Trunk
        let trunkPath = CGMutablePath()
        trunkPath.move(to: CGPoint(x: -5, y: 0))
        trunkPath.addLine(to: CGPoint(x: -4, y: size.height * 0.3))
        trunkPath.addLine(to: CGPoint(x: 4, y: size.height * 0.3))
        trunkPath.addLine(to: CGPoint(x: 5, y: 0))
        trunkPath.closeSubpath()

        let trunk = SKShapeNode(path: trunkPath)
        trunk.fillColor = SKColor(hex: "#4E342E")
        trunk.strokeColor = SKColor(hex: "#3E2723")
        trunk.lineWidth = 1
        addChild(trunk)

        // Three layered triangles (darkest at bottom, lightest at top)
        let layerColors = ["#1B5E20", "#2E7D32", "#388E3C"]
        for i in 0..<3 {
            let yBase = size.height * (0.2 + CGFloat(i) * 0.22)
            let layerWidth = size.width * (1.0 - CGFloat(i) * 0.22)
            let layerHeight = size.height * 0.38

            let path = CGMutablePath()
            path.move(to: CGPoint(x: -layerWidth / 2, y: yBase))
            path.addLine(to: CGPoint(x: 0, y: yBase + layerHeight))
            path.addLine(to: CGPoint(x: layerWidth / 2, y: yBase))
            path.closeSubpath()

            let layer = SKShapeNode(path: path)
            layer.fillColor = SKColor(hex: layerColors[i])
            layer.strokeColor = SKColor(hex: "#0D3311").withAlphaComponent(0.5)
            layer.lineWidth = 1
            addChild(layer)
        }

        // Snow dusting on top
        let snowDot1 = SKShapeNode(circleOfRadius: 3)
        snowDot1.fillColor = .white.withAlphaComponent(0.8)
        snowDot1.strokeColor = .clear
        snowDot1.position = CGPoint(x: 0, y: size.height * 0.85)
        addChild(snowDot1)

        let snowDot2 = SKShapeNode(circleOfRadius: 2)
        snowDot2.fillColor = .white.withAlphaComponent(0.6)
        snowDot2.strokeColor = .clear
        snowDot2.position = CGPoint(x: -5, y: size.height * 0.55)
        addChild(snowDot2)

        shapeNode = SKShapeNode(rectOf: size)
    }

    // MARK: - Building (City - with lit windows)

    private func buildBuilding(size: CGSize) {
        // Main building body
        let bodyPath = CGMutablePath()
        bodyPath.addRect(CGRect(x: -size.width / 2, y: 0, width: size.width, height: size.height))
        let body = SKShapeNode(path: bodyPath)
        body.fillColor = SKColor(hex: "#455A64")
        body.strokeColor = SKColor(hex: "#37474F")
        body.lineWidth = 1.5
        addChild(body)
        shapeNode = body

        // Darker side for 3D depth
        let sidePath = CGMutablePath()
        sidePath.addRect(CGRect(x: -size.width / 2, y: 0, width: size.width * 0.15, height: size.height))
        let side = SKShapeNode(path: sidePath)
        side.fillColor = SKColor(hex: "#37474F")
        side.strokeColor = .clear
        addChild(side)

        // Roof ledge
        let ledge = SKShapeNode(rectOf: CGSize(width: size.width + 6, height: 4))
        ledge.fillColor = SKColor(hex: "#546E7A")
        ledge.strokeColor = .clear
        ledge.position = CGPoint(x: 0, y: size.height)
        addChild(ledge)

        // Rooftop structure (AC unit or water tank)
        if Bool.random() {
            let rooftop = SKShapeNode(rectOf: CGSize(width: size.width * 0.3, height: 12), cornerRadius: 2)
            rooftop.fillColor = SKColor(hex: "#607D8B")
            rooftop.strokeColor = .clear
            rooftop.position = CGPoint(x: size.width * 0.15, y: size.height + 8)
            addChild(rooftop)
        }

        // Windows grid with random lighting
        let windowWidth: CGFloat = 10
        let windowHeight: CGFloat = 14
        let hSpacing: CGFloat = 18
        let vSpacing: CGFloat = 22
        let windowCols = Int((size.width - 12) / hSpacing)
        let windowRows = Int((size.height - 15) / vSpacing)

        let startX = -size.width / 2 + (size.width - CGFloat(windowCols) * hSpacing) / 2 + hSpacing / 2

        for row in 0..<windowRows {
            for col in 0..<windowCols {
                let window = SKShapeNode(rectOf: CGSize(width: windowWidth, height: windowHeight))
                let isLit = Bool.random()
                if isLit {
                    let warmth = CGFloat.random(in: 0.7...1.0)
                    window.fillColor = SKColor(hex: "#FFF176").withAlphaComponent(warmth)
                    window.glowWidth = 1
                } else {
                    window.fillColor = SKColor(hex: "#1A237E").withAlphaComponent(0.8)
                }
                window.strokeColor = SKColor(hex: "#546E7A")
                window.lineWidth = 0.5
                window.position = CGPoint(
                    x: startX + CGFloat(col) * hSpacing,
                    y: 12 + CGFloat(row) * vSpacing
                )
                addChild(window)
            }
        }
    }

    // MARK: - Crane (T-shaped construction crane)

    private func buildCrane(size: CGSize) {
        // Lattice tower (drawn as crossed lines)
        let towerWidth: CGFloat = 10
        let tower = SKShapeNode(rectOf: CGSize(width: towerWidth, height: size.height))
        tower.fillColor = SKColor(hex: "#FF8F00")
        tower.strokeColor = SKColor(hex: "#E65100")
        tower.lineWidth = 1
        tower.position = CGPoint(x: 0, y: size.height / 2)
        addChild(tower)
        shapeNode = tower

        // Tower lattice cross-braces
        let braceCount = Int(size.height / 20)
        for i in 0..<braceCount {
            let yPos = CGFloat(i) * 20 + 10
            let brace1 = SKShapeNode(rectOf: CGSize(width: towerWidth - 2, height: 1.5))
            brace1.fillColor = SKColor(hex: "#E65100")
            brace1.strokeColor = .clear
            brace1.position = CGPoint(x: 0, y: yPos)
            brace1.zRotation = .pi / 4
            addChild(brace1)
        }

        // Horizontal jib arm
        let armLength = size.width * 2.2
        let arm = SKShapeNode(rectOf: CGSize(width: armLength, height: 5))
        arm.fillColor = SKColor(hex: "#FF8F00")
        arm.strokeColor = SKColor(hex: "#E65100")
        arm.lineWidth = 1
        arm.position = CGPoint(x: armLength * 0.2, y: size.height)
        addChild(arm)

        // Counter-weight arm (shorter, back)
        let counterArm = SKShapeNode(rectOf: CGSize(width: armLength * 0.3, height: 5))
        counterArm.fillColor = SKColor(hex: "#FF8F00")
        counterArm.strokeColor = .clear
        counterArm.position = CGPoint(x: -armLength * 0.15, y: size.height)
        addChild(counterArm)

        // Counter-weight block
        let weight = SKShapeNode(rectOf: CGSize(width: 12, height: 10))
        weight.fillColor = SKColor(hex: "#424242")
        weight.strokeColor = .clear
        weight.position = CGPoint(x: -armLength * 0.25, y: size.height - 8)
        addChild(weight)

        // Cable line hanging from arm tip
        let cablePath = CGMutablePath()
        cablePath.move(to: CGPoint(x: armLength * 0.5, y: size.height))
        cablePath.addLine(to: CGPoint(x: armLength * 0.5, y: size.height - 40))
        let cable = SKShapeNode(path: cablePath)
        cable.strokeColor = SKColor(hex: "#424242")
        cable.lineWidth = 1.5
        addChild(cable)

        // Hook at cable end
        let hook = SKShapeNode(circleOfRadius: 4)
        hook.fillColor = SKColor(hex: "#616161")
        hook.strokeColor = .clear
        hook.position = CGPoint(x: armLength * 0.5, y: size.height - 42)
        addChild(hook)

        // Support cables (diagonal from tower top to arm)
        let supportPath1 = CGMutablePath()
        supportPath1.move(to: CGPoint(x: 0, y: size.height + 15))
        supportPath1.addLine(to: CGPoint(x: armLength * 0.45, y: size.height))
        let support1 = SKShapeNode(path: supportPath1)
        support1.strokeColor = SKColor(hex: "#616161")
        support1.lineWidth = 1
        addChild(support1)

        let supportPath2 = CGMutablePath()
        supportPath2.move(to: CGPoint(x: 0, y: size.height + 15))
        supportPath2.addLine(to: CGPoint(x: -armLength * 0.15, y: size.height))
        let support2 = SKShapeNode(path: supportPath2)
        support2.strokeColor = SKColor(hex: "#616161")
        support2.lineWidth = 1
        addChild(support2)

        // Apex point
        let apex = SKShapeNode(circleOfRadius: 3)
        apex.fillColor = SKColor(hex: "#FF8F00")
        apex.strokeColor = .clear
        apex.position = CGPoint(x: 0, y: size.height + 15)
        addChild(apex)
    }

    // MARK: - Antenna (with blinking light)

    private func buildAntenna(size: CGSize) {
        // Tapered pole
        let polePath = CGMutablePath()
        polePath.move(to: CGPoint(x: -3, y: 0))
        polePath.addLine(to: CGPoint(x: -1.5, y: size.height))
        polePath.addLine(to: CGPoint(x: 1.5, y: size.height))
        polePath.addLine(to: CGPoint(x: 3, y: 0))
        polePath.closeSubpath()

        let pole = SKShapeNode(path: polePath)
        pole.fillColor = SKColor(hex: "#B0BEC5")
        pole.strokeColor = SKColor(hex: "#78909C")
        pole.lineWidth = 1
        addChild(pole)
        shapeNode = pole

        // Cross bars at intervals
        for i in 1..<4 {
            let yPos = CGFloat(i) * size.height * 0.25
            let barWidth: CGFloat = 20 - CGFloat(i) * 3
            let bar = SKShapeNode(rectOf: CGSize(width: barWidth, height: 2))
            bar.fillColor = SKColor(hex: "#90A4AE")
            bar.strokeColor = .clear
            bar.position = CGPoint(x: 0, y: yPos)
            addChild(bar)

            // Small diagonal supports
            let diagPath = CGMutablePath()
            diagPath.move(to: CGPoint(x: -barWidth / 2, y: yPos))
            diagPath.addLine(to: CGPoint(x: 0, y: yPos + size.height * 0.12))
            let diag1 = SKShapeNode(path: diagPath)
            diag1.strokeColor = SKColor(hex: "#90A4AE").withAlphaComponent(0.6)
            diag1.lineWidth = 0.8
            addChild(diag1)

            let diagPath2 = CGMutablePath()
            diagPath2.move(to: CGPoint(x: barWidth / 2, y: yPos))
            diagPath2.addLine(to: CGPoint(x: 0, y: yPos + size.height * 0.12))
            let diag2 = SKShapeNode(path: diagPath2)
            diag2.strokeColor = SKColor(hex: "#90A4AE").withAlphaComponent(0.6)
            diag2.lineWidth = 0.8
            addChild(diag2)
        }

        // Blinking red light at top
        let light = SKShapeNode(circleOfRadius: 4)
        light.fillColor = SKColor(hex: "#F44336")
        light.strokeColor = .clear
        light.glowWidth = 6
        light.position = CGPoint(x: 0, y: size.height + 2)
        addChild(light)

        let blink = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.2, duration: 0.8),
            SKAction.fadeAlpha(to: 1.0, duration: 0.2),
            SKAction.wait(forDuration: 0.5)
        ])
        light.run(SKAction.repeatForever(blink))

        // Secondary light (smaller, halfway up)
        let light2 = SKShapeNode(circleOfRadius: 2.5)
        light2.fillColor = SKColor(hex: "#F44336")
        light2.strokeColor = .clear
        light2.glowWidth = 4
        light2.position = CGPoint(x: 0, y: size.height * 0.5)
        light2.alpha = 0.7
        addChild(light2)

        let blink2 = SKAction.sequence([
            SKAction.wait(forDuration: 0.3),
            SKAction.fadeAlpha(to: 0.2, duration: 0.8),
            SKAction.fadeAlpha(to: 0.7, duration: 0.2),
            SKAction.wait(forDuration: 0.5)
        ])
        light2.run(SKAction.repeatForever(blink2))
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
            oscillate.timingMode = .easeInEaseOut
            oscillateBack.timingMode = .easeInEaseOut
            let wingFlap = SKAction.sequence([oscillate, oscillateBack])

            run(SKAction.repeatForever(SKAction.group([moveLeft, wingFlap])))
        } else if kind == .cloud {
            let drift = SKAction.moveBy(x: -30, y: 0, duration: 2.0)
            let driftBack = SKAction.moveBy(x: 30, y: 0, duration: 2.0)
            drift.timingMode = .easeInEaseOut
            driftBack.timingMode = .easeInEaseOut
            run(SKAction.repeatForever(SKAction.sequence([drift, driftBack])))
        }
    }

    // MARK: - Destruction

    func destroy() {
        // Break-apart particle effect
        let particleCount = 8
        let baseColor = SKColor(hex: kind.colorHex)

        for _ in 0..<particleCount {
            let piece = SKShapeNode(rectOf: CGSize(width: CGFloat.random(in: 4...10),
                                                    height: CGFloat.random(in: 3...8)),
                                     cornerRadius: 1)
            piece.fillColor = baseColor
            piece.strokeColor = .clear
            piece.position = position
            piece.zPosition = GameConfig.ZPosition.particles
            parent?.addChild(piece)

            let angle = CGFloat.random(in: 0...(.pi * 2))
            let dist = CGFloat.random(in: 30...70)
            let moveAction = SKAction.move(by: CGVector(dx: cos(angle) * dist, dy: sin(angle) * dist),
                                            duration: 0.5)
            let rotateAction = SKAction.rotate(byAngle: CGFloat.random(in: -3...3), duration: 0.5)
            let fadeAction = SKAction.fadeOut(withDuration: 0.5)
            piece.run(SKAction.sequence([
                SKAction.group([moveAction, rotateAction, fadeAction]),
                SKAction.removeFromParent()
            ]))
        }

        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let scale = SKAction.scale(to: 1.3, duration: 0.3)
        let remove = SKAction.removeFromParent()
        run(SKAction.sequence([SKAction.group([fadeOut, scale]), remove]))
    }
}
