import Foundation
import CoreGraphics

// MARK: - GameConfig
// Central configuration for all tunable game values. NO magic numbers elsewhere.

enum GameConfig {

    // MARK: - Screen & World

    enum World {
        static let gravity: CGFloat = -4.8
        static let groundY: CGFloat = 100.0
        static let ceilingY: CGFloat = 2000.0
        static let despawnOffsetX: CGFloat = -200.0
        static let chunkWidth: CGFloat = 1024.0
    }

    // MARK: - Slingshot

    enum Slingshot {
        static let anchorOffset = CGPoint(x: 150, y: World.groundY + 80)
        static let maxPullDistance: CGFloat = 180.0
        static let minPullDistance: CGFloat = 20.0
        static let bandElasticity: CGFloat = 1.0
        static let minLaunchPower: CGFloat = 400.0
        static let maxLaunchPower: CGFloat = 1800.0
        static let minLaunchAngle: CGFloat = 15.0   // degrees
        static let maxLaunchAngle: CGFloat = 80.0    // degrees
        static let forkWidth: CGFloat = 40.0
        static let forkHeight: CGFloat = 120.0
        static let bandWidth: CGFloat = 6.0
    }

    // MARK: - Plane Physics

    enum Plane {
        static let baseMass: CGFloat = 1.0
        static let baseThrust: CGFloat = 320.0
        static let baseLift: CGFloat = 180.0
        static let baseDrag: CGFloat = 0.35
        static let maxSpeed: CGFloat = 1200.0
        static let minSpeedForLift: CGFloat = 60.0
        static let pitchSensitivity: CGFloat = 2.8
        static let maxPitchAngle: CGFloat = 75.0     // degrees
        static let minPitchAngle: CGFloat = -60.0     // degrees
        static let angularDamping: CGFloat = 0.92
        static let groundBounceRestitution: CGFloat = 0.3
        static let crashSpeedThreshold: CGFloat = 250.0
        static let smoothLandingAngle: CGFloat = 15.0 // degrees from horizontal
        static let smoothLandingSpeed: CGFloat = 150.0
        static let idleThrustDecay: CGFloat = 0.98
        static let stallAngle: CGFloat = 45.0         // degrees — beyond this, lift drops
    }

    // MARK: - Camera

    enum Camera {
        static let followSmoothing: CGFloat = 0.08
        static let leadAheadX: CGFloat = 250.0
        static let leadAheadY: CGFloat = 80.0
        static let minY: CGFloat = 0.0
        static let shakeIntensity: CGFloat = 12.0
        static let shakeDuration: TimeInterval = 0.4
    }

    // MARK: - Coins

    enum Coins {
        static let baseValue: Int = 1
        static let spawnInterval: CGFloat = 220.0     // points apart
        static let clusterSize: ClosedRange<Int> = 3...7
        static let clusterSpread: CGFloat = 60.0
        static let magnetRadius: CGFloat = 200.0
        static let magnetSpeed: CGFloat = 600.0
        static let collectRadius: CGFloat = 30.0
        static let floatAmplitude: CGFloat = 8.0
        static let floatFrequency: CGFloat = 2.0
        static let size: CGFloat = 24.0
        static let sparkleParticleCount: Int = 8
    }

    // MARK: - Obstacles

    enum Obstacles {
        static let firstSpawnDistance: CGFloat = 600.0
        static let minSpacing: CGFloat = 350.0
        static let maxSpacing: CGFloat = 700.0
        static let minY: CGFloat = World.groundY + 50
        static let maxY: CGFloat = 800.0
        static let birdSpeed: CGFloat = 120.0
        static let birdOscillation: CGFloat = 40.0
    }

    // MARK: - Upgrades

    enum Upgrades {
        static let maxLevel: Int = 10
        static let baseCost: Int = 50
        static let costMultiplier: CGFloat = 1.65

        static let thrustPerLevel: CGFloat = 35.0
        static let liftPerLevel: CGFloat = 22.0
        static let dragReductionPerLevel: CGFloat = 0.025
        static let weightReductionPerLevel: CGFloat = 0.06
        static let magnetRadiusPerLevel: CGFloat = 30.0

        static func cost(forLevel level: Int) -> Int {
            Int(CGFloat(baseCost) * pow(costMultiplier, CGFloat(level)))
        }
    }

