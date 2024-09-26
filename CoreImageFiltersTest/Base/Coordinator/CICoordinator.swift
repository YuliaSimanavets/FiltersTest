//
//  CICoordinator.swift
//  CoreImageTest
//
//  Created by Yuliya on 22/08/2024.
//

import UIKit

protocol CICoordinator: AnyObject {
    func start()
}

protocol CITabBarCoordinator: CICoordinator {
    func rootView() -> UIViewController
}
