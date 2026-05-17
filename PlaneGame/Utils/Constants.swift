import SpriteKit

// MARK: - Notification Names

extension Notification.Name {
    static let coinCollected = Notification.Name("coinCollected")
    static let planeCrashed = Notification.Name("planeCrashed")
    static let planeLanded = Notification.Name("planeLanded")
    static let distanceMilestone = Notification.Name("distanceMilestone")
    static let upgradeApplied = Notification.Name("upgradeApplied")
    static let powerUpCollected = Notification.Name("powerUpCollected")
    static let powerUpExpired = Notification.Name("powerUpExpired")
    static let environmentChanged = Notification.Name("environmentChanged")
    static let dailyChallengeCompleted = Notification.Name("dailyChallengeCompleted")
}

// MARK: - UserDefaults Keys

enum StorageKey {
    static let playerProgress = "playerProgress"
    static let bestDistance = "bestDistance"
    static let totalCoins = "totalCoins"
    static let totalFlights = "totalFlights"
    static let soundEnabled = "soundEnabled"
    static let hapticsEnabled = "hapticsEnabled"
    static let musicEnabled = "musicEnabled"
    static let lastDailyChallengeDate = "lastDailyChallengeDate"
    static let dailyChallengeCompleted = "dailyChallengeCompleted"
    static let selectedEnvironment = "selectedEnvironment"
    static let adsRemoved = "adsRemoved"
    static let isVIP = "isVIP"
    static let tutorialCompleted = "tutorialCompleted"
}

// MARK: - Game State

enum GameState {
    case menu
    case ready          // slingshot visible, waiting for pull
    case aiming         // player is pulling the slingshot
    case launched       // plane is in the air
    case flying         // sustained flight
    case landing        // touching down
    case crashed        // collided with obstacle or ground at speed
    case results        // showing results screen
    case paused
}

// MARK: - Power-up Types

enum PowerUpType: String, Codable, CaseIterable {
    case speedBoost
    case shield
    case coinMagnet

    var displayName: String {
        switch self {
        case .speedBoost: return "Speed Boost"
        case .shield: return "Shield"
        case .coinMagnet: return "Coin Magnet"
        }
    }

    var colorHex: String {
        switch self {
        case .speedBoost: return "#FF6B35"
        case .shield: return "#4ECDC4"
        case .coinMagnet: return "#FFE66D"
        }
    }
}

// MARK: - Upgrade Types

enum UpgradeType: String, Codable, CaseIterable {
    case engine
    case wings
    case fuselage

    var displayName: String {
        switch self {
        case .engine: return "Engine"
        case .wings: return "Wings"
        case .fuselage: return "Fuselage"
        }
    }

    var description: String {
        switch self {
        case .engine: return "Increases thrust power"
        case .wings: return "Improves lift and handling"
        case .fuselage: return "Reduces weight and drag"
        }
    }

    var iconName: String {
        switch self {
        case .engine: return "engine_icon"
        case .wings: return "wings_icon"
        case .fuselage: return "fuselage_icon"
        }
    }
}

// MARK: - Environment Type

enum EnvironmentType: String, Codable, CaseIterable {
    case countryside
    case mountains
    case city

    var displayName: String {
        switch self {
        case .countryside: return "Countryside"
        case .mountains: return "Mountains"
        case .city: return "City"
        }
    }

    var unlockDistance: CGFloat {
        switch self {
        case .countryside: return GameConfig.Environments.countrysideUnlockDistance
        case .mountains: return GameConfig.Environments.mountainsUnlockDistance
        case .city: return GameConfig.Environments.cityUnlockDistance
        }
    }

    var groundColorHex: String {
        switch self {
        case .countryside: return "#4CAF50"
        case .mountains: return "#8D6E63"
        case .city: return "#78909C"
        }
    }

    var skyColorTopHex: String {
        switch self {
        case .countryside: return "#87CEEB"
        case .mountains: return "#5C6BC0"
        case .city: return "#FF8A65"
        }
    }

    var skyColorBottomHex: String {
        switch self {
        case .countryside: return "#E0F7FA"
        case .mountains: return "#B3E5FC"
        case .city: return "#FFE0B2"
        }
    }
}

// MARK: - Plane Evolution Stage

enum PlaneStage: Int, Codable, CaseIterable {
    case propeller = 0
    case turboProp = 1
    case jet = 2
    case rocket = 3

    var displayName: String {
        switch self {
        case .propeller: return "Propeller"
        case .turboProp: return "Turbo Prop"
        case .jet: return "Jet"
        case .rocket: return "Rocket"
        }
    }

    /// Total upgrade levels needed to reach this stage
    var upgradeThreshold: Int {
        switch self {
        case .propeller: return 0
        case .turboProp: return 8
        case .jet: return 18
        case .rocket: return 27
        }
    }
}
