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
        // Base
        let basePath = CGMutablePath()
        basePath.move(to: CGPoint(x: -12, y: 0))
        basePath.addLine(to: CGPoint(x: -forkWidth / 2 - 4, y: forkHeight * 0.3))
        basePath.addLine(to: CGPoint(x: -forkWidth / 2, y: forkHeight))
        basePath.addLine(to: CGPoint(x: -forkWidth / 2 + 6, y: forkHeight))
        basePath.addLine(to: CGPoint(x: -forkWidth / 2 + 2, y: forkHeight * 0.3))
        basePath.addLine(to: CGPoint(x: 0, y: 0))
        basePath.addLine(to: CGPoint(x: forkWidth / 2 - 2, y: forkHeight * 0.3))
        basePath.addLine(to: CGPoint(x: forkWidth / 2 - 6, y: forkHeight))
        basePath.addLine(to: CGPoint(x: forkWidth / 2, y: forkHeight))
        basePath.addLine(to: CGPoint(x: forkWidth / 2 + 4, y: forkHeight * 0.3))
        basePath.addLine(to: CGPoint(x: 12, y: 0))
        basePath.closeSubpath()

        base = SKShapeNode(path: basePath)
        base.fillColor = SKColor(hex: "#5D4037")
        base.strokeColor = SKColor(hex: "#3E2723")
        base.lineWidth = 2
        addChild(base)

        // Bands (drawn dynamically, start at rest)
        bandLeft = SKShapeNode()
        bandLeft.strokeColor = SKColor(hex: "#D84315")
        bandLeft.lineWidth = bandWidth
        bandLeft.lineCap = .round
        addChild(bandLeft)

        bandRight = SKShapeNode()
        bandRight.strokeColor = SKColor(hex: "#D84315")
        bandRight.lineWidth = bandWidth
        bandRight.lineCap = .round
        addChild(bandRight)

        // Pouch
        pouch = SKShapeNode(circleOfRadius: 10)
        pouch.fillColor = SKColor(hex: "#4E342E")
        pouch.strokeColor = .clear
        pouch.position = CGPoint(x: 0, y: forkHeight)
        pouch.isHidden = true
        addChild(pouch)

        // Power indicator (arc behind slingshot)
        powerIndicator = SKShapeNode()
        powerIndicator.strokeColor = SKColor(hex: GameConfig.UI.secondaryColor).withAlphaComponent(0.6)
        powerIndicator.lineWidth = 4
        powerIndicator.isHidden = true
        addChild(powerIndicator)

        // Angle label
        powerLabel = SKLabelNode.styled(
            text: "",
            fontSize: 16,
            fontName: GameConfig.UI.fontNameRegular,
            color: .white
        )
        powerLabel.isHidden = true
        powerLabel.position = CGPoint(x: 0, y: forkHeight + 40)
        addChild(powerLabel)

        updateBands(at: CGPoint(x: 0, y: forkHeight))
    }

    // MARK: - Pull Interaction

    func beginPull(at point: CGPoint) {
        isPulling = true
        pouch.isHidden = false
        powerIndicator.isHidden = false
        powerLabel.isHidden = false
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

        // Snap back animation
        let snapBack = SKAction.run { [weak self] in
            self?.resetVisuals()
        }
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.05),
            snapBack
        ]))

        return impulse
    }

    // MARK: - Visual Updates

    private func updateBands(at pouchPos: CGPoint) {
        let leftPath = CGMutablePath()
        leftPath.move(to: leftForkTop)
        leftPath.addLine(to: pouchPos)
        bandLeft.path = leftPath

        let rightPath = CGMutablePath()
        rightPath.move(to: rightForkTop)
        rightPath.addLine(to: pouchPos)
        bandRight.path = rightPath

        pouch.position = pouchPos

        // Color based on stretch
        let anchor = CGPoint(x: 0, y: forkHeight)
        let stretchFraction = (pouchPos - anchor).length / GameConfig.Slingshot.maxPullDistance
        let bandColor = stretchFraction > 0.7 ?
            SKColor(hex: "#F44336") : SKColor(hex: "#D84315")
        bandLeft.strokeColor = bandColor
        bandRight.strokeColor = bandColor
    }

    private func updateIndicators(power: CGFloat, angle: CGFloat) {
        // Power arc
        let arcRadius: CGFloat = 60
        let startAngle = degreesToRadians(angle - 5)
        let endAngle = degreesToRadians(angle + 5)
        let arcPath = CGMutablePath()
        arcPath.addArc(
            center: CGPoint(x: 0, y: forkHeight),
            radius: arcRadius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        powerIndicator.path = arcPath

        // Dotted trajectory preview
        powerLabel.text = "\(Int(power * 100))%"
        let labelOffset = CGPoint(x: cos(degreesToRadians(angle)) * 80,
                                   y: sin(degreesToRadians(angle)) * 80)
        powerLabel.position = CGPoint(x: 0, y: forkHeight) + labelOffset
    }

    private func resetVisuals() {
        let restPos = CGPoint(x: 0, y: forkHeight)
        updateBands(at: restPos)
        pouch.isHidden = true
        powerIndicator.isHidden = true
        powerLabel.isHidden = true
        pullPosition = restPos
        launchPower = 0
        launchAngle = 0
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