    // MARK: - Environments

    enum Environments {
        static let countrysideUnlockDistance: CGFloat = 0
        static let mountainsUnlockDistance: CGFloat = 2000
        static let cityUnlockDistance: CGFloat = 5000
        static let parallaxLayerCount: Int = 4
        static let parallaxSpeedRatios: [CGFloat] = [0.1, 0.3, 0.6, 1.0]
    }

    // MARK: - Power-ups

    enum PowerUps {
        static let spawnChance: CGFloat = 0.12
        static let spawnMinDistance: CGFloat = 500.0
        static let boostDuration: TimeInterval = 3.0
        static let boostMultiplier: CGFloat = 2.0
        static let shieldDuration: TimeInterval = 5.0
        static let magnetDuration: TimeInterval = 6.0
        static let size: CGFloat = 36.0
    }

    // MARK: - Progression

    enum Progression {
        static let xpPerMeter: CGFloat = 0.5
        static let xpPerCoin: CGFloat = 2.0
        static let baseXPForLevel: CGFloat = 100.0
        static let xpLevelMultiplier: CGFloat = 1.4
        static let smoothLandingBonus: Int = 50

        static func xpRequired(forLevel level: Int) -> Int {
            Int(baseXPForLevel * pow(xpLevelMultiplier, CGFloat(level - 1)))
        }
    }

    // MARK: - Daily Challenges

    enum DailyChallenge {
        static let rewardCoins: Int = 200
        static let distanceTarget: CGFloat = 1500.0
        static let coinTarget: Int = 50
    }

    // MARK: - UI

    enum UI {
        static let animationDuration: TimeInterval = 0.3
        static let buttonScale: CGFloat = 1.08
        static let hudFontSize: CGFloat = 22.0
        static let titleFontSize: CGFloat = 48.0
        static let subtitleFontSize: CGFloat = 28.0
        static let bodyFontSize: CGFloat = 18.0
        static let fontName: String = "AvenirNext-Bold"
        static let fontNameRegular: String = "AvenirNext-Medium"
        static let hudPadding: CGFloat = 20.0
        static let primaryColor = "#4A90D9"
        static let secondaryColor = "#F5A623"
        static let accentColor = "#7ED321"
        static let dangerColor = "#D0021B"
        static let backgroundColor = "#1A1A2E"
    }

    // MARK: - Audio

    enum Audio {
        static let launchSound = "launch_whoosh"
        static let coinSound = "coin_ding"
        static let crashSound = "crash_boom"
        static let boostSound = "boost_whoosh"
        static let buttonSound = "button_tap"
        static let upgradeSound = "upgrade_chime"
        static let ambientWind = "ambient_wind"
        static let backgroundMusic = "bg_music"
    }

    // MARK: - Haptics

    enum Haptics {
        static let launchIntensity: Float = 0.8
        static let coinIntensity: Float = 0.3
        static let crashIntensity: Float = 1.0
        static let boostIntensity: Float = 0.6
    }

    // MARK: - IAP Product IDs

    enum IAP {
        static let removeAds = "com.planegame.removeads"
        static let gemsSmall = "com.planegame.gems.small"
        static let gemsMedium = "com.planegame.gems.medium"
        static let gemsLarge = "com.planegame.gems.large"
        static let vipPass = "com.planegame.vip"
    }

    // MARK: - Physics Categories

    enum PhysicsCategory {
        static let none: UInt32       = 0
        static let plane: UInt32      = 0b1
        static let ground: UInt32     = 0b10
        static let obstacle: UInt32   = 0b100
        static let coin: UInt32       = 0b1000
        static let powerUp: UInt32    = 0b10000
        static let boundary: UInt32   = 0b100000
    }

    // MARK: - Z Positions

    enum ZPosition {
        static let background: CGFloat = -100
        static let parallaxFar: CGFloat = -80
        static let parallaxMid: CGFloat = -60
        static let parallaxNear: CGFloat = -40
        static let ground: CGFloat = -20
        static let obstacles: CGFloat = 0
        static let coins: CGFloat = 5
        static let powerUps: CGFloat = 6
        static let plane: CGFloat = 10
        static let particles: CGFloat = 15
        static let slingshot: CGFloat = 8
        static let hud: CGFloat = 100
        static let overlay: CGFloat = 200
    }
}
