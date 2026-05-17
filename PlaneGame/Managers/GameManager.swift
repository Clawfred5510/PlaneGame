import SpriteKit

// MARK: - GameManager

final class GameManager {

    // MARK: - Singleton

    static let shared = GameManager()

    // MARK: - Properties

    private(set) var state: GameState = .menu
    private(set) var progressionSystem: ProgressionSystem
    private(set) var upgradeSystem: UpgradeSystem

    var progress: PlayerProgress { progressionSystem.progress }

    // Scene management
    weak var currentScene: SKScene?
    private var sceneSize: CGSize = .zero

    // MARK: - Init

    private init() {
        progressionSystem = ProgressionSystem()
        upgradeSystem = UpgradeSystem(progress: progressionSystem.progress)
    }

    // MARK: - State Management

    func setState(_ newState: GameState) {
        let oldState = state
        state = newState
        onStateChange(from: oldState, to: newState)
    }

    private func onStateChange(from oldState: GameState, to newState: GameState) {
        switch newState {
        case .crashed:
            HapticsManager.shared.playCrash()
            AudioManager.shared.playSound(GameConfig.Audio.crashSound)
        case .launched:
            HapticsManager.shared.playLaunch()
            AudioManager.shared.playSound(GameConfig.Audio.launchSound)
        default:
            break
        }
    }

    // MARK: - Scene Navigation

    func configureSceneSize(_ size: CGSize) {
        sceneSize = size
    }

    func createMenuScene() -> MenuScene {
        let scene = MenuScene(size: sceneSize)
        scene.scaleMode = .aspectFill
        return scene
    }

    func createGameScene() -> GameScene {
        let scene = GameScene(size: sceneSize)
        scene.scaleMode = .aspectFill
        return scene
    }

    func createUpgradeScene() -> UpgradeScene {
        let scene = UpgradeScene(size: sceneSize)
        scene.scaleMode = .aspectFill
        return scene
    }

    func presentScene(_ scene: SKScene, in view: SKView) {
        let transition = SKTransition.fade(withDuration: 0.4)
        view.presentScene(scene, transition: transition)
        currentScene = scene
    }

    // MARK: - Game Flow

    func startGame(in view: SKView) {
        let gameScene = createGameScene()
        presentScene(gameScene, in: view)
        setState(.ready)
    }

    func returnToMenu(in view: SKView) {
        let menuScene = createMenuScene()
        presentScene(menuScene, in: view)
        setState(.menu)
    }

    func openUpgrades(in view: SKView) {
        let upgradeScene = createUpgradeScene()
        presentScene(upgradeScene, in: view)
    }

    func restartGame(in view: SKView) {
        refreshSystems()
        startGame(in: view)
    }

    // MARK: - Upgrade Purchase

    func purchaseUpgrade(_ type: UpgradeType) -> UpgradeResult? {
        let result = upgradeSystem.purchaseUpgrade(type)
        if result != nil {
            // Sync progression system with updated progress
            progressionSystem.reloadProgress()
        }
        return result
    }

    // MARK: - Systems Refresh

    func refreshSystems() {
        progressionSystem.reloadProgress()
        upgradeSystem.updateProgress(progressionSystem.progress)
    }

    // MARK: - Flight End

    func endFlight(smoothLanding: Bool) -> FlightResult {
        let result = progressionSystem.endFlight(smoothLanding: smoothLanding)
        upgradeSystem.updateProgress(progressionSystem.progress)
        return result
    }
}
