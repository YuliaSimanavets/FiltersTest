//
//  CIAppCoordinator.swift
//  CoreImageTest
//
//  Created by Yuliya on 22/08/2024.
//

import Combine
import UIKit

final class CIAppCoordinator {
    private let window: UIWindow
    private let tabBarController = CITabBarController()

    private lazy var coordinatorTypes = [CITabBarItem: CITabBarCoordinator]()
    private let coordinatorFactory: CICoordinatorFactory

    private var cancellable = Set<AnyCancellable>()

    init(window: UIWindow,
         coordinatorFactory: CICoordinatorFactory) {
        self.window = window
        self.coordinatorFactory = coordinatorFactory
    }
}

extension CIAppCoordinator: CICoordinator {
    func start() {
        showMainApp()
    }
}

// MARK: - TabBar

private extension CIAppCoordinator {
    func showMainApp() {
        setupTabBar()
        window.rootViewController = tabBarController
    }

    func setupTabBar() {
        var navControllers = [UINavigationController]()
        CITabBarItem.allCases.forEach { item in
            let coordinator = coordinatorFactory.coordinator(for: item)
            coordinatorTypes[item] = coordinator

            let viewController = coordinator.rootView()
            viewController.tabBarItem = item.tabBarItem
            let navigationController = UINavigationController(rootViewController: viewController)
            navControllers.append(navigationController)

            coordinator.start()
        }

        tabBarController.viewControllers = navControllers
    }
}

