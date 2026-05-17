import Foundation
import CoreGraphics

// MARK: - PlaneModel

struct PlaneModel: Codable {
    var stage: PlaneStage = .propeller
    var engineLevel: Int = 0
    var wingsLevel: Int = 0
    var fuselageLevel: Int = 0

    // MARK: - Computed Stats

    var totalUpgradeLevel: Int {
        engineLevel + wingsLevel + fuselageLevel
    }

    var currentStage: PlaneStage {
        for stage in PlaneStage.allCases.reversed() {
            if totalUpgradeLevel >= stage.upgradeThreshold {
                return stage
            }
        }
        return .propeller
    }

    var thrust: CGFloat {
        GameConfig.Plane.baseThrust + CGFloat(engineLevel) * GameConfig.Upgrades.thrustPerLevel
    }

    var lift: CGFloat {
        GameConfig.Plane.baseLift + CGFloat(wingsLevel) * GameConfig.Upgrades.liftPerLevel
    }

    var drag: CGFloat {
        max(0.05, GameConfig.Plane.baseDrag - CGFloat(fuselageLevel) * GameConfig.Upgrades.dragReductionPerLevel)
    }

    var mass: CGFloat {
        max(0.3, GameConfig.Plane.baseMass - CGFloat(fuselageLevel) * GameConfig.Upgrades.weightReductionPerLevel)
    }

    var magnetRadius: CGFloat {
        GameConfig.Coins.magnetRadius + CGFloat(wingsLevel) * GameConfig.Upgrades.magnetRadiusPerLevel
    }

    // MARK: - Upgrade Costs

    func upgradeCost(for type: UpgradeType) -> Int {
        let level = self.level(for: type)
        return GameConfig.Upgrades.cost(forLevel: level)
    }

    func level(for type: UpgradeType) -> Int {
        switch type {
        case .engine: return engineLevel
        case .wings: return wingsLevel
        case .fuselage: return fuselageLevel
        }
    }

    func canUpgrade(_ type: UpgradeType) -> Bool {
        level(for: type) < GameConfig.Upgrades.maxLevel
    }

    mutating func applyUpgrade(_ type: UpgradeType) {
        switch type {
        case .engine:
            guard engineLevel < GameConfig.Upgrades.maxLevel else { return }
            engineLevel += 1
        case .wings:
            guard wingsLevel < GameConfig.Upgrades.maxLevel else { return }
            wingsLevel += 1
        case .fuselage:
            guard fuselageLevel < GameConfig.Upgrades.maxLevel else { return }
            fuselageLevel += 1
        }
        stage = currentStage
    }

    // MARK: - Visual

    var bodySize: CGSize {
        switch currentStage {
        case .propeller:  return CGSize(width: 60, height: 24)
        case .turboProp:  return CGSize(width: 70, height: 28)
        case .jet:        return CGSize(width: 80, height: 30)
        case .rocket:     return CGSize(width: 90, height: 32)
        }
    }

    var wingSpan: CGFloat {
        switch currentStage {
        case .propeller:  return 50
        case .turboProp:  return 58
        case .jet:        return 64
        case .rocket:     return 56  // sleeker
        }
    }

    var bodyColorHex: String {
        switch currentStage {
        case .propeller:  return "#E74C3C"
        case .turboProp:  return "#3498DB"
        case .jet:        return "#2ECC71"
        case .rocket:     return "#F39C12"
        }
    }
}
