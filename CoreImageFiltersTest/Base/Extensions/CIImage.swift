//
//  CIImage.swift
//  FiltersTest
//
//  Created by Yuliya on 19/09/2024.
//

import UIKit
import CoreImage

extension CIImage {
    func resize(to targetSize: CGSize) -> CIImage? {
        let scaleX = targetSize.width / self.extent.width
        let scaleY = targetSize.height / self.extent.height
        let transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
        return self.transformed(by: transform)
    }
}
