//
//  CICoordinatorFactory.swift
//  CoreImageTest
//
//  Created by Yuliya on 22/08/2024.
//

import Foundation

final class CICoordinatorFactory {
    let appContext: CIAppContext

    init(appContext: CIAppContext) {
        self.appContext = appContext
    }
}

// TabBar coordinators
extension CICoordinatorFactory {
    
    var ciImageCoordinator: CITabBarCoordinator {
        CIImageCoordinator(filterManager: appContext.filterManager, cutoutManager: appContext.cutoutManager)
    }

    var videoCoordinator: CITabBarCoordinator {
        CIVideoPlayerCoordinator(creationManager: appContext.creationManager)
    }
    
    func coordinator(for tabBarItem: CITabBarItem) -> CITabBarCoordinator {
        switch tabBarItem {
        case .ciImage:
            return ciImageCoordinator
            
        case .video:
            return videoCoordinator
        }
    }
}
