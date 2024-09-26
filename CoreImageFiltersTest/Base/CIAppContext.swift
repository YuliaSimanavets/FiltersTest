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
    
    init(filterManager: CIFilterManager, 
         creationManager: CICreationVideoManager) {
        self.filterManager = filterManager
        self.creationManager = creationManager
    }
}
