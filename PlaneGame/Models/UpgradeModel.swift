import Foundation
import CoreGraphics

// MARK: - UpgradeModel

struct UpgradeModel: Codable, Identifiable {
    let id: String
    let type: UpgradeType
    var currentLevel: Int
    let maxLevel: Int

    var isMaxed: Bool { currentLevel >= maxLevel }

    var cost: Int {
        GameConfig.Upgrades.cost(forLevel: currentLevel)
    }

    var nextLevelCost: Int? {
        guard !isMaxed else { return nil }
        return cost
    }

    var progressFraction: CGFloat {
        CGFloat(currentLevel) / CGFloat(maxLevel)
    }

    var statDescription: String {
        switch type {
        case .engine:
            let current = GameConfig.Plane.baseThrust + CGFloat(currentLevel) * GameConfig.Upgrades.thrustPerLevel
            let next = current + GameConfig.Upgrades.thrustPerLevel
            return isMaxed ? "Thrust: \(Int(current))" : "Thrust: \(Int(current)) → \(Int(next))"
        case .wings:
            let current = GameConfig.Plane.baseLift + CGFloat(currentLevel) * GameConfig.Upgrades.liftPerLevel
            let next = current + GameConfig.Upgrades.liftPerLevel
            return isMaxed ? "Lift: \(Int(current))" : "Lift: \(Int(current)) → \(Int(next))"
        case .fuselage:
            let current = GameConfig.Plane.baseDrag - CGFloat(currentLevel) * GameConfig.Upgrades.dragReductionPerLevel
            let next = current - GameConfig.Upgrades.dragReductionPerLevel
            return isMaxed ? "Drag: \(String(format: "%.2f", current))" :
                "Drag: \(String(format: "%.2f", current)) → \(String(format: "%.2f", next))"
        }
    }

    // MARK: - Factory

    static func allUpgrades(from plane: PlaneModel) -> [UpgradeModel] {
        UpgradeType.allCases.map { type in
            UpgradeModel(
                id: type.rawValue,
                type: type,
                currentLevel: plane.level(for: type),
                maxLevel: GameConfig.Upgrades.maxLevel
            )
        }
    }
}

// MARK: - UpgradeResult

struct UpgradeResult {
    let type: UpgradeType
    let newLevel: Int
    let coinsSpent: Int
    let newStage: PlaneStage?
}
