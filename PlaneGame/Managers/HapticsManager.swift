import UIKit
import CoreHaptics

// MARK: - HapticsManager

final class HapticsManager {

    // MARK: - Singleton

    static let shared = HapticsManager()

    // MARK: - Properties

    private var engine: CHHapticEngine?
    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationGenerator = UINotificationFeedbackGenerator()

    private var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: StorageKey.hapticsEnabled) }
        set { UserDefaults.standard.set(newValue, forKey: StorageKey.hapticsEnabled) }
    }

    private var supportsHaptics: Bool {
        CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }

    // MARK: - Init

    private init() {
        if UserDefaults.standard.object(forKey: StorageKey.hapticsEnabled) == nil {
            isEnabled = true
        }
        setupEngine()
        prepareGenerators()
    }

    // MARK: - Setup

    private func setupEngine() {
        guard supportsHaptics else { return }

        do {
            engine = try CHHapticEngine()
            engine?.resetHandler = { [weak self] in
                do {
                    try self?.engine?.start()
                } catch {
                    print("[Haptics] Engine reset failed: \(error)")
                }
            }
            try engine?.start()
        } catch {
            print("[Haptics] Engine setup failed: \(error)")
        }
    }

    private func prepareGenerators() {
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()
        notificationGenerator.prepare()
    }

    // MARK: - Game Events

    func playLaunch() {
        guard isEnabled else { return }
        playCustomPattern(intensity: GameConfig.Haptics.launchIntensity, sharpness: 0.7)
    }

    func playCoinCollect() {
        guard isEnabled else { return }
        lightGenerator.impactOccurred(intensity: CGFloat(GameConfig.Haptics.coinIntensity))
    }

    func playCrash() {
        guard isEnabled else { return }
        playCustomPattern(intensity: GameConfig.Haptics.crashIntensity, sharpness: 1.0)
        heavyGenerator.impactOccurred()
    }

    func playBoost() {
        guard isEnabled else { return }
        mediumGenerator.impactOccurred(intensity: CGFloat(GameConfig.Haptics.boostIntensity))
    }

    func playUpgrade() {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(.success)
    }

    func playButtonTap() {
        guard isEnabled else { return }
        lightGenerator.impactOccurred(intensity: 0.5)
    }

    // MARK: - Custom Pattern

    private func playCustomPattern(intensity: Float, sharpness: Float) {
        guard supportsHaptics, let engine = engine else {
            heavyGenerator.impactOccurred()
            return
        }

        do {
            let event = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                ],
                relativeTime: 0,
                duration: 0.2
            )

            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("[Haptics] Custom pattern failed: \(error)")
        }
    }

    // MARK: - Toggle

    func toggle() -> Bool {
        isEnabled.toggle()
        return isEnabled
    }

    var hapticsOn: Bool { isEnabled }
}
