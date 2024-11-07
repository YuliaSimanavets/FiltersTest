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
        switch filterID {
        case .clones:
            // Clones filter
            preparedURL = try? await creationManager.applyClonesEffectToComp(assetURL: url)

        case .vhs:
            // VHS filter
            preparedURL = try? await creationManager.applyVHSEffectToComp(assetURL: url)
            
            // Curve filter
        case .curve:
            preparedURL = try? await creationManager.applyCurveToFullComp(assetLink: url)
         
            // ColorMatrix filter
        case .colorMatrix:
            preparedURL = try? await creationManager.applyColorMatrixToFullComp(assetLink: url)
            
            // ColorCorrection filter
        case .colorCorrection:
            preparedURL = try? await creationManager.applyColorFiltersToFullComp(assetLink: url)
        }
        
        return preparedURL
    }
}
