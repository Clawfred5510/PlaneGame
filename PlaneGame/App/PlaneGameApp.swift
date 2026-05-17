import SwiftUI

// MARK: - PlaneGameApp

@main
struct PlaneGameApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            GameContainerView()
                .ignoresSafeArea()
                .statusBarHidden(true)
                .persistentSystemOverlays(.hidden)
        }
    }
}

// MARK: - AppDelegate

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Initialize managers
        AdManager.shared.initialize()
        IAPManager.shared.startTransactionListener()

        Task {
            await IAPManager.shared.loadProducts()
        }

        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        IAPManager.shared.stopTransactionListener()
        GameManager.shared.progressionSystem.saveProgress()
    }
}

// MARK: - GameContainerView

struct GameContainerView: UIViewControllerRepresentable {

    func makeUIViewController(context: Context) -> GameViewController {
        GameViewController()
    }

    func updateUIViewController(_ uiViewController: GameViewController, context: Context) {}
}
