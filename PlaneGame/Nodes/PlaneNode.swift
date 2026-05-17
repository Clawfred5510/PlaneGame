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

    var speed: CGFloat { velocity.length }
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
        // Body
        let bodySize = model.bodySize
        bodyNode = SKShapeNode(rectOf: bodySize, cornerRadius: bodySize.height * 0.3)
        bodyNode.fillColor = SKColor(hex: model.bodyColorHex)
        bodyNode.strokeColor = SKColor(hex: model.bodyColorHex).withAlphaComponent(0.7)
        bodyNode.lineWidth = 1.5
        addChild(bodyNode)

        // Wings
        let wingPath = CGMutablePath()
        let ws = model.wingSpan / 2
        wingPath.move(to: CGPoint(x: -bodySize.width * 0.1, y: 0))
        wingPath.addLine(to: CGPoint(x: -bodySize.width * 0.15, y: ws))
        wingPath.addLine(to: CGPoint(x: bodySize.width * 0.1, y: ws))
        wingPath.addLine(to: CGPoint(x: bodySize.width * 0.15, y: 0))
        wingPath.addLine(to: CGPoint(x: bodySize.width * 0.15, y: 0))
        wingPath.addLine(to: CGPoint(x: bodySize.width * 0.1, y: -ws))
        wingPath.addLine(to: CGPoint(x: -bodySize.width * 0.15, y: -ws))
        wingPath.closeSubpath()

        wingNode = SKShapeNode(path: wingPath)
        wingNode.fillColor = bodyNode.fillColor.withAlphaComponent(0.8)
        wingNode.strokeColor = .clear
        addChild(wingNode)

        // Tail fin
        let tailPath = CGMutablePath()
        tailPath.move(to: CGPoint(x: -bodySize.width * 0.45, y: 0))
        tailPath.addLine(to: CGPoint(x: -bodySize.width * 0.5, y: bodySize.height * 0.8))
        tailPath.addLine(to: CGPoint(x: -bodySize.width * 0.35, y: bodySize.height * 0.2))
        tailPath.closeSubpath()

        tailNode = SKShapeNode(path: tailPath)
        tailNode.fillColor = bodyNode.fillColor.withAlphaComponent(0.9)
        tailNode.strokeColor = .clear
        addChild(tailNode)

        // Cockpit
        cockpitNode = SKShapeNode(rectOf: CGSize(width: bodySize.width * 0.2, height: bodySize.height * 0.5),
                                   cornerRadius: 4)
        cockpitNode.position = CGPoint(x: bodySize.width * 0.25, y: bodySize.height * 0.1)
        cockpitNode.fillColor = SKColor(hex: "#81D4FA")
        cockpitNode.strokeColor = .clear
        addChild(cockpitNode)

        // Propeller (for prop stages)
        if model.currentStage == .propeller || model.currentStage == .turboProp {
            let prop = SKNode()
            let blade1 = SKShapeNode(rectOf: CGSize(width: 4, height: 24))
            blade1.fillColor = .darkGray
            blade1.strokeColor = .clear
            prop.addChild(blade1)

            let blade2 = SKShapeNode(rectOf: CGSize(width: 24, height: 4))
            blade2.fillColor = .darkGray
            blade2.strokeColor = .clear
            prop.addChild(blade2)

            prop.position = CGPoint(x: bodySize.width * 0.5 + 4, y: 0)
            addChild(prop)
            propellerNode = prop
        }

        zPosition = GameConfig.ZPosition.plane
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
            shield.fillColor = SKColor(hex: "#4ECDC4").withAlphaComponent(0.2)
            shield.strokeColor = SKColor(hex: "#4ECDC4").withAlphaComponent(0.6)
            shield.lineWidth = 2
            shield.glowWidth = 4
            addChild(shield)
            shieldNode = shield

            let pulse = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.4, duration: 0.5),
                SKAction.fadeAlpha(to: 0.8, duration: 0.5)
            ])
            shield.run(SKAction.repeatForever(pulse))
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
        bodyNode.run(SKAction.sequence([
            SKAction.colorize(with: .orange, colorBlendFactor: 0.5, duration: 0.2),
            SKAction.wait(forDuration: GameConfig.PowerUps.boostDuration - 0.4),
            SKAction.colorize(withColorBlendFactor: 0, duration: 0.2)
        ]), withKey: "boostVisual")
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
        emitter.particleBirthRate = 80
        emitter.particleLifetime = 0.4
        emitter.particleLifetimeRange = 0.2
        emitter.particleSpeed = 40
        emitter.particleSpeedRange = 20
        emitter.emissionAngle = .pi  // behind the plane
        emitter.emissionAngleRange = 0.3
        emitter.particleScale = 0.15
        emitter.particleScaleRange = 0.1
        emitter.particleScaleSpeed = -0.2
        emitter.particleAlpha = 0.7
        emitter.particleAlphaSpeed = -1.5
        emitter.particleColor = .orange
        emitter.particleColorBlendFactor = 1.0
        emitter.particleColorSequence = SKKeyframeSequence(
            keyframeValues: [SKColor.yellow, SKColor.orange, SKColor.gray],
            times: [0, 0.3, 1.0]
        )

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
        let spin = SKAction.rotate(byAngle: .pi * 2, duration: 0.1)
        prop.run(SKAction.repeatForever(spin), withKey: "spin")
    }

    func stopPropeller() {
        propellerNode?.removeAction(forKey: "spin")
    }

    // MARK: - Crash

    func playCrashEffect() {
        stopExhaust()
        stopPropeller()

        // Dust particles
        let dust = SKEmitterNode()
        dust.particleBirthRate = 200
        dust.numParticlesToEmit = 30
        dust.particleLifetime = 0.6
        dust.particleSpeed = 100
        dust.particleSpeedRange = 60
        dust.emissionAngleRange = .pi * 2
        dust.particleScale = 0.2
        dust.particleScaleSpeed = -0.3
        dust.particleAlpha = 0.8
        dust.particleAlphaSpeed = -1.2
        dust.particleColor = SKColor(hex: "#8D6E63")
        dust.particleColorBlendFactor = 1.0
        let tex = SKTexture.placeholder(color: .white, size: CGSize(width: 8, height: 8))
        dust.particleTexture = tex
        dust.position = position
        dust.zPosition = GameConfig.ZPosition.particles
        parent?.addChild(dust)

        dust.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.0),
            SKAction.removeFromParent()
        ]))
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
