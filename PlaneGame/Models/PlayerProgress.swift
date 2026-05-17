import Foundation
import CoreGraphics

// MARK: - PlayerProgress

struct PlayerProgress: Codable {
    var coins: Int = 0
    var gems: Int = 0
    var plane: PlaneModel = PlaneModel()
    var bestDistance: CGFloat = 0
    var totalDistance: CGFloat = 0
    var totalFlights: Int = 0
    var totalCoinsCollected: Int = 0
    var level: Int = 1
    var xp: CGFloat = 0
    var selectedEnvironment: EnvironmentType = .countryside
    var unlockedEnvironments: [EnvironmentType] = [.countryside]
    var adsRemoved: Bool = false
    var isVIP: Bool = false
    var tutorialCompleted: Bool = false
    var dailyChallengeDate: Date?
    var dailyChallengeCompleted: Bool = false
    var soundEnabled: Bool = true
    var musicEnabled: Bool = true
    var hapticsEnabled: Bool = true

    // MARK: - XP / Level

    var xpForNextLevel: Int {
        GameConfig.Progression.xpRequired(forLevel: level)
    }

    var xpProgress: CGFloat {
        CGFloat(xp) / CGFloat(xpForNextLevel)
    }

    mutating func addXP(_ amount: CGFloat) {
        xp += amount
        while xp >= CGFloat(xpForNextLevel) {
            xp -= CGFloat(xpForNextLevel)
            level += 1
        }
    }

    // MARK: - Coins

    mutating func addCoins(_ amount: Int) {
        coins += amount
        totalCoinsCollected += amount
    }

    mutating func spendCoins(_ amount: Int) -> Bool {
        guard coins >= amount else { return false }
        coins -= amount
        return true
    }

    // MARK: - Upgrades

    mutating func purchaseUpgrade(_ type: UpgradeType) -> UpgradeResult? {
        let cost = plane.upgradeCost(for: type)
        guard plane.canUpgrade(type), spendCoins(cost) else { return nil }

        let previousStage = plane.currentStage
        plane.applyUpgrade(type)
        let newStage = plane.currentStage

        return UpgradeResult(
            type: type,
            newLevel: plane.level(for: type),
            coinsSpent: cost,
            newStage: newStage != previousStage ? newStage : nil
        )
    }

    // MARK: - Flight Recording

    mutating func recordFlight(distance: CGFloat, coinsCollected: Int) {
        totalFlights += 1
        totalDistance += distance

        if distance > bestDistance {
            bestDistance = distance
            checkEnvironmentUnlocks()
        }

        addCoins(coinsCollected)

        let xpGain = distance * GameConfig.Progression.xpPerMeter
            + CGFloat(coinsCollected) * GameConfig.Progression.xpPerCoin
        addXP(xpGain)
    }

    // MARK: - Environments

    private mutating func checkEnvironmentUnlocks() {
        for env in EnvironmentType.allCases {
            if bestDistance >= env.unlockDistance && !unlockedEnvironments.contains(env) {
                unlockedEnvironments.append(env)
            }
        }
    }

    mutating func selectEnvironment(_ env: EnvironmentType) -> Bool {
        guard unlockedEnvironments.contains(env) else { return false }
        selectedEnvironment = env
        return true
    }

    // MARK: - Daily Challenge

    mutating func checkDailyChallenge() {
        let today = Date().startOfDay
        if let lastDate = dailyChallengeDate, lastDate == today {
            return // already checked today
        }
        dailyChallengeDate = today
        dailyChallengeCompleted = false
    }

    mutating func completeDailyChallenge() {
        guard !dailyChallengeCompleted else { return }
        dailyChallengeCompleted = true
        addCoins(GameConfig.DailyChallenge.rewardCoins)
    }

    // MARK: - Persistence

    static func load() -> PlayerProgress {
        guard let data = UserDefaults.standard.data(forKey: StorageKey.playerProgress),
              let progress = try? JSONDecoder().decode(PlayerProgress.self, from: data) else {
            return PlayerProgress()
        }
        return progress
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: StorageKey.playerProgress)
        }
    }
}

// MARK: - FlightResult

struct FlightResult {
    let distance: CGFloat
    let coinsCollected: Int
    let isNewBest: Bool
    let smoothLanding: Bool
    let xpEarned: CGFloat
    let bonusCoins: Int

    var totalCoins: Int {
        coinsCollected + bonusCoins
    }
}
