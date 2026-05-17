import AVFoundation
import SpriteKit

// MARK: - AudioManager

final class AudioManager {

    // MARK: - Singleton

    static let shared = AudioManager()

    // MARK: - Properties

    private var soundEffects: [String: SKAction] = [:]
    private var bgMusicPlayer: AVAudioPlayer?
    private var isSoundEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: StorageKey.soundEnabled) }
        set { UserDefaults.standard.set(newValue, forKey: StorageKey.soundEnabled) }
    }
    private var isMusicEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: StorageKey.musicEnabled) }
        set { UserDefaults.standard.set(newValue, forKey: StorageKey.musicEnabled) }
    }

    // MARK: - Init

    private init() {
        // Default to enabled on first launch
        if UserDefaults.standard.object(forKey: StorageKey.soundEnabled) == nil {
            isSoundEnabled = true
        }
        if UserDefaults.standard.object(forKey: StorageKey.musicEnabled) == nil {
            isMusicEnabled = true
        }

        setupAudioSession()
        preloadSounds()
    }

    // MARK: - Setup

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("[AudioManager] Failed to set audio session: \(error)")
        }
    }

    private func preloadSounds() {
        // Pre-create SKActions for each sound name.
        // In production, these would load actual audio files.
        // For now, we create placeholder actions that do nothing if files are missing.
        let soundNames = [
            GameConfig.Audio.launchSound,
            GameConfig.Audio.coinSound,
            GameConfig.Audio.crashSound,
            GameConfig.Audio.boostSound,
            GameConfig.Audio.buttonSound,
            GameConfig.Audio.upgradeSound,
        ]

        for name in soundNames {
            if let _ = Bundle.main.url(forResource: name, withExtension: "wav") ??
                        Bundle.main.url(forResource: name, withExtension: "mp3") {
                soundEffects[name] = SKAction.playSoundFileNamed(name, waitForCompletion: false)
            } else {
                // Placeholder — no-op action when sound file doesn't exist
                soundEffects[name] = SKAction.wait(forDuration: 0)
            }
        }
    }

    // MARK: - Sound Effects

    func playSound(_ name: String) {
        guard isSoundEnabled else { return }
        guard let action = soundEffects[name] else { return }
        GameManager.shared.currentScene?.run(action)
    }

    // MARK: - Background Music

    func playBackgroundMusic() {
        guard isMusicEnabled else { return }

        guard let url = Bundle.main.url(forResource: GameConfig.Audio.backgroundMusic, withExtension: "mp3") ??
                         Bundle.main.url(forResource: GameConfig.Audio.backgroundMusic, withExtension: "wav") else {
            print("[AudioManager] Background music file not found")
            return
        }

        do {
            bgMusicPlayer = try AVAudioPlayer(contentsOf: url)
            bgMusicPlayer?.numberOfLoops = -1 // loop forever
            bgMusicPlayer?.volume = 0.3
            bgMusicPlayer?.play()
        } catch {
            print("[AudioManager] Failed to play background music: \(error)")
        }
    }

    func stopBackgroundMusic() {
        bgMusicPlayer?.stop()
        bgMusicPlayer = nil
    }

    func pauseBackgroundMusic() {
        bgMusicPlayer?.pause()
    }

    func resumeBackgroundMusic() {
        guard isMusicEnabled else { return }
        bgMusicPlayer?.play()
    }

    // MARK: - Toggle

    func toggleSound() -> Bool {
        isSoundEnabled.toggle()
        return isSoundEnabled
    }

    func toggleMusic() -> Bool {
        isMusicEnabled.toggle()
        if isMusicEnabled {
            playBackgroundMusic()
        } else {
            stopBackgroundMusic()
        }
        return isMusicEnabled
    }

    var soundOn: Bool { isSoundEnabled }
    var musicOn: Bool { isMusicEnabled }
}
