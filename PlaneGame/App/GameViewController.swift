import UIKit
import SpriteKit

// MARK: - GameViewController

final class GameViewController: UIViewController {

    // MARK: - Properties

    private var skView: SKView!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        skView = SKView(frame: view.bounds)
        skView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(skView)

        // Debug info (disable for release)
        #if DEBUG
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.showsPhysics = false
        #endif

        skView.ignoresSiblingOrder = true

        // Configure GameManager with the screen size
        let sceneSize = CGSize(width: 414, height: 896) // iPhone 11 Pro reference size
        GameManager.shared.configureSceneSize(sceneSize)

        // Present the menu scene
        let menuScene = GameManager.shared.createMenuScene()
        skView.presentScene(menuScene)
    }

    // MARK: - View Overrides

    override var prefersStatusBarHidden: Bool { true }
    override var prefersHomeIndicatorAutoHidden: Bool { true }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }

    override var shouldAutorotate: Bool { true }

    // MARK: - Memory

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Flush caches if needed
        print("[GameViewController] Memory warning received")
    }
}
