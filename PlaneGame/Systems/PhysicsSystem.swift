import SpriteKit

// MARK: - PhysicsSystem

final class PhysicsSystem: NSObject, SKPhysicsContactDelegate {

    // MARK: - Callbacks

    var onCoinCollected: ((CoinNode) -> Void)?
    var onPowerUpCollected: ((PowerUpNode) -> Void)?
    var onObstacleHit: ((ObstacleNode) -> Void)?
    var onGroundHit: ((CGFloat) -> Void)?  // speed at impact

    // MARK: - Contact Handling

    func didBegin(_ contact: SKPhysicsContact) {
        let (bodyA, bodyB) = sortBodies(contact.bodyA, contact.bodyB)

        guard let nodeA = bodyA.node, let nodeB = bodyB.node else { return }

        // Plane + Coin
        if bodyA.categoryBitMask == GameConfig.PhysicsCategory.plane &&
           bodyB.categoryBitMask == GameConfig.PhysicsCategory.coin {
            if let coin = nodeB as? CoinNode {
                onCoinCollected?(coin)
            }
            return
        }

        // Plane + PowerUp
        if bodyA.categoryBitMask == GameConfig.PhysicsCategory.plane &&
           bodyB.categoryBitMask == GameConfig.PhysicsCategory.powerUp {
            if let powerUp = nodeB as? PowerUpNode {
                onPowerUpCollected?(powerUp)
            }
            return
        }

        // Plane + Obstacle
        if bodyA.categoryBitMask == GameConfig.PhysicsCategory.plane &&
           bodyB.categoryBitMask == GameConfig.PhysicsCategory.obstacle {
            if let obstacle = nodeB as? ObstacleNode {
                onObstacleHit?(obstacle)
            }
            return
        }

        // Plane + Ground
        if bodyA.categoryBitMask == GameConfig.PhysicsCategory.plane &&
           bodyB.categoryBitMask == GameConfig.PhysicsCategory.ground {
            let speed = bodyA.velocity.length
            onGroundHit?(speed)
            return
        }
    }

    // MARK: - Helpers

    /// Sorts bodies so that the lower categoryBitMask is always bodyA.
    private func sortBodies(_ a: SKPhysicsBody, _ b: SKPhysicsBody) -> (SKPhysicsBody, SKPhysicsBody) {
        if a.categoryBitMask <= b.categoryBitMask {
            return (a, b)
        }
        return (b, a)
    }

    // MARK: - World Configuration

    static func configureWorld(for scene: SKScene) {
        scene.physicsWorld.gravity = CGVector(dx: 0, dy: GameConfig.World.gravity)
    }
}
