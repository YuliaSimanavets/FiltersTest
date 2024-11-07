//
//  CIImageCoordinator.swift
//  CoreImageTest
//
//  Created by Yuliya on 22/08/2024.
//

import UIKit

final class CIImageCoordinator {

    private let filterManager: CIFilterManager
    private let cutoutManager: CICutoutObjectManager
    
    init(filterManager: CIFilterManager, cutoutManager: CICutoutObjectManager) {
        self.filterManager = filterManager
        self.cutoutManager = cutoutManager
    }
}

// MARK: - TabBarCoordinator

extension CIImageCoordinator: CITabBarCoordinator {
    func start() {
    }

    func rootView() -> UIViewController {
        let viewModel = CIImageViewModel(filterManager: filterManager, cutoutManager: cutoutManager)
        let rootView = CIImageViewController(viewModel: viewModel)
        rootView.coordinator = self
        return rootView
    }
}
