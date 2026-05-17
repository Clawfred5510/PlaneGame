import Foundation
import CoreGraphics

// MARK: - ProgressionSystem

final class ProgressionSystem {

    // MARK: - Properties

    private(set) var progress: PlayerProgress
    private(set) var currentFlightDistance: CGFloat = 0
    private(set) var currentFlightCoins: Int = 0
    private var flightStartX: CGFloat = 0
    private var isFlightActive = false

    // MARK: - Init

    init() {
        self.progress = PlayerProgress.load()
        progress.checkDailyChallenge()
    }

    // MARK: - Flight Tracking

    func startFlight(at startX: CGFloat) {
        flightStartX = startX
        currentFlightDistance = 0
        currentFlightCoins = 0
        isFlightActive = true
    }

    func updateDistance(currentX: CGFloat) {
        guard isFlightActive else { return }
        currentFlightDistance = max(0, currentX - flightStartX)
    }

    func addCoins(_ count: Int) {
        currentFlightCoins += count
    }

    // MARK: - End Flight

    func endFlight(smoothLanding: Bool) -> FlightResult {
        isFlightActive = false

        let isNewBest = currentFlightDistance > progress.bestDistance
        let bonusCoins = smoothLanding ? GameConfig.Progression.smoothLandingBonus : 0

        let xpEarned = currentFlightDistance * GameConfig.Progression.xpPerMeter
            + CGFloat(currentFlightCoins) * GameConfig.Progression.xpPerCoin

        let result = FlightResult(
            distance: currentFlightDistance,
            coinsCollected: currentFlightCoins,
            isNewBest: isNewBest,
            smoothLanding: smoothLanding,
            xpEarned: xpEarned,
            bonusCoins: bonusCoins
        )

        // Update progress
        progress.recordFlight(
            distance: currentFlightDistance,
            coinsCollected: currentFlightCoins + bonusCoins
        )

        // Check daily challenge
        checkDailyChallenge()

        progress.save()
        return result
    }

    // MARK: - Daily Challenge

    private func checkDailyChallenge() {
        guard !progress.dailyChallengeCompleted else { return }

        let distanceMet = currentFlightDistance >= GameConfig.DailyChallenge.distanceTarget
        let coinsMet = currentFlightCoins >= GameConfig.DailyChallenge.coinTarget

        if distanceMet || coinsMet {
            progress.completeDailyChallenge()
            NotificationCenter.default.post(name: .dailyChallengeCompleted, object: nil)
        }
    }

    var isDailyChallengeAvailable: Bool {
        !progress.dailyChallengeCompleted
    }

    var dailyChallengeProgress: (distance: CGFloat, coins: Int) {
        (currentFlightDistance, currentFlightCoins)
    }

    // MARK: - Environment

    func availableEnvironments() -> [EnvironmentModel] {
        EnvironmentModel.allEnvironments(bestDistance: progress.bestDistance)
    }

    func selectEnvironment(_ env: EnvironmentType) -> Bool {
        let result = progress.selectEnvironment(env)
        if result { progress.save() }
        return result
    }

    // MARK: - Persistence

    func reloadProgress() {
        progress = PlayerProgress.load()
    }

    func saveProgress() {
        progress.save()
    }

    // MARK: - Stats

    var totalFlights: Int { progress.totalFlights }
    var bestDistance: CGFloat { progress.bestDistance }
    var totalCoins: Int { progress.coins }
    var playerLevel: Int { progress.level }
    var currentXP: CGFloat { progress.xp }
    var xpForNextLevel: Int { progress.xpForNextLevel }
}
