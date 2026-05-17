import Foundation
import CoreGraphics
import SpriteKit

// MARK: - EnvironmentModel

struct EnvironmentModel: Codable {
    let type: EnvironmentType
    let isUnlocked: Bool

    var groundColor: String { type.groundColorHex }
    var skyColorTop: String { type.skyColorTopHex }
    var skyColorBottom: String { type.skyColorBottomHex }
    var unlockDistance: CGFloat { type.unlockDistance }

    // MARK: - Obstacle Configuration

    var obstacleTypes: [ObstacleKind] {
        switch type {
        case .countryside:
            return [.tree, .barn, .bird, .windmill]
        case .mountains:
            return [.peak, .bird, .cloud, .pine]
        case .city:
            return [.building, .crane, .bird, .antenna]
        }
    }

    var parallaxLayers: [ParallaxLayerConfig] {
        switch type {
        case .countryside:
            return [
                ParallaxLayerConfig(colorHex: "#87CEEB", speedRatio: 0.1, yOffset: 0, height: 1.0),
                ParallaxLayerConfig(colorHex: "#90CAF9", speedRatio: 0.3, yOffset: 0.2, height: 0.5),
                ParallaxLayerConfig(colorHex: "#66BB6A", speedRatio: 0.6, yOffset: 0.0, height: 0.25),
                ParallaxLayerConfig(colorHex: "#4CAF50", speedRatio: 1.0, yOffset: 0.0, height: 0.15),
            ]
        case .mountains:
            return [
                ParallaxLayerConfig(colorHex: "#5C6BC0", speedRatio: 0.1, yOffset: 0, height: 1.0),
                ParallaxLayerConfig(colorHex: "#7986CB", speedRatio: 0.25, yOffset: 0.3, height: 0.5),
                ParallaxLayerConfig(colorHex: "#9FA8DA", speedRatio: 0.5, yOffset: 0.15, height: 0.4),
                ParallaxLayerConfig(colorHex: "#8D6E63", speedRatio: 1.0, yOffset: 0.0, height: 0.15),
            ]
        case .city:
            return [
                ParallaxLayerConfig(colorHex: "#FF8A65", speedRatio: 0.1, yOffset: 0, height: 1.0),
                ParallaxLayerConfig(colorHex: "#FFAB91", speedRatio: 0.3, yOffset: 0.25, height: 0.5),
                ParallaxLayerConfig(colorHex: "#90A4AE", speedRatio: 0.6, yOffset: 0.1, height: 0.35),
                ParallaxLayerConfig(colorHex: "#78909C", speedRatio: 1.0, yOffset: 0.0, height: 0.15),
            ]
        }
    }

    // MARK: - Factory

    static func allEnvironments(bestDistance: CGFloat) -> [EnvironmentModel] {
        EnvironmentType.allCases.map { type in
            EnvironmentModel(
                type: type,
                isUnlocked: bestDistance >= type.unlockDistance
            )
        }
    }
}

// MARK: - ParallaxLayerConfig

struct ParallaxLayerConfig: Codable {
    let colorHex: String
    let speedRatio: CGFloat
    let yOffset: CGFloat    // fraction of screen height
    let height: CGFloat     // fraction of screen height
}

// MARK: - ObstacleKind

enum ObstacleKind: String, Codable, CaseIterable {
    case tree
    case barn
    case bird
    case windmill
    case peak
    case cloud
    case pine
    case building
    case crane
    case antenna

    var size: CGSize {
        switch self {
        case .tree:     return CGSize(width: 40, height: 80)
        case .barn:     return CGSize(width: 80, height: 60)
        case .bird:     return CGSize(width: 30, height: 20)
        case .windmill: return CGSize(width: 30, height: 100)
        case .peak:     return CGSize(width: 120, height: 200)
        case .cloud:    return CGSize(width: 100, height: 40)
        case .pine:     return CGSize(width: 35, height: 90)
        case .building: return CGSize(width: 70, height: 160)
        case .crane:    return CGSize(width: 40, height: 140)
        case .antenna:  return CGSize(width: 15, height: 120)
        }
    }

    var colorHex: String {
        switch self {
        case .tree:     return "#2E7D32"
        case .barn:     return "#8D6E63"
        case .bird:     return "#37474F"
        case .windmill: return "#BDBDBD"
        case .peak:     return "#5D4037"
        case .cloud:    return "#ECEFF1"
        case .pine:     return "#1B5E20"
        case .building: return "#546E7A"
        case .crane:    return "#FF8F00"
        case .antenna:  return "#B0BEC5"
        }
    }

    var isFlying: Bool {
        self == .bird || self == .cloud
    }

    var isDestructible: Bool {
        self == .cloud
    }

    var damageOnHit: CGFloat {
        switch self {
        case .cloud: return 0
        case .bird: return 0.3
        default: return 1.0
        }
    }
}
