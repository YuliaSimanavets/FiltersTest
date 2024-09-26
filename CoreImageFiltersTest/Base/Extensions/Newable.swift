//
//  Newable.swift
//  CoreImageTest
//
//  Created by Yuliya on 23/08/2024.
//

import UIKit

protocol Newable {
    init()
}

extension NSObject: Newable {}

extension Newable where Self: NSObject {
    static func new(_ creatorFunc: (Self) -> Void) -> Self {
        let instance = self.init()
        creatorFunc(instance)
        return instance
    }
}

extension Newable where Self: UIView {
    static func new(_ creatorFunc: (Self) -> Void) -> Self {
        let instance = self.init()
        creatorFunc(instance)
        instance.translatesAutoresizingMaskIntoConstraints = false
        return instance
    }
}
