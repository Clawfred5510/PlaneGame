import Foundation
import CoreGraphics

// MARK: - UpgradeSystem

final class UpgradeSystem {

    // MARK: - Properties

    private(set) var progress: PlayerProgress

    // MARK: - Init

    init(progress: PlayerProgress) {
        self.progress = progress
    }

    // MARK: - Queries

    func availableUpgrades() -> [UpgradeModel] {
        UpgradeModel.allUpgrades(from: progress.plane)
    }

    func canAfford(_ type: UpgradeType) -> Bool {
        let cost = progress.plane.upgradeCost(for: type)
        return progress.coins >= cost && progress.plane.canUpgrade(type)
    }

    func upgradeInfo(for type: UpgradeType) -> (level: Int, maxLevel: Int, cost: Int, canAfford: Bool) {
        let level = progress.plane.level(for: type)
        let maxLevel = GameConfig.Upgrades.maxLevel
        let cost = progress.plane.upgradeCost(for: type)
        let canAfford = progress.coins >= cost && level < maxLevel
        return (level, maxLevel, cost, canAfford)
    }

    // MARK: - Purchase

    func purchaseUpgrade(_ type: UpgradeType) -> UpgradeResult? {
        guard canAfford(type) else { return nil }

        let result = progress.purchaseUpgrade(type)
        if result != nil {
            progress.save()
            NotificationCenter.default.post(name: .upgradeApplied, object: type)
        }
        return result
    }

    // MARK: - Stats Summary

    func currentStats() -> PlaneStats {
        let plane = progress.plane
        return PlaneStats(
            thrust: plane.thrust,
            lift: plane.lift,
            drag: plane.drag,
            mass: plane.mass,
            magnetRadius: plane.magnetRadius,
            stage: plane.currentStage
        )
    }

    // MARK: - Update Progress

    func updateProgress(_ newProgress: PlayerProgress) {
        self.progress = newProgress
    }
}

// MARK: - PlaneStats

struct PlaneStats {
    let thrust: CGFloat
    let lift: CGFloat
    let drag: CGFloat
    let mass: CGFloat
    let magnetRadius: CGFloat
    let stage: PlaneStage

    var thrustNormalized: CGFloat {
        let max = GameConfig.Plane.baseThrust + CGFloat(GameConfig.Upgrades.maxLevel) * GameConfig.Upgrades.thrustPerLevel
        return thrust / max
    }

    var liftNormalized: CGFloat {
        let max = GameConfig.Plane.baseLift + CGFloat(GameConfig.Upgrades.maxLevel) * GameConfig.Upgrades.liftPerLevel
        return lift / max
    }

    var dragNormalized: CGFloat {
        // Lower drag is better, so invert for display
        let min = GameConfig.Plane.baseDrag - CGFloat(GameConfig.Upgrades.maxLevel) * GameConfig.Upgrades.dragReductionPerLevel
        let max = GameConfig.Plane.baseDrag
        return 1.0 - inverseLerp(min, max, drag)
    }
}
