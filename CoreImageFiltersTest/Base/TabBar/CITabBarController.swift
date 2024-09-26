//
//  CITabBarController.swift
//  CoreImageTest
//
//  Created by Yuliya on 22/08/2024.
//

import UIKit

final class CITabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.backgroundColor = .clear
        tabBar.unselectedItemTintColor = .systemRed.withAlphaComponent(0.5)
        tabBar.tintColor = .systemRed
    }
}
