import UIKit
import SwiftUI

enum RootSwitcher {
    static func toMain() {
        guard let window = keyWindow() else { return }
        let root = UIHostingController(rootView: MainContainerView())
        let nav = UINavigationController(rootViewController: root)
        setRoot(nav, for: window)
    }

    static func toAuth(_ api: APIClient) {
        guard let window = keyWindow() else { return }
        let auth = AuthViewController(api: api)
        let nav = UINavigationController(rootViewController: auth)
        setRoot(nav, for: window)
    }
    
    static func presentModally(_ vc: UIViewController, animated: Bool = true) {
            guard let window = keyWindow(),
                  let root = window.rootViewController else { return }

            let top = topMost(from: root)
            top.present(vc, animated: animated, completion: nil)
    }

    private static func topMost(from vc: UIViewController) -> UIViewController {
        if let nav = vc as? UINavigationController {
            return topMost(from: nav.visibleViewController ?? nav)
        }
        if let tab = vc as? UITabBarController {
            return topMost(from: tab.selectedViewController ?? tab)
        }
        if let presented = vc.presentedViewController {
            return topMost(from: presented)
        }
        return vc
    }

    // MARK: - helpers

    private static func keyWindow() -> UIWindow? {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
        return scenes.first?.windows.first { $0.isKeyWindow }
    }

    private static func setRoot(_ vc: UIViewController, for window: UIWindow) {
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
            window.rootViewController = vc
        })
        window.makeKeyAndVisible()
    }
}
