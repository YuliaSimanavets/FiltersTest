//
//  CITabBarItem.swift
//  CoreImageTest
//
//  Created by Yuliya on 22/08/2024.
//

import UIKit

enum CITabBarItem: Int, CaseIterable {
    case video
    case ciImage
}

extension CITabBarItem {
    var index: Int { rawValue }

    var tabBarItem: UITabBarItem {
        switch self {
        case .video:
            return UITabBarItem(title: "Video",
                                image: UIImage(systemName: "video"),
                                tag: index)
            
        case .ciImage:
            return UITabBarItem(title: "Image",
                                image: UIImage(systemName: "photo.on.rectangle.angled"),
                                tag: index)

        }
    }
}
