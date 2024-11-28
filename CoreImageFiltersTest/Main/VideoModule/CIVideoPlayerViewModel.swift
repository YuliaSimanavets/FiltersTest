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
            // Clones filter
        case .clones:
            preparedURL = try? await creationManager.applyClonesEffectToComp(assetURL: url)
            
            // Clones + Overlays filter
        case .clonesOverlay:
            preparedURL = try? await creationManager.applyClonesEffectWithOverlaysToComp(assetURL: url)
            
            // Cut filter
        case .cut:
            preparedURL = try? await creationManager.applyCutEffectToComp(assetURL: url)

            // VHS filter
        case .vhs:
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
