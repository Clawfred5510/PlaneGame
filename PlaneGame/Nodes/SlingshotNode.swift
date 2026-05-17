import SpriteKit

// MARK: - SlingshotNode

final class SlingshotNode: SKNode {

    // MARK: - Properties

    private var leftFork: SKShapeNode!
    private var rightFork: SKShapeNode!
    private var base: SKShapeNode!
    private var bandLeft: SKShapeNode!
    private var bandRight: SKShapeNode!
    private var pouch: SKShapeNode!
    private var powerIndicator: SKShapeNode!
    private var angleIndicator: SKShapeNode!
    private var powerLabel: SKLabelNode!
    private var trajectoryDots: [SKShapeNode] = []
    private var woodGrainDetails: [SKShapeNode] = []

    private let forkWidth = GameConfig.Slingshot.forkWidth
    private let forkHeight = GameConfig.Slingshot.forkHeight
    private let bandWidth = GameConfig.Slingshot.bandWidth

    private var leftForkTop: CGPoint {
        CGPoint(x: -forkWidth / 2, y: forkHeight)
    }

    private var rightForkTop: CGPoint {
        CGPoint(x: forkWidth / 2, y: forkHeight)
    }

    private(set) var pullPosition: CGPoint = .zero
    private(set) var isPulling = false
    var launchPower: CGFloat = 0
    var launchAngle: CGFloat = 0

    // MARK: - Init

