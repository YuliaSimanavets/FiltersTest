//
//  CIVideoPlayerViewModel.swift
//  CoreImageTest
//
//  Created by Yuliya on 27/08/2024.
//

import Foundation
import PhotosUI

final class CIVideoPlayerViewModel {
    
    private let creationManager: CICreationVideoManager
    
    private var preparedURL: URL? = nil
    
    init(creationManager: CICreationVideoManager) {
        self.creationManager = creationManager
    }
    
    func getAllFilters() -> [FilterCollectionViewModel] {
        FilterName.allCases.map { FilterCollectionViewModel(filterName: $0)}
    }
    
    func preparedVideo(by url: URL, filterID: FilterName) async -> URL? {
        // apply filter (добавление фильтра на всю композицию)
        //        preparedURL = try? await creationManager.addFilterToFullComp(assetLink: url)
        
        
        switch filterID {
//        case .clones:
            // Clones filter
//        preparedURL = try? await creationManager.applyClonesEffectToComp(assetURL: url)

        case .vhs:
            // VHS filter
            preparedURL = try? await creationManager.applyVHSEffectToComp(assetURL: url)
            
        case .curve:
            preparedURL = try? await creationManager.applyCurveToFullComp(assetLink: url)
         
        case .colorMatrix:
            preparedURL = try? await creationManager.applyColorMatrixToFullComp(assetLink: url)
        }
        
        return preparedURL
    }
}
