//
//  CIVideoPlayerCoordinator.swift
//  CoreImageTest
//
//  Created by Yuliya on 27/08/2024.
//

import UIKit

final class CIVideoPlayerCoordinator {
    
    private let creationManager: CICreationVideoManager
    
    init(creationManager: CICreationVideoManager) {
        self.creationManager = creationManager
    }
}

// MARK: - TabBarCoordinator

extension CIVideoPlayerCoordinator: CITabBarCoordinator {
    func start() {
    }

    func rootView() -> UIViewController {
        let viewModel = CIVideoPlayerViewModel(creationManager: creationManager)
        let rootView = CIVideoPlayerViewController(viewModel: viewModel)
        rootView.coordinator = self
        return rootView
    }
}
