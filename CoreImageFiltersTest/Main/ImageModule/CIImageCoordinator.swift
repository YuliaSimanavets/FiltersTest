//
//  CIImageCoordinator.swift
//  CoreImageTest
//
//  Created by Yuliya on 22/08/2024.
//

import UIKit

final class CIImageCoordinator {

    private let filterManager: CIFilterManager
    
    init(filterManager: CIFilterManager) {
        self.filterManager = filterManager
    }
}

// MARK: - TabBarCoordinator

extension CIImageCoordinator: CITabBarCoordinator {
    func start() {
    }

    func rootView() -> UIViewController {
        let viewModel = CIImageViewModel(filterManager: filterManager)
        let rootView = CIImageViewController(viewModel: viewModel)
        rootView.coordinator = self
        return rootView
    }
}