    override init() {
        super.init()
        buildSlingshot()
        zPosition = GameConfig.ZPosition.slingshot
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    // MARK: - Build

    private func buildSlingshot() {
        buildWoodenFork()
        buildBands()
        buildPouch()
        buildIndicators()
        updateBands(at: CGPoint(x: 0, y: forkHeight))
    }

    private func buildWoodenFork() {
        // Y-shaped wooden fork drawn with organic curves
        let forkPath = CGMutablePath()

        // Left prong (curved wood)
        forkPath.move(to: CGPoint(x: -8, y: 0))
        forkPath.addCurve(to: CGPoint(x: -forkWidth / 2 - 5, y: forkHeight),
                          control1: CGPoint(x: -10, y: forkHeight * 0.3),
                          control2: CGPoint(x: -forkWidth / 2 - 8, y: forkHeight * 0.7))
        // Left prong top
        forkPath.addLine(to: CGPoint(x: -forkWidth / 2 + 5, y: forkHeight + 6))
        forkPath.addLine(to: CGPoint(x: -forkWidth / 2 + 8, y: forkHeight))
        // Back down left inner
        forkPath.addCurve(to: CGPoint(x: -4, y: forkHeight * 0.35),
                          control1: CGPoint(x: -forkWidth / 2 + 4, y: forkHeight * 0.7),
                          control2: CGPoint(x: -6, y: forkHeight * 0.5))

        // Center junction (Y-fork crotch)
        forkPath.addCurve(to: CGPoint(x: 4, y: forkHeight * 0.35),
                          control1: CGPoint(x: -2, y: forkHeight * 0.3),
                          control2: CGPoint(x: 2, y: forkHeight * 0.3))

        // Right prong inner
        forkPath.addCurve(to: CGPoint(x: forkWidth / 2 - 8, y: forkHeight),
                          control1: CGPoint(x: 6, y: forkHeight * 0.5),
                          control2: CGPoint(x: forkWidth / 2 - 4, y: forkHeight * 0.7))
        // Right prong top
        forkPath.addLine(to: CGPoint(x: forkWidth / 2 - 5, y: forkHeight + 6))
        forkPath.addLine(to: CGPoint(x: forkWidth / 2 + 5, y: forkHeight))
        // Right outer
        forkPath.addCurve(to: CGPoint(x: 8, y: 0),
                          control1: CGPoint(x: forkWidth / 2 + 8, y: forkHeight * 0.7),
                          control2: CGPoint(x: 10, y: forkHeight * 0.3))

        // Base/handle
        forkPath.addLine(to: CGPoint(x: 10, y: -20))
        forkPath.addCurve(to: CGPoint(x: -10, y: -20),
                          control1: CGPoint(x: 8, y: -25),
                          control2: CGPoint(x: -8, y: -25))
        forkPath.addLine(to: CGPoint(x: -8, y: 0))
        forkPath.closeSubpath()

        base = SKShapeNode(path: forkPath)
        base.fillColor = SKColor(hex: "#6D4C41")
        base.strokeColor = SKColor(hex: "#3E2723")
        base.lineWidth = 2
        addChild(base)

        // Wood grain texture lines
        addWoodGrain()

        // Fork tip knobs (rounded caps on prong tops)
        let leftKnob = SKShapeNode(circleOfRadius: 6)
        leftKnob.fillColor = SKColor(hex: "#5D4037")
        leftKnob.strokeColor = SKColor(hex: "#3E2723")
        leftKnob.lineWidth = 1.5
        leftKnob.position = leftForkTop
        addChild(leftKnob)

        let rightKnob = SKShapeNode(circleOfRadius: 6)
        rightKnob.fillColor = SKColor(hex: "#5D4037")
        rightKnob.strokeColor = SKColor(hex: "#3E2723")
        rightKnob.lineWidth = 1.5
        rightKnob.position = rightForkTop
        addChild(rightKnob)

        // Darker wood highlight on the left side
        let shadowPath = CGMutablePath()
        shadowPath.move(to: CGPoint(x: -7, y: 5))
        shadowPath.addCurve(to: CGPoint(x: -forkWidth / 2 - 3, y: forkHeight * 0.85),
                            control1: CGPoint(x: -9, y: forkHeight * 0.3),
                            control2: CGPoint(x: -forkWidth / 2 - 5, y: forkHeight * 0.6))
        let shadow = SKShapeNode(path: shadowPath)
        shadow.strokeColor = SKColor(hex: "#4E342E").withAlphaComponent(0.5)
        shadow.lineWidth = 3
        shadow.lineCap = .round
        shadow.fillColor = .clear
        addChild(shadow)
    }

    private func addWoodGrain() {
        // Horizontal wood grain lines on the handle
        for i in 0..<4 {
            let yPos = CGFloat(i) * 8 - 10
            let grainPath = CGMutablePath()
            grainPath.move(to: CGPoint(x: -6, y: yPos))
            grainPath.addCurve(to: CGPoint(x: 6, y: yPos + 2),
                               control1: CGPoint(x: -2, y: yPos + 1),
                               control2: CGPoint(x: 3, y: yPos - 1))
            let grain = SKShapeNode(path: grainPath)
            grain.strokeColor = SKColor(hex: "#4E342E").withAlphaComponent(0.4)
            grain.lineWidth = 0.8
            grain.fillColor = .clear
            addChild(grain)
            woodGrainDetails.append(grain)
        }
    }

    private func buildBands() {
        // Left rubber band
        bandLeft = SKShapeNode()
        bandLeft.strokeColor = SKColor(hex: "#D32F2F")
        bandLeft.lineWidth = bandWidth
        bandLeft.lineCap = .round
        bandLeft.glowWidth = 1
        addChild(bandLeft)

        // Right rubber band
        bandRight = SKShapeNode()
        bandRight.strokeColor = SKColor(hex: "#D32F2F")
        bandRight.lineWidth = bandWidth
        bandRight.lineCap = .round
        bandRight.glowWidth = 1
        addChild(bandRight)
    }

    private func buildPouch() {
        // Leather pouch
        let pouchPath = CGMutablePath()
        pouchPath.addEllipse(in: CGRect(x: -12, y: -8, width: 24, height: 16))

        pouch = SKShapeNode(path: pouchPath)
        pouch.fillColor = SKColor(hex: "#4E342E")
        pouch.strokeColor = SKColor(hex: "#3E2723")
        pouch.lineWidth = 1.5
        pouch.position = CGPoint(x: 0, y: forkHeight)
        pouch.isHidden = true
        addChild(pouch)
    }

    private func buildIndicators() {
        // Power arc indicator
        powerIndicator = SKShapeNode()
        powerIndicator.strokeColor = SKColor(hex: GameConfig.UI.secondaryColor).withAlphaComponent(0.6)
        powerIndicator.lineWidth = 3
        powerIndicator.glowWidth = 2
        powerIndicator.isHidden = true
        addChild(powerIndicator)

        // Angle indicator arc
        angleIndicator = SKShapeNode()
        angleIndicator.strokeColor = SKColor.white.withAlphaComponent(0.4)
        angleIndicator.lineWidth = 1.5
        angleIndicator.isHidden = true
        addChild(angleIndicator)

        // Power percentage label
        powerLabel = SKLabelNode.styled(
            text: "",
            fontSize: 16,
            fontName: GameConfig.UI.fontNameRegular,
            color: .white
        )
        powerLabel.isHidden = true
        powerLabel.position = CGPoint(x: 0, y: forkHeight + 40)
        addChild(powerLabel)
    }

    // MARK: - Pull Interaction

    func beginPull(at point: CGPoint) {
        isPulling = true
        pouch.isHidden = false
        powerIndicator.isHidden = false
        powerLabel.isHidden = false
        angleIndicator.isHidden = false
        updatePull(to: point)
    }

    func updatePull(to point: CGPoint) {
        guard isPulling else { return }

        // Clamp pull distance
        let localPoint = convert(point, from: parent!)
        let anchor = CGPoint(x: 0, y: forkHeight)
        let offset = localPoint - anchor
        let distance = offset.length.clamped(to: 0...GameConfig.Slingshot.maxPullDistance)

        let direction = offset.length > 0 ? offset.normalized : CGPoint(x: 0, y: -1)
        pullPosition = anchor + direction * distance

        // Calculate launch parameters (launch is opposite of pull direction)
        let pullFraction = inverseLerp(
            GameConfig.Slingshot.minPullDistance,
            GameConfig.Slingshot.maxPullDistance,
            distance
        )
        launchPower = lerp(
            GameConfig.Slingshot.minLaunchPower,
            GameConfig.Slingshot.maxLaunchPower,
            pullFraction
        )

        // Angle: opposite of pull direction
        let launchDir = CGPoint.zero - direction
        let rawAngle = radiansToDegrees(atan2(launchDir.y, launchDir.x))
        launchAngle = rawAngle.clamped(
            to: GameConfig.Slingshot.minLaunchAngle...GameConfig.Slingshot.maxLaunchAngle
        )

        updateBands(at: pullPosition)
        updateIndicators(power: pullFraction, angle: launchAngle)
        updateTrajectoryPreview()
    }

    func release() -> CGVector? {
        guard isPulling else { return nil }
        isPulling = false

        let anchor = CGPoint(x: 0, y: forkHeight)
        let distance = (pullPosition - anchor).length
        guard distance >= GameConfig.Slingshot.minPullDistance else {
            resetVisuals()
            return nil
        }

        let angleRad = degreesToRadians(launchAngle)
        let impulse = CGVector(
            dx: cos(angleRad) * launchPower,
            dy: sin(angleRad) * launchPower
        )

        // Snap back animation with elastic bounce
        let snapBack = SKAction.run { [weak self] in
            self?.animateSnapBack()
        }
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.02),
            snapBack
        ]))

        return impulse
    }

    // MARK: - Snap Animation

    private func animateSnapBack() {
        let restPos = CGPoint(x: 0, y: forkHeight)

        // Animate bands snapping back with overshoot
        let duration: TimeInterval = 0.15
        let overshootPos = CGPoint(x: 0, y: forkHeight + 8)

        // Quick snap
        let snapAction = SKAction.customAction(withDuration: duration) { [weak self] _, elapsed in
            guard let self = self else { return }
            let t = CGFloat(elapsed / duration)
            let eased = 1.0 - pow(1.0 - t, 3.0) // ease out cubic
            let currentPos: CGPoint
            if t < 0.7 {
                let subT = t / 0.7
                currentPos = CGPoint(
                    x: self.pullPosition.x + (overshootPos.x - self.pullPosition.x) * subT,
                    y: self.pullPosition.y + (overshootPos.y - self.pullPosition.y) * subT
                )
            } else {
                let subT = (t - 0.7) / 0.3
                currentPos = CGPoint(
                    x: overshootPos.x + (restPos.x - overshootPos.x) * subT,
                    y: overshootPos.y + (restPos.y - overshootPos.y) * subT
                )
            }
            self.updateBands(at: currentPos)
        }

        run(SKAction.sequence([
            snapAction,
            SKAction.run { [weak self] in self?.resetVisuals() }
        ]))
    }

    // MARK: - Visual Updates

    private func updateBands(at pouchPos: CGPoint) {
        // Left band with slight curve
        let leftPath = CGMutablePath()
        leftPath.move(to: leftForkTop)
        let leftMid = CGPoint(
            x: (leftForkTop.x + pouchPos.x) / 2 - 3,
            y: (leftForkTop.y + pouchPos.y) / 2 + 2
        )
        leftPath.addQuadCurve(to: pouchPos, control: leftMid)
        bandLeft.path = leftPath

        // Right band with slight curve
        let rightPath = CGMutablePath()
        rightPath.move(to: rightForkTop)
        let rightMid = CGPoint(
            x: (rightForkTop.x + pouchPos.x) / 2 + 3,
            y: (rightForkTop.y + pouchPos.y) / 2 + 2
        )
        rightPath.addQuadCurve(to: pouchPos, control: rightMid)
        bandRight.path = rightPath

        pouch.position = pouchPos

        // Band stretch visual feedback - thinner as they stretch more
        let anchor = CGPoint(x: 0, y: forkHeight)
        let stretchFraction = (pouchPos - anchor).length / GameConfig.Slingshot.maxPullDistance

        // Bands get thinner as they stretch
        let thickness = bandWidth * (1.0 - stretchFraction * 0.4)
        bandLeft.lineWidth = thickness
        bandRight.lineWidth = thickness

        // Color shifts from red to brighter red under tension
        if stretchFraction > 0.7 {
            let tensionColor = SKColor(hex: "#F44336")
            bandLeft.strokeColor = tensionColor
            bandRight.strokeColor = tensionColor
            bandLeft.glowWidth = 3
            bandRight.glowWidth = 3
        } else if stretchFraction > 0.4 {
            let medColor = SKColor(hex: "#E53935")
            bandLeft.strokeColor = medColor
            bandRight.strokeColor = medColor
            bandLeft.glowWidth = 2
            bandRight.glowWidth = 2
        } else {
            let restColor = SKColor(hex: "#D32F2F")
            bandLeft.strokeColor = restColor
            bandRight.strokeColor = restColor
            bandLeft.glowWidth = 1
            bandRight.glowWidth = 1
        }
    }

    private func updateIndicators(power: CGFloat, angle: CGFloat) {
        // Power arc - wider arc showing trajectory direction
        let arcRadius: CGFloat = 55 + power * 20
        let halfArc: CGFloat = 3 + power * 8
        let startAngle = degreesToRadians(angle - halfArc)
        let endAngle = degreesToRadians(angle + halfArc)
        let arcPath = CGMutablePath()
        arcPath.addArc(
            center: CGPoint(x: 0, y: forkHeight),
            radius: arcRadius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        powerIndicator.path = arcPath
        powerIndicator.strokeColor = SKColor(hex: GameConfig.UI.secondaryColor).withAlphaComponent(0.4 + power * 0.4)

        // Angle indicator (thin arc from 0 to launch angle)
        let angleArcPath = CGMutablePath()
        angleArcPath.addArc(
            center: CGPoint(x: 0, y: forkHeight),
            radius: 35,
            startAngle: 0,
            endAngle: degreesToRadians(angle),
            clockwise: false
        )
        angleIndicator.path = angleArcPath

        // Power label with angle readout
        let powerPercent = Int(power * 100)
        let angleInt = Int(angle)
        powerLabel.text = "\(powerPercent)% | \(angleInt) deg"
        let labelOffset = CGPoint(x: cos(degreesToRadians(angle)) * 80,
                                   y: sin(degreesToRadians(angle)) * 80)
        powerLabel.position = CGPoint(x: 0, y: forkHeight) + labelOffset
    }

    private func updateTrajectoryPreview() {
        // Remove old dots
        for dot in trajectoryDots {
            dot.removeFromParent()
        }
        trajectoryDots.removeAll()

        guard isPulling, launchPower > GameConfig.Slingshot.minLaunchPower else { return }

        // Draw dotted trajectory line
        let points = trajectoryPoints(steps: 15)
        let origin = convert(CGPoint(x: 0, y: forkHeight), to: parent!)

        for (i, point) in points.enumerated() {
            let localPoint = convert(point, from: parent!)
            let alpha = CGFloat(1.0 - Double(i) / Double(points.count)) * 0.6
            let radius: CGFloat = 3.0 - CGFloat(i) * 0.15

            let dot = SKShapeNode(circleOfRadius: max(1.5, radius))
            dot.fillColor = SKColor.white.withAlphaComponent(alpha)
            dot.strokeColor = .clear
            dot.glowWidth = 1
            dot.position = localPoint
            addChild(dot)
            trajectoryDots.append(dot)
        }
    }

    private func resetVisuals() {
        let restPos = CGPoint(x: 0, y: forkHeight)
        updateBands(at: restPos)
        pouch.isHidden = true
        powerIndicator.isHidden = true
        powerLabel.isHidden = true
        angleIndicator.isHidden = true
        pullPosition = restPos
        launchPower = 0
        launchAngle = 0

        // Clear trajectory dots
        for dot in trajectoryDots {
            dot.removeFromParent()
        }
        trajectoryDots.removeAll()
    }

    // MARK: - Trajectory Preview

    func trajectoryPoints(steps: Int = 20) -> [CGPoint] {
        guard isPulling, launchPower > 0 else { return [] }

        let angleRad = degreesToRadians(launchAngle)
        let vx = cos(angleRad) * launchPower
        let vy = sin(angleRad) * launchPower
        let gravity = GameConfig.World.gravity
        let dt: CGFloat = 0.08

        var points: [CGPoint] = []
        let origin = convert(CGPoint(x: 0, y: forkHeight), to: parent!)

        for i in 0..<steps {
            let t = CGFloat(i) * dt
            let x = origin.x + vx * t
            let y = origin.y + vy * t + 0.5 * gravity * t * t * 100
            if y < GameConfig.World.groundY { break }
            points.append(CGPoint(x: x, y: y))
        }

        return points
    }
}
