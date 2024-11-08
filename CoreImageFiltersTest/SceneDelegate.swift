//
//  SceneDelegate.swift
//  CoreImageFiltersTest
//
//  Created by Yuliya on 26/09/2024.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var appCoordinator: CICoordinator?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
    
        let window = UIWindow(windowScene: windowScene)
        window.backgroundColor = .white
        
        let filterManager = CIFilterManager()
        let cutoutManager = CICutoutObjectManager(filterManager: filterManager)
        let creationManager = CICreationVideoManager(filterManager: filterManager, cutoutManager: cutoutManager)

        let coordinatorFactory = CICoordinatorFactory(appContext: CIAppContext(filterManager: filterManager,
                                                                               creationManager: creationManager,
                                                                               cutoutManager: cutoutManager))
        appCoordinator = CIAppCoordinator(window: window,
                                          coordinatorFactory: coordinatorFactory)
        appCoordinator?.start()

        self.window = window
        window.makeKeyAndVisible()
    }
}

