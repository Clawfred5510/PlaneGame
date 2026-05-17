import SpriteKit

// MARK: - PlaneNode

final class PlaneNode: SKNode {

    // MARK: - Properties

    private(set) var model: PlaneModel
    private var bodyNode: SKShapeNode!
    private var wingNode: SKShapeNode!
    private var tailNode: SKShapeNode!
    private var cockpitNode: SKShapeNode!
    private var propellerNode: SKNode?
    private var exhaustEmitter: SKEmitterNode?
    private var shieldNode: SKShapeNode?

    private(set) var velocity: CGVector = .zero
    private(set) var isLaunched = false
    private(set) var hasShield = false
    private(set) var hasMagnet = false
    private(set) var hasBoost = false
    private var boostTimer: TimeInterval = 0

    var currentSpeed: CGFloat { velocity.length }
    var isFlying: Bool { isLaunched && position.y > GameConfig.World.groundY + 10 }

    // MARK: - Init

    init(model: PlaneModel) {
        self.model = model
        super.init()
        buildPlane()
        setupPhysics()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    // MARK: - Build Visual

    private func buildPlane() {
        switch model.currentStage {
        case .propeller:
            buildPropellerPlane()
        case .turboProp:
            buildTurboPropPlane()
        case .jet:
            buildJetPlane()
        case .rocket:
            buildRocketPlane()
        }

        zPosition = GameConfig.ZPosition.plane
    }

    // MARK: - Propeller Stage (Red Biplane)

    private func buildPropellerPlane() {
        let bodySize = model.bodySize

        // Fuselage - rounded biplane body
        let fuselagePath = CGMutablePath()
        let fw = bodySize.width
        let fh = bodySize.height
        fuselagePath.move(to: CGPoint(x: -fw * 0.45, y: 0))
        fuselagePath.addCurve(to: CGPoint(x: fw * 0.35, y: fh * 0.4),
                              control1: CGPoint(x: -fw * 0.3, y: fh * 0.5),
                              control2: CGPoint(x: fw * 0.1, y: fh * 0.5))
        fuselagePath.addCurve(to: CGPoint(x: fw * 0.5, y: 0),
                              control1: CGPoint(x: fw * 0.45, y: fh * 0.3),
                              control2: CGPoint(x: fw * 0.5, y: fh * 0.15))
        fuselagePath.addCurve(to: CGPoint(x: fw * 0.35, y: -fh * 0.4),
                              control1: CGPoint(x: fw * 0.5, y: -fh * 0.15),
                              control2: CGPoint(x: fw * 0.45, y: -fh * 0.3))
        fuselagePath.addCurve(to: CGPoint(x: -fw * 0.45, y: 0),
                              control1: CGPoint(x: fw * 0.1, y: -fh * 0.5),
                              control2: CGPoint(x: -fw * 0.3, y: -fh * 0.5))
        fuselagePath.closeSubpath()

        bodyNode = SKShapeNode(path: fuselagePath)
        bodyNode.fillColor = SKColor(hex: "#C62828")
        bodyNode.strokeColor = SKColor(hex: "#8E0000")
        bodyNode.lineWidth = 1.5
        addChild(bodyNode)

        // Upper wing
        let upperWing = SKShapeNode(rectOf: CGSize(width: fw * 0.6, height: model.wingSpan * 0.9),
                                     cornerRadius: 3)
        upperWing.fillColor = SKColor(hex: "#E53935")
        upperWing.strokeColor = SKColor(hex: "#B71C1C")
        upperWing.lineWidth = 1
        upperWing.position = CGPoint(x: -fw * 0.05, y: fh * 0.55)
        addChild(upperWing)

        // Lower wing
        let lowerWing = SKShapeNode(rectOf: CGSize(width: fw * 0.55, height: model.wingSpan * 0.8),
                                     cornerRadius: 3)
        lowerWing.fillColor = SKColor(hex: "#E53935")
        lowerWing.strokeColor = SKColor(hex: "#B71C1C")
        lowerWing.lineWidth = 1
        lowerWing.position = CGPoint(x: -fw * 0.05, y: -fh * 0.55)
        addChild(lowerWing)
        wingNode = lowerWing

        // Wing struts (connecting upper and lower wings)
        for xOff: CGFloat in [-fw * 0.15, fw * 0.05] {
            let strut = SKShapeNode(rectOf: CGSize(width: 2, height: fh * 1.0))
            strut.fillColor = SKColor(hex: "#5D4037")
            strut.strokeColor = .clear
            strut.position = CGPoint(x: xOff, y: 0)
            addChild(strut)
        }

        // Tail fin (vertical stabilizer)
        let tailPath = CGMutablePath()
        tailPath.move(to: CGPoint(x: -fw * 0.42, y: 0))
        tailPath.addLine(to: CGPoint(x: -fw * 0.5, y: fh * 0.9))
        tailPath.addLine(to: CGPoint(x: -fw * 0.38, y: fh * 0.7))
        tailPath.addLine(to: CGPoint(x: -fw * 0.35, y: 0))
        tailPath.closeSubpath()

        tailNode = SKShapeNode(path: tailPath)
        tailNode.fillColor = SKColor(hex: "#D32F2F")
        tailNode.strokeColor = SKColor(hex: "#B71C1C")
        tailNode.lineWidth = 1
        addChild(tailNode)

        // Horizontal stabilizer
        let hStabPath = CGMutablePath()
        hStabPath.move(to: CGPoint(x: -fw * 0.45, y: 0))
        hStabPath.addLine(to: CGPoint(x: -fw * 0.52, y: fh * 0.3))
        hStabPath.addLine(to: CGPoint(x: -fw * 0.38, y: fh * 0.1))
        hStabPath.addLine(to: CGPoint(x: -fw * 0.38, y: -fh * 0.1))
        hStabPath.addLine(to: CGPoint(x: -fw * 0.52, y: -fh * 0.3))
        hStabPath.closeSubpath()

        let hStab = SKShapeNode(path: hStabPath)
        hStab.fillColor = SKColor(hex: "#D32F2F")
        hStab.strokeColor = .clear
        addChild(hStab)

        // Cockpit window
        cockpitNode = SKShapeNode(ellipseOf: CGSize(width: fw * 0.18, height: fh * 0.4))
        cockpitNode.position = CGPoint(x: fw * 0.2, y: fh * 0.15)
        cockpitNode.fillColor = SKColor(hex: "#81D4FA")
        cockpitNode.strokeColor = SKColor(hex: "#4FC3F7")
        cockpitNode.lineWidth = 1
        cockpitNode.glowWidth = 1
        addChild(cockpitNode)

        // Propeller
        let prop = SKNode()
        let blade1 = SKShapeNode(rectOf: CGSize(width: 4, height: 22), cornerRadius: 2)
        blade1.fillColor = SKColor(hex: "#424242")
        blade1.strokeColor = .clear
        prop.addChild(blade1)

        let blade2 = SKShapeNode(rectOf: CGSize(width: 22, height: 4), cornerRadius: 2)
        blade2.fillColor = SKColor(hex: "#424242")
        blade2.strokeColor = .clear
        prop.addChild(blade2)

        // Propeller hub
        let hub = SKShapeNode(circleOfRadius: 4)
        hub.fillColor = SKColor(hex: "#616161")
        hub.strokeColor = .clear
        prop.addChild(hub)

        prop.position = CGPoint(x: fw * 0.5 + 3, y: 0)
        addChild(prop)
        propellerNode = prop

        // Landing gear dots
        let leftGear = SKShapeNode(circleOfRadius: 3)
        leftGear.fillColor = SKColor(hex: "#212121")
        leftGear.strokeColor = .clear
        leftGear.position = CGPoint(x: fw * 0.1, y: -fh * 0.6)
        addChild(leftGear)

        let rightGear = SKShapeNode(circleOfRadius: 3)
        rightGear.fillColor = SKColor(hex: "#212121")
        rightGear.strokeColor = .clear
        rightGear.position = CGPoint(x: -fw * 0.15, y: -fh * 0.6)
        addChild(rightGear)
    }

    // MARK: - Turbo Prop Stage (Blue Sleek Plane)

    private func buildTurboPropPlane() {
        let bodySize = model.bodySize
        let fw = bodySize.width
        let fh = bodySize.height

        // Sleek fuselage
        let fuselagePath = CGMutablePath()
        fuselagePath.move(to: CGPoint(x: -fw * 0.48, y: 0))
        fuselagePath.addCurve(to: CGPoint(x: fw * 0.3, y: fh * 0.35),
                              control1: CGPoint(x: -fw * 0.2, y: fh * 0.42),
                              control2: CGPoint(x: fw * 0.05, y: fh * 0.42))
        fuselagePath.addCurve(to: CGPoint(x: fw * 0.52, y: 0),
                              control1: CGPoint(x: fw * 0.42, y: fh * 0.2),
                              control2: CGPoint(x: fw * 0.52, y: fh * 0.1))
        fuselagePath.addCurve(to: CGPoint(x: fw * 0.3, y: -fh * 0.35),
                              control1: CGPoint(x: fw * 0.52, y: -fh * 0.1),
                              control2: CGPoint(x: fw * 0.42, y: -fh * 0.2))
        fuselagePath.addCurve(to: CGPoint(x: -fw * 0.48, y: 0),
                              control1: CGPoint(x: fw * 0.05, y: -fh * 0.42),
                              control2: CGPoint(x: -fw * 0.2, y: -fh * 0.42))
        fuselagePath.closeSubpath()

        bodyNode = SKShapeNode(path: fuselagePath)
        bodyNode.fillColor = SKColor(hex: "#1976D2")
        bodyNode.strokeColor = SKColor(hex: "#0D47A1")
        bodyNode.lineWidth = 1.5
        addChild(bodyNode)

        // Fuselage stripe detail
        let stripePath = CGMutablePath()
        stripePath.move(to: CGPoint(x: -fw * 0.4, y: fh * 0.05))
        stripePath.addLine(to: CGPoint(x: fw * 0.45, y: fh * 0.05))
        stripePath.addLine(to: CGPoint(x: fw * 0.45, y: -fh * 0.05))
        stripePath.addLine(to: CGPoint(x: -fw * 0.4, y: -fh * 0.05))
        stripePath.closeSubpath()

        let stripe = SKShapeNode(path: stripePath)
        stripe.fillColor = SKColor(hex: "#BBDEFB")
        stripe.strokeColor = .clear
        addChild(stripe)

        // Single swept wing
        let wingPath = CGMutablePath()
        wingPath.move(to: CGPoint(x: fw * 0.05, y: 0))
        wingPath.addLine(to: CGPoint(x: -fw * 0.1, y: model.wingSpan * 0.48))
        wingPath.addLine(to: CGPoint(x: -fw * 0.2, y: model.wingSpan * 0.5))
        wingPath.addLine(to: CGPoint(x: -fw * 0.15, y: 0))
        wingPath.addLine(to: CGPoint(x: -fw * 0.2, y: -model.wingSpan * 0.5))
        wingPath.addLine(to: CGPoint(x: -fw * 0.1, y: -model.wingSpan * 0.48))
        wingPath.closeSubpath()

        wingNode = SKShapeNode(path: wingPath)
        wingNode.fillColor = SKColor(hex: "#1E88E5")
        wingNode.strokeColor = SKColor(hex: "#0D47A1")
        wingNode.lineWidth = 1
        addChild(wingNode)

        // Engine nacelle
        let nacellePath = CGMutablePath()
        nacellePath.addEllipse(in: CGRect(x: fw * 0.3, y: -fh * 0.25,
                                           width: fw * 0.2, height: fh * 0.5))
        let nacelle = SKShapeNode(path: nacellePath)
        nacelle.fillColor = SKColor(hex: "#455A64")
        nacelle.strokeColor = SKColor(hex: "#263238")
        nacelle.lineWidth = 1
        addChild(nacelle)

        // Tail with vertical stabilizer
        let tailPath = CGMutablePath()
        tailPath.move(to: CGPoint(x: -fw * 0.4, y: 0))
        tailPath.addLine(to: CGPoint(x: -fw * 0.5, y: fh * 1.0))
        tailPath.addCurve(to: CGPoint(x: -fw * 0.38, y: fh * 0.5),
                          control1: CGPoint(x: -fw * 0.48, y: fh * 0.9),
                          control2: CGPoint(x: -fw * 0.4, y: fh * 0.7))
        tailPath.addLine(to: CGPoint(x: -fw * 0.35, y: 0))
        tailPath.closeSubpath()

        tailNode = SKShapeNode(path: tailPath)
        tailNode.fillColor = SKColor(hex: "#1565C0")
        tailNode.strokeColor = SKColor(hex: "#0D47A1")
        tailNode.lineWidth = 1
        addChild(tailNode)

        // Horizontal tail stabilizer
        let hTailPath = CGMutablePath()
        hTailPath.move(to: CGPoint(x: -fw * 0.42, y: 0))
        hTailPath.addLine(to: CGPoint(x: -fw * 0.5, y: fh * 0.4))
        hTailPath.addLine(to: CGPoint(x: -fw * 0.38, y: fh * 0.15))
        hTailPath.addLine(to: CGPoint(x: -fw * 0.38, y: -fh * 0.15))
        hTailPath.addLine(to: CGPoint(x: -fw * 0.5, y: -fh * 0.4))
        hTailPath.closeSubpath()

        let hTail = SKShapeNode(path: hTailPath)
        hTail.fillColor = SKColor(hex: "#1565C0")
        hTail.strokeColor = .clear
        addChild(hTail)

        // Cockpit
        cockpitNode = SKShapeNode(ellipseOf: CGSize(width: fw * 0.22, height: fh * 0.45))
        cockpitNode.position = CGPoint(x: fw * 0.22, y: fh * 0.1)
        cockpitNode.fillColor = SKColor(hex: "#81D4FA")
        cockpitNode.strokeColor = SKColor(hex: "#4FC3F7")
        cockpitNode.lineWidth = 1
        cockpitNode.glowWidth = 1
        addChild(cockpitNode)

        // Bigger propeller
        let prop = SKNode()
        let blade1 = SKShapeNode(rectOf: CGSize(width: 5, height: 28), cornerRadius: 2)
        blade1.fillColor = SKColor(hex: "#37474F")
        blade1.strokeColor = .clear
        prop.addChild(blade1)

        let blade2 = SKShapeNode(rectOf: CGSize(width: 28, height: 5), cornerRadius: 2)
        blade2.fillColor = SKColor(hex: "#37474F")
        blade2.strokeColor = .clear
        prop.addChild(blade2)

        let blade3 = SKShapeNode(rectOf: CGSize(width: 4, height: 26), cornerRadius: 2)
        blade3.fillColor = SKColor(hex: "#37474F")
        blade3.strokeColor = .clear
        blade3.zRotation = .pi / 4
        prop.addChild(blade3)

        let hub = SKShapeNode(circleOfRadius: 5)
        hub.fillColor = SKColor(hex: "#546E7A")
        hub.strokeColor = .clear
        prop.addChild(hub)

        prop.position = CGPoint(x: fw * 0.52 + 4, y: 0)
        addChild(prop)
        propellerNode = prop
    }

    // MARK: - Jet Stage (Green Military Jet)

    private func buildJetPlane() {
        let bodySize = model.bodySize
        let fw = bodySize.width
        let fh = bodySize.height

        // Streamlined jet fuselage with pointed nose
        let fuselagePath = CGMutablePath()
        fuselagePath.move(to: CGPoint(x: -fw * 0.45, y: 0))
        fuselagePath.addCurve(to: CGPoint(x: fw * 0.2, y: fh * 0.32),
                              control1: CGPoint(x: -fw * 0.25, y: fh * 0.38),
                              control2: CGPoint(x: 0, y: fh * 0.38))
        fuselagePath.addLine(to: CGPoint(x: fw * 0.55, y: fh * 0.05))
        fuselagePath.addLine(to: CGPoint(x: fw * 0.55, y: -fh * 0.05))
        fuselagePath.addLine(to: CGPoint(x: fw * 0.2, y: -fh * 0.32))
        fuselagePath.addCurve(to: CGPoint(x: -fw * 0.45, y: 0),
                              control1: CGPoint(x: 0, y: -fh * 0.38),
                              control2: CGPoint(x: -fw * 0.25, y: -fh * 0.38))
        fuselagePath.closeSubpath()

        bodyNode = SKShapeNode(path: fuselagePath)
        bodyNode.fillColor = SKColor(hex: "#2E7D32")
        bodyNode.strokeColor = SKColor(hex: "#1B5E20")
        bodyNode.lineWidth = 1.5
        addChild(bodyNode)

        // Darker belly panel
        let bellyPath = CGMutablePath()
        bellyPath.move(to: CGPoint(x: -fw * 0.3, y: -fh * 0.1))
        bellyPath.addLine(to: CGPoint(x: fw * 0.4, y: -fh * 0.1))
        bellyPath.addLine(to: CGPoint(x: fw * 0.35, y: -fh * 0.25))
        bellyPath.addLine(to: CGPoint(x: -fw * 0.25, y: -fh * 0.25))
        bellyPath.closeSubpath()

        let belly = SKShapeNode(path: bellyPath)
        belly.fillColor = SKColor(hex: "#1B5E20")
        belly.strokeColor = .clear
        addChild(belly)

        // Delta wings
        let wingPath = CGMutablePath()
        wingPath.move(to: CGPoint(x: fw * 0.1, y: 0))
        wingPath.addLine(to: CGPoint(x: -fw * 0.2, y: model.wingSpan * 0.5))
        wingPath.addLine(to: CGPoint(x: -fw * 0.35, y: model.wingSpan * 0.45))
        wingPath.addLine(to: CGPoint(x: -fw * 0.15, y: 0))
        wingPath.addLine(to: CGPoint(x: -fw * 0.35, y: -model.wingSpan * 0.45))
        wingPath.addLine(to: CGPoint(x: -fw * 0.2, y: -model.wingSpan * 0.5))
        wingPath.closeSubpath()

        wingNode = SKShapeNode(path: wingPath)
        wingNode.fillColor = SKColor(hex: "#388E3C")
        wingNode.strokeColor = SKColor(hex: "#1B5E20")
        wingNode.lineWidth = 1
        addChild(wingNode)

        // Pointed nose cone
        let nosePath = CGMutablePath()
        nosePath.move(to: CGPoint(x: fw * 0.4, y: fh * 0.12))
        nosePath.addLine(to: CGPoint(x: fw * 0.58, y: 0))
        nosePath.addLine(to: CGPoint(x: fw * 0.4, y: -fh * 0.12))
        nosePath.closeSubpath()

        let nose = SKShapeNode(path: nosePath)
        nose.fillColor = SKColor(hex: "#455A64")
        nose.strokeColor = SKColor(hex: "#263238")
        nose.lineWidth = 1
        addChild(nose)

        // Jet intake underneath
        let intakePath = CGMutablePath()
        intakePath.addEllipse(in: CGRect(x: fw * 0.05, y: -fh * 0.45,
                                          width: fw * 0.2, height: fh * 0.2))
        let intake = SKShapeNode(path: intakePath)
        intake.fillColor = SKColor(hex: "#212121")
        intake.strokeColor = SKColor(hex: "#424242")
        intake.lineWidth = 1
        addChild(intake)

        // Tail with vertical stabilizer
        let tailPath = CGMutablePath()
        tailPath.move(to: CGPoint(x: -fw * 0.35, y: 0))
        tailPath.addLine(to: CGPoint(x: -fw * 0.48, y: fh * 1.1))
        tailPath.addLine(to: CGPoint(x: -fw * 0.42, y: fh * 0.9))
        tailPath.addLine(to: CGPoint(x: -fw * 0.38, y: fh * 0.4))
        tailPath.addLine(to: CGPoint(x: -fw * 0.3, y: 0))
        tailPath.closeSubpath()

        tailNode = SKShapeNode(path: tailPath)
        tailNode.fillColor = SKColor(hex: "#2E7D32")
        tailNode.strokeColor = SKColor(hex: "#1B5E20")
        tailNode.lineWidth = 1
        addChild(tailNode)

        // Cockpit (fighter-style bubble canopy)
        let canopyPath = CGMutablePath()
        canopyPath.addEllipse(in: CGRect(x: fw * 0.08, y: fh * 0.05,
                                          width: fw * 0.25, height: fh * 0.35))
        cockpitNode = SKShapeNode(path: canopyPath)
        cockpitNode.fillColor = SKColor(hex: "#81D4FA").withAlphaComponent(0.8)
        cockpitNode.strokeColor = SKColor(hex: "#4FC3F7")
        cockpitNode.lineWidth = 1
        cockpitNode.glowWidth = 2
        addChild(cockpitNode)

        // Engine glow at tail (orange emitter)
        let glowNode = SKShapeNode(circleOfRadius: 6)
        glowNode.fillColor = SKColor(hex: "#FF6D00")
        glowNode.strokeColor = .clear
        glowNode.glowWidth = 8
        glowNode.position = CGPoint(x: -fw * 0.5, y: 0)
        glowNode.alpha = 0.7
        addChild(glowNode)

        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.4, duration: 0.15),
            SKAction.fadeAlpha(to: 0.8, duration: 0.15)
        ])
        glowNode.run(SKAction.repeatForever(pulse))
    }

    // MARK: - Rocket Stage (Gold/Orange Rocket Plane)

    private func buildRocketPlane() {
        let bodySize = model.bodySize
        let fw = bodySize.width
        let fh = bodySize.height

        // Futuristic angular body
        let fuselagePath = CGMutablePath()
        fuselagePath.move(to: CGPoint(x: -fw * 0.42, y: 0))
        fuselagePath.addLine(to: CGPoint(x: -fw * 0.35, y: fh * 0.28))
        fuselagePath.addLine(to: CGPoint(x: fw * 0.2, y: fh * 0.3))
        fuselagePath.addLine(to: CGPoint(x: fw * 0.55, y: fh * 0.05))
        fuselagePath.addLine(to: CGPoint(x: fw * 0.6, y: 0))
        fuselagePath.addLine(to: CGPoint(x: fw * 0.55, y: -fh * 0.05))
        fuselagePath.addLine(to: CGPoint(x: fw * 0.2, y: -fh * 0.3))
        fuselagePath.addLine(to: CGPoint(x: -fw * 0.35, y: -fh * 0.28))
        fuselagePath.closeSubpath()

        bodyNode = SKShapeNode(path: fuselagePath)
        bodyNode.fillColor = SKColor(hex: "#F57C00")
        bodyNode.strokeColor = SKColor(hex: "#E65100")
        bodyNode.lineWidth = 1.5
        addChild(bodyNode)

        // Gold accent panel on top
        let accentPath = CGMutablePath()
        accentPath.move(to: CGPoint(x: -fw * 0.2, y: fh * 0.22))
        accentPath.addLine(to: CGPoint(x: fw * 0.3, y: fh * 0.24))
        accentPath.addLine(to: CGPoint(x: fw * 0.35, y: fh * 0.12))
        accentPath.addLine(to: CGPoint(x: -fw * 0.15, y: fh * 0.12))
        accentPath.closeSubpath()

        let accent = SKShapeNode(path: accentPath)
        accent.fillColor = SKColor(hex: "#FFD54F")
        accent.strokeColor = .clear
        addChild(accent)

        // Swept-back delta wings with glow
        let wingPath = CGMutablePath()
        wingPath.move(to: CGPoint(x: fw * 0.05, y: 0))
        wingPath.addLine(to: CGPoint(x: -fw * 0.15, y: model.wingSpan * 0.5))
        wingPath.addLine(to: CGPoint(x: -fw * 0.35, y: model.wingSpan * 0.35))
        wingPath.addLine(to: CGPoint(x: -fw * 0.2, y: 0))
        wingPath.addLine(to: CGPoint(x: -fw * 0.35, y: -model.wingSpan * 0.35))
        wingPath.addLine(to: CGPoint(x: -fw * 0.15, y: -model.wingSpan * 0.5))
        wingPath.closeSubpath()

        wingNode = SKShapeNode(path: wingPath)
        wingNode.fillColor = SKColor(hex: "#FF8F00")
        wingNode.strokeColor = SKColor(hex: "#FFD54F")
        wingNode.lineWidth = 2
        wingNode.glowWidth = 4
        addChild(wingNode)

        // Pointed needle nose
        let nosePath = CGMutablePath()
        nosePath.move(to: CGPoint(x: fw * 0.45, y: fh * 0.08))
        nosePath.addLine(to: CGPoint(x: fw * 0.65, y: 0))
        nosePath.addLine(to: CGPoint(x: fw * 0.45, y: -fh * 0.08))
        nosePath.closeSubpath()

        let nose = SKShapeNode(path: nosePath)
        nose.fillColor = SKColor(hex: "#FFECB3")
        nose.strokeColor = SKColor(hex: "#FFD54F")
        nose.lineWidth = 1
        nose.glowWidth = 2
        addChild(nose)

        // Tail with dual vertical stabilizers
        let tailPath = CGMutablePath()
        tailPath.move(to: CGPoint(x: -fw * 0.33, y: fh * 0.1))
        tailPath.addLine(to: CGPoint(x: -fw * 0.45, y: fh * 0.8))
        tailPath.addLine(to: CGPoint(x: -fw * 0.38, y: fh * 0.6))
        tailPath.addLine(to: CGPoint(x: -fw * 0.3, y: fh * 0.1))
        tailPath.closeSubpath()

        tailNode = SKShapeNode(path: tailPath)
        tailNode.fillColor = SKColor(hex: "#EF6C00")
        tailNode.strokeColor = SKColor(hex: "#E65100")
        tailNode.lineWidth = 1
        addChild(tailNode)

        // Lower tail fin
        let lowerTailPath = CGMutablePath()
        lowerTailPath.move(to: CGPoint(x: -fw * 0.33, y: -fh * 0.1))
        lowerTailPath.addLine(to: CGPoint(x: -fw * 0.45, y: -fh * 0.6))
        lowerTailPath.addLine(to: CGPoint(x: -fw * 0.38, y: -fh * 0.45))
        lowerTailPath.addLine(to: CGPoint(x: -fw * 0.3, y: -fh * 0.1))
        lowerTailPath.closeSubpath()

        let lowerTail = SKShapeNode(path: lowerTailPath)
        lowerTail.fillColor = SKColor(hex: "#EF6C00")
        lowerTail.strokeColor = .clear
        addChild(lowerTail)

        // Cockpit (futuristic visor)
        let canopyPath = CGMutablePath()
        canopyPath.move(to: CGPoint(x: fw * 0.15, y: fh * 0.25))
        canopyPath.addLine(to: CGPoint(x: fw * 0.38, y: fh * 0.1))
        canopyPath.addLine(to: CGPoint(x: fw * 0.38, y: fh * 0.0))
        canopyPath.addLine(to: CGPoint(x: fw * 0.15, y: fh * 0.12))
        canopyPath.closeSubpath()

        cockpitNode = SKShapeNode(path: canopyPath)
        cockpitNode.fillColor = SKColor(hex: "#80DEEA").withAlphaComponent(0.85)
        cockpitNode.strokeColor = SKColor(hex: "#4DD0E1")
        cockpitNode.lineWidth = 1
        cockpitNode.glowWidth = 3
        addChild(cockpitNode)

        // Dual engine exhaust openings
        let exhaust1 = SKShapeNode(circleOfRadius: 5)
        exhaust1.fillColor = SKColor(hex: "#FF3D00")
        exhaust1.strokeColor = .clear
        exhaust1.glowWidth = 6
        exhaust1.position = CGPoint(x: -fw * 0.45, y: fh * 0.08)
        exhaust1.alpha = 0.8
        addChild(exhaust1)

        let exhaust2 = SKShapeNode(circleOfRadius: 5)
        exhaust2.fillColor = SKColor(hex: "#FF3D00")
        exhaust2.strokeColor = .clear
        exhaust2.glowWidth = 6
        exhaust2.position = CGPoint(x: -fw * 0.45, y: -fh * 0.08)
        exhaust2.alpha = 0.8
        addChild(exhaust2)

        // Pulsing exhaust glow
        let exhaustPulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.5, duration: 0.1),
            SKAction.fadeAlpha(to: 1.0, duration: 0.1)
        ])
        exhaust1.run(SKAction.repeatForever(exhaustPulse))
        exhaust2.run(SKAction.repeatForever(exhaustPulse))

        // Light ray effect - subtle pulsing glow around entire plane
        let auraNode = SKShapeNode(ellipseOf: CGSize(width: fw * 1.2, height: fh * 2.0))
        auraNode.fillColor = SKColor(hex: "#FFD54F").withAlphaComponent(0.05)
        auraNode.strokeColor = SKColor(hex: "#FFD54F").withAlphaComponent(0.15)
        auraNode.lineWidth = 2
        auraNode.glowWidth = 8
        auraNode.zPosition = -1
        addChild(auraNode)

        let auraPulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.8),
            SKAction.fadeAlpha(to: 0.7, duration: 0.8)
        ])
        auraNode.run(SKAction.repeatForever(auraPulse))
    }

    // MARK: - Physics

    private func setupPhysics() {
        let bodySize = model.bodySize
        let body = SKPhysicsBody(rectangleOf: CGSize(width: bodySize.width * 0.8,
                                                      height: bodySize.height * 0.6))
        body.mass = model.mass
        body.restitution = GameConfig.Plane.groundBounceRestitution
        body.friction = 0.3
        body.linearDamping = 0.0
        body.angularDamping = 2.0
        body.allowsRotation = true
        body.categoryBitMask = GameConfig.PhysicsCategory.plane
        body.contactTestBitMask = GameConfig.PhysicsCategory.ground |
            GameConfig.PhysicsCategory.obstacle |
            GameConfig.PhysicsCategory.coin |
            GameConfig.PhysicsCategory.powerUp
        body.collisionBitMask = GameConfig.PhysicsCategory.ground
        body.isDynamic = false // enabled on launch
        physicsBody = body
    }

    // MARK: - Launch

    func launch(with impulse: CGVector) {
        physicsBody?.isDynamic = true
        physicsBody?.applyImpulse(impulse)
        isLaunched = true
        velocity = impulse
        startExhaust()
        spinPropeller()
    }

    // MARK: - Flight Update

    func updateFlight(dt: TimeInterval, pitchInput: CGFloat) {
        guard isLaunched, let body = physicsBody else { return }

        velocity = body.velocity

        let speed = velocity.length
        guard speed > 1 else { return }

        // Pitch control
        let pitchDelta = pitchInput * GameConfig.Plane.pitchSensitivity * CGFloat(dt)
        let currentAngle = radiansToDegrees(zRotation)
        let targetAngle = (currentAngle + pitchDelta * 60).clamped(
            to: GameConfig.Plane.minPitchAngle...GameConfig.Plane.maxPitchAngle
        )
        zRotation = degreesToRadians(targetAngle)

        // Apply forces
        let angle = zRotation
        let direction = CGVector(dx: cos(angle), dy: sin(angle))

        // Thrust
        var thrustMag = model.thrust
        if hasBoost {
            thrustMag *= GameConfig.PowerUps.boostMultiplier
        }
        let thrustForce = direction * thrustMag * CGFloat(dt)

        // Lift (perpendicular to velocity, proportional to speed)
        let liftFactor = min(speed / GameConfig.Plane.maxSpeed, 1.0)
        let stallFactor: CGFloat = abs(currentAngle) > GameConfig.Plane.stallAngle ?
            max(0, 1.0 - (abs(currentAngle) - GameConfig.Plane.stallAngle) / 30.0) : 1.0
        let liftMag = model.lift * liftFactor * stallFactor * CGFloat(dt)
        let liftForce = CGVector(dx: -direction.dy * liftMag, dy: direction.dx * liftMag)

        // Drag (opposes velocity)
        let dragMag = model.drag * speed * CGFloat(dt)
        let velNorm = velocity.normalized
        let dragForce = CGVector(dx: -velNorm.dx * dragMag, dy: -velNorm.dy * dragMag)

        // Apply
        body.applyForce(thrustForce + liftForce + dragForce)

        // Clamp speed
        if body.velocity.length > GameConfig.Plane.maxSpeed {
            let clamped = body.velocity.normalized * GameConfig.Plane.maxSpeed
            body.velocity = clamped
        }

        // Thrust decay
        if pitchInput == 0 {
            body.velocity = body.velocity * GameConfig.Plane.idleThrustDecay
        }

        // Update boost timer
        if hasBoost {
            boostTimer -= dt
            if boostTimer <= 0 {
                deactivateBoost()
            }
        }
    }

    // MARK: - Power-ups

    func activateShield() {
        hasShield = true
        if shieldNode == nil {
            let shield = SKShapeNode(circleOfRadius: model.bodySize.width * 0.7)
            shield.fillColor = SKColor(hex: "#4ECDC4").withAlphaComponent(0.1)
            shield.strokeColor = SKColor(hex: "#4ECDC4").withAlphaComponent(0.6)
            shield.lineWidth = 2.5
            shield.glowWidth = 6
            addChild(shield)
            shieldNode = shield

            // Hexagonal pattern inner decoration
            let innerRing = SKShapeNode(circleOfRadius: model.bodySize.width * 0.55)
            innerRing.fillColor = .clear
            innerRing.strokeColor = SKColor(hex: "#4ECDC4").withAlphaComponent(0.3)
            innerRing.lineWidth = 1
            shield.addChild(innerRing)

            let pulse = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.4, duration: 0.5),
                SKAction.fadeAlpha(to: 0.8, duration: 0.5)
            ])
            shield.run(SKAction.repeatForever(pulse))

            // Rotating ring effect
            let rotate = SKAction.rotate(byAngle: .pi * 2, duration: 4.0)
            innerRing.run(SKAction.repeatForever(rotate))
        }

        run(SKAction.sequence([
            SKAction.wait(forDuration: GameConfig.PowerUps.shieldDuration),
            SKAction.run { [weak self] in self?.deactivateShield() }
        ]), withKey: "shieldTimer")
    }

    func deactivateShield() {
        hasShield = false
        shieldNode?.removeFromParent()
        shieldNode = nil
        removeAction(forKey: "shieldTimer")
    }

    func activateBoost() {
        hasBoost = true
        boostTimer = GameConfig.PowerUps.boostDuration

        // Orange tint effect
        bodyNode.run(SKAction.sequence([
            SKAction.colorize(with: .orange, colorBlendFactor: 0.5, duration: 0.2),
            SKAction.wait(forDuration: GameConfig.PowerUps.boostDuration - 0.4),
            SKAction.colorize(withColorBlendFactor: 0, duration: 0.2)
        ]), withKey: "boostVisual")

        // Speed lines effect
        addSpeedLines()
    }

    private func addSpeedLines() {
        let lineCount = 5
        for i in 0..<lineCount {
            let line = SKShapeNode(rectOf: CGSize(width: 20 + CGFloat(i) * 4, height: 1.5))
            line.fillColor = SKColor.white.withAlphaComponent(0.6)
            line.strokeColor = .clear
            line.position = CGPoint(x: -model.bodySize.width * 0.6 - CGFloat(i) * 8,
                                    y: CGFloat(i - lineCount / 2) * 6)
            line.alpha = 0
            addChild(line)

            let fadeIn = SKAction.fadeAlpha(to: 0.6 - CGFloat(i) * 0.1, duration: 0.2)
            let wait = SKAction.wait(forDuration: GameConfig.PowerUps.boostDuration - 0.5)
            let fadeOut = SKAction.fadeOut(withDuration: 0.3)
            line.run(SKAction.sequence([fadeIn, wait, fadeOut, SKAction.removeFromParent()]))
        }
    }

    private func deactivateBoost() {
        hasBoost = false
        bodyNode.removeAction(forKey: "boostVisual")
        NotificationCenter.default.post(name: .powerUpExpired, object: PowerUpType.speedBoost)
    }

    func activateMagnet() {
        hasMagnet = true
        run(SKAction.sequence([
            SKAction.wait(forDuration: GameConfig.PowerUps.magnetDuration),
            SKAction.run { [weak self] in
                self?.hasMagnet = false
                NotificationCenter.default.post(name: .powerUpExpired, object: PowerUpType.coinMagnet)
            }
        ]), withKey: "magnetTimer")
    }

    /// Returns true if the shield absorbed the hit (plane survives).
    func handleObstacleHit() -> Bool {
        if hasShield {
            deactivateShield()
            return true
        }
        return false
    }

    // MARK: - Visual Effects

    private func startExhaust() {
        let emitter = SKEmitterNode()

        switch model.currentStage {
        case .propeller:
            emitter.particleBirthRate = 40
            emitter.particleLifetime = 0.3
            emitter.particleLifetimeRange = 0.1
            emitter.particleSpeed = 30
            emitter.particleSpeedRange = 10
            emitter.particleScale = 0.08
            emitter.particleScaleRange = 0.04
            emitter.particleColor = SKColor(hex: "#9E9E9E")
            emitter.particleColorBlendFactor = 1.0
            emitter.particleAlpha = 0.5
            emitter.particleAlphaSpeed = -1.5

        case .turboProp:
            emitter.particleBirthRate = 60
            emitter.particleLifetime = 0.4
            emitter.particleLifetimeRange = 0.15
            emitter.particleSpeed = 40
            emitter.particleSpeedRange = 15
            emitter.particleScale = 0.12
            emitter.particleScaleRange = 0.06
            emitter.particleAlpha = 0.6
            emitter.particleAlphaSpeed = -1.3
            emitter.particleColor = .gray
            emitter.particleColorBlendFactor = 1.0
            emitter.particleColorSequence = SKKeyframeSequence(
                keyframeValues: [SKColor.lightGray, SKColor.gray, SKColor.darkGray],
                times: [0 as NSNumber, 0.4 as NSNumber, 1.0 as NSNumber]
            )

        case .jet:
            emitter.particleBirthRate = 100
            emitter.particleLifetime = 0.5
            emitter.particleLifetimeRange = 0.2
            emitter.particleSpeed = 60
            emitter.particleSpeedRange = 25
            emitter.particleScale = 0.15
            emitter.particleScaleRange = 0.08
            emitter.particleScaleSpeed = -0.2
            emitter.particleAlpha = 0.8
            emitter.particleAlphaSpeed = -1.5
            emitter.particleColor = .orange
            emitter.particleColorBlendFactor = 1.0
            emitter.particleColorSequence = SKKeyframeSequence(
                keyframeValues: [SKColor.white, SKColor.yellow, SKColor.orange, SKColor(hex: "#424242")],
                times: [0 as NSNumber, 0.2 as NSNumber, 0.5 as NSNumber, 1.0 as NSNumber]
            )

        case .rocket:
            emitter.particleBirthRate = 180
            emitter.particleLifetime = 0.7
            emitter.particleLifetimeRange = 0.3
            emitter.particleSpeed = 80
            emitter.particleSpeedRange = 30
            emitter.particleScale = 0.2
            emitter.particleScaleRange = 0.1
            emitter.particleScaleSpeed = -0.15
            emitter.particleAlpha = 0.9
            emitter.particleAlphaSpeed = -1.2
            emitter.particleColor = .white
            emitter.particleColorBlendFactor = 1.0
            emitter.particleColorSequence = SKKeyframeSequence(
                keyframeValues: [SKColor.white, SKColor.yellow, SKColor.orange, SKColor(hex: "#FF3D00"), SKColor(hex: "#212121")],
                times: [0 as NSNumber, 0.15 as NSNumber, 0.35 as NSNumber, 0.6 as NSNumber, 1.0 as NSNumber]
            )
        }

        emitter.emissionAngle = .pi  // behind the plane
        emitter.emissionAngleRange = 0.25

        let texture = SKTexture.placeholder(color: .white, size: CGSize(width: 8, height: 8))
        emitter.particleTexture = texture
        emitter.position = CGPoint(x: -model.bodySize.width * 0.5, y: 0)
        emitter.zPosition = -1
        emitter.targetNode = scene
        addChild(emitter)
        exhaustEmitter = emitter
    }

    func stopExhaust() {
        exhaustEmitter?.particleBirthRate = 0
    }

    private func spinPropeller() {
        guard let prop = propellerNode else { return }
        let duration: TimeInterval = model.currentStage == .propeller ? 0.12 : 0.07
        let spin = SKAction.rotate(byAngle: .pi * 2, duration: duration)
        prop.run(SKAction.repeatForever(spin), withKey: "spin")
    }

    func stopPropeller() {
        propellerNode?.removeAction(forKey: "spin")
    }

    // MARK: - Crash

    func playCrashEffect() {
        stopExhaust()
        stopPropeller()

        // Explosion particles
        let dust = SKEmitterNode()
        dust.particleBirthRate = 300
        dust.numParticlesToEmit = 50
        dust.particleLifetime = 0.8
        dust.particleLifetimeRange = 0.3
        dust.particleSpeed = 150
        dust.particleSpeedRange = 80
        dust.emissionAngleRange = .pi * 2
        dust.particleScale = 0.2
        dust.particleScaleRange = 0.15
        dust.particleScaleSpeed = -0.2
        dust.particleAlpha = 0.9
        dust.particleAlphaSpeed = -1.0
        dust.particleColorBlendFactor = 1.0
        dust.particleColorSequence = SKKeyframeSequence(
            keyframeValues: [SKColor.yellow, SKColor.orange, SKColor(hex: "#8D6E63"), SKColor.darkGray],
            times: [0 as NSNumber, 0.2 as NSNumber, 0.5 as NSNumber, 1.0 as NSNumber]
        )
        let tex = SKTexture.placeholder(color: .white, size: CGSize(width: 8, height: 8))
        dust.particleTexture = tex
        dust.position = position
        dust.zPosition = GameConfig.ZPosition.particles
        parent?.addChild(dust)

        dust.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.5),
            SKAction.removeFromParent()
        ]))

        // Debris pieces
        let bodyColor = SKColor(hex: model.bodyColorHex)
        for _ in 0..<6 {
            let debris = SKShapeNode(rectOf: CGSize(width: CGFloat.random(in: 5...12),
                                                     height: CGFloat.random(in: 3...8)),
                                      cornerRadius: 2)
            debris.fillColor = bodyColor
            debris.strokeColor = .clear
            debris.position = position
            debris.zPosition = GameConfig.ZPosition.particles
            parent?.addChild(debris)

            let angle = CGFloat.random(in: 0...(.pi * 2))
            let dist = CGFloat.random(in: 40...100)
            let moveAction = SKAction.move(by: CGVector(dx: cos(angle) * dist, dy: sin(angle) * dist),
                                            duration: 0.6)
            let rotateAction = SKAction.rotate(byAngle: CGFloat.random(in: -4...4), duration: 0.6)
            let fadeAction = SKAction.fadeOut(withDuration: 0.6)
            debris.run(SKAction.sequence([
                SKAction.group([moveAction, rotateAction, fadeAction]),
                SKAction.removeFromParent()
            ]))
        }
    }

    // MARK: - Update Model

    func updateModel(_ newModel: PlaneModel) {
        model = newModel
        removeAllChildren()
        exhaustEmitter = nil
        shieldNode = nil
        propellerNode = nil
        buildPlane()
        setupPhysics()
    }

    // MARK: - Reset

    func reset(at launchPosition: CGPoint) {
        position = launchPosition
        zRotation = 0
        velocity = .zero
        isLaunched = false
        hasShield = false
        hasMagnet = false
        hasBoost = false
        boostTimer = 0
        physicsBody?.isDynamic = false
        physicsBody?.velocity = .zero
        physicsBody?.angularVelocity = 0
        stopExhaust()
        stopPropeller()
        exhaustEmitter?.removeFromParent()
        exhaustEmitter = nil
        shieldNode?.removeFromParent()
        shieldNode = nil
        removeAllActions()
    }
}
