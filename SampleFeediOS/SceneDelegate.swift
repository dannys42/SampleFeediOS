//
//  SceneDelegate.swift
//  SampleFeediOS
//
//  Created by Danny Sung on 02/01/2020.
//  Copyright © 2020 Sung Heroes. All rights reserved.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate, UISplitViewControllerDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let window = window else { return }
                
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        guard let splitViewController = window.rootViewController as? UISplitViewController else { return }
        guard let navigationController = splitViewController.viewControllers.last as? UINavigationController else { return }
        navigationController.topViewController?.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
        navigationController.topViewController?.navigationItem.leftItemsSupplementBackButton = true
        splitViewController.delegate = self

        let masterNavigationController = splitViewController.viewControllers[0] as! UINavigationController
        let masterViewController = masterNavigationController.topViewController as! MasterViewController
        
        let viewContext = (UIApplication.shared.delegate as?
        AppDelegate)?.persistentContainer.viewContext
        masterViewController.managedObjectContext = viewContext
        
        // Make sure feed controller has the same parent
        FeedController.shared.parentManagedObjectContext = viewContext
        
        let loginViewController = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
        window.rootViewController = loginViewController
        
        loginViewController.didLogin = {
            DispatchQueue.main.async {
                window.transitionRootViewController(to: splitViewController)
            }
        }
        masterViewController.didLogout = {
            DispatchQueue.main.async {
                window.transitionRootViewController(to: loginViewController)
            }
        }
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.

        // Save changes in the application's managed object context when the application transitions to the background.
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }

    // MARK: - Split view

    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController:UIViewController, onto primaryViewController:UIViewController) -> Bool {
        guard let secondaryAsNavController = secondaryViewController as? UINavigationController else { return false }
        guard let topAsDetailController = secondaryAsNavController.topViewController as? DetailViewController else { return false }
        if topAsDetailController.detailItem == nil {
            // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
            return true
        }
        return false
    }

}

// MARK: - UIWindow transition helper
fileprivate extension UIWindow {
    func transitionRootViewController(to toVC: UIViewController, duration: TimeInterval = 0.25) {
        guard let fromVC = self.rootViewController else {
            self.rootViewController = toVC
            return
        }
        
        let fadeDuration = duration / 2
        // Fade between view controllers
        // Need to split up the fade because we cannot use UIView.transition(from:to:...) for the root window
        
        fromVC.view.alpha = 1.0
        UIView.transition(with: fromVC.view,
                          duration: fadeDuration,
                          options: .curveEaseOut,
                          animations: {
                            fromVC.view.alpha = 0.0
        }, completion: { _ in
            toVC.view.alpha = 0.0
            self.rootViewController = toVC

            UIView.transition(with: toVC.view,
                              duration: fadeDuration,
                              options: .curveEaseIn, animations: {
                                toVC.view.alpha = 1.0
            })
        })
    }
}
