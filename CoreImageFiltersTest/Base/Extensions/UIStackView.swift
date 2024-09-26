//
//  UIStackView.swift
//  CoreImageTest
//
//  Created by Yuliya on 23/08/2024.
//

import UIKit

extension UIStackView {
    public func addArrangedSubviews(_ subviews: UIView...) {
        addArrangedSubviews(subviews)
    }

    public func addArrangedSubviews(_ subviews: [UIView]) {
        subviews.forEach { addArrangedSubview($0) }
    }
}
