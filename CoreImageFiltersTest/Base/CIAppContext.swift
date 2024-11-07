//
//  CIAppContext.swift
//  CoreImageTest
//
//  Created by Yuliya on 22/08/2024.
//

import Foundation

final class CIAppContext {
    let filterManager: CIFilterManager
    let creationManager: CICreationVideoManager
    let cutoutManager: CICutoutObjectManager
    
    init(filterManager: CIFilterManager, 
         creationManager: CICreationVideoManager,
         cutoutManager: CICutoutObjectManager) {
        self.filterManager = filterManager
        self.creationManager = creationManager
        self.cutoutManager = cutoutManager
    }
}
