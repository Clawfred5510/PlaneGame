import SpriteKit

// MARK: - CoinSystem

final class CoinSystem {

    // MARK: - Properties

    private weak var scene: SKScene?
    private var coins: [CoinNode] = []
    private var powerUps: [PowerUpNode] = []
    private var lastSpawnX: CGFloat = 0
    private var lastPowerUpX: CGFloat = 0
    private(set) var coinsCollected: Int = 0

    // MARK: - Init

    init(scene: SKScene) {
        self.scene = scene
    }

    // MARK: - Spawn Coins

    func update(cameraX: CGFloat, planeY: CGFloat, distanceTraveled: CGFloat) {
        spawnCoinsIfNeeded(cameraX: cameraX, planeY: planeY)
        spawnPowerUpIfNeeded(cameraX: cameraX, distanceTraveled: distanceTraveled)
        despawnOffscreen(cameraX: cameraX)
    }

    private func spawnCoinsIfNeeded(cameraX: CGFloat, planeY: CGFloat) {
        guard let scene = scene else { return }

        let spawnX = cameraX + scene.size.width
        let threshold = lastSpawnX + GameConfig.Coins.spawnInterval

        guard spawnX > threshold else { return }

        // Spawn a cluster
        let clusterSize = Int.random(in: GameConfig.Coins.clusterSize)
        let baseY = planeY + CGFloat.random(in: -100...150)
        let clampedY = baseY.clamped(to: (GameConfig.World.groundY + 60)...GameConfig.World.ceilingY)

        for i in 0..<clusterSize {
            let coin = CoinNode()
            let offsetX = CGFloat(i) * GameConfig.Coins.clusterSpread * 0.6
            let offsetY = CGFloat.random(in: -GameConfig.Coins.clusterSpread...GameConfig.Coins.clusterSpread) * 0.5
            coin.position = CGPoint(x: spawnX + offsetX, y: clampedY + offsetY)
            scene.addChild(coin)
            coins.append(coin)
        }

        lastSpawnX = spawnX
    }

    private func spawnPowerUpIfNeeded(cameraX: CGFloat, distanceTraveled: CGFloat) {
        guard let scene = scene else { return }
        guard distanceTraveled > GameConfig.PowerUps.spawnMinDistance else { return }

        let spawnX = cameraX + scene.size.width
        let threshold = lastPowerUpX + GameConfig.PowerUps.spawnMinDistance

        guard spawnX > threshold else { return }
        guard CGFloat.random(in: 0...1) < GameConfig.PowerUps.spawnChance else {
            lastPowerUpX = spawnX
            return
        }

        let type = PowerUpType.allCases.randomElement()!
        let powerUp = PowerUpNode(type: type)
        powerUp.position = CGPoint(
            x: spawnX,
            y: CGFloat.random(in: (GameConfig.World.groundY + 100)...600)
        )
        scene.addChild(powerUp)
        powerUps.append(powerUp)
        lastPowerUpX = spawnX
    }

    // MARK: - Magnet

    func applyMagnet(planePosition: CGPoint, magnetRadius: CGFloat, hasMagnetPowerUp: Bool, dt: TimeInterval) {
        let effectiveRadius = hasMagnetPowerUp ? magnetRadius * 2 : magnetRadius

        for coin in coins {
            guard coin.parent != nil else { continue }
            let dist = coin.position.distance(to: planePosition)
            if dist < effectiveRadius {
                coin.attractToward(planePosition, speed: GameConfig.Coins.magnetSpeed, dt: dt)
            }
        }
    }

    // MARK: - Collection

    func collectCoin(_ coin: CoinNode) {
        coin.collect()
        coinsCollected += GameConfig.Coins.baseValue
        coins.removeAll { $0 === coin }
    }

    func collectPowerUp(_ powerUp: PowerUpNode) -> PowerUpType {
        let type = powerUp.type
        powerUp.collect()
        powerUps.removeAll { $0 === powerUp }
        return type
    }

    // MARK: - Despawn

    private func despawnOffscreen(cameraX: CGFloat) {
        let leftBound = cameraX + GameConfig.World.despawnOffsetX

        coins.removeAll { coin in
            if coin.position.x < leftBound {
                coin.removeFromParent()
                return true
            }
            return false
        }

        powerUps.removeAll { pu in
            if pu.position.x < leftBound {
                pu.removeFromParent()
                return true
            }
            return false
        }
    }

    // MARK: - Reset

    func reset() {
        for coin in coins { coin.removeFromParent() }
        for pu in powerUps { pu.removeFromParent() }
        coins.removeAll()
        powerUps.removeAll()
        coinsCollected = 0
        lastSpawnX = 0
        lastPowerUpX = 0
    }
}
