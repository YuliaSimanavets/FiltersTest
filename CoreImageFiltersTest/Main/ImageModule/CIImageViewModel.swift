//
//  CIImageViewModel.swift
//  CoreImageTest
//
//  Created by Yuliya on 22/08/2024.
//

import UIKit

final class CIImageViewModel {
    
    private let filterManager: CIFilterManager
    
    init(filterManager: CIFilterManager) {
        self.filterManager = filterManager
    }
    
    func applyFirstFilter(for inputImage: UIImageView) -> UIImage? {
        
        // здесь ничего не меняем
        var finalImage = UIImage()
        guard let image = inputImage.image else { return nil }
        guard let firstCIImage = CIImage(image: image) else { return nil }
        firstCIImage.cropped(to: inputImage.bounds)
        
        // здесь создаем фильтр
        // c помощью метода, созданного в filterManager
        
        // CICategoryBlur
        let bokehBlur = filterManager.getCIImageWithBokehBlur(inputImage: firstCIImage)
//        let boxBlur = filterManager.getCIImageWithBoxBlur(inputImage: firstCIImage, radius: 100)
        
        // Reduction Filters
        let kMeans = filterManager.getCIImageWithKMeansFilter(inputImage: firstCIImage)
        
        // Distortion Filters
//        let displacementDistortion = filterManager.displacementDistortion(inputImage: firstCIImage)
        
        
        // здесь ничего менять не нужно
        let ciContext = CIContext(options: nil)
        let srcScale = image.scale
        let srcOrientation = image.imageOrientation
        
        // здесь менять фильтры
        guard let filteredImageData = bokehBlur else { return nil }
        
        
        // здесь ничего не меняем
        let filteredImageRef = ciContext.createCGImage(filteredImageData, from: firstCIImage.extent)
        finalImage = UIImage(cgImage: filteredImageRef!, scale: srcScale, orientation: srcOrientation)
        return finalImage
    }
    
    func applySecondFilter(for inputImage: UIImageView) -> UIImage? {
        
        // здесь ничего не меняем
        var finalImage = UIImage()
        guard let secondImg = inputImage.image else { return nil }
        guard let secondCIImage = CIImage(image: secondImg) else { return nil }
        secondCIImage.cropped(to: inputImage.bounds)
        
        // здесь создаем фильтр
        // c помощью метода, созданного в filterManager
        
        
        let gaussianFilter = filterManager.getCIImageWithGaussianBlurFilter(inputImage: secondCIImage)
        let sepiaTone = filterManager.getCIImageWithSepiaToneFilter(inputImage: secondCIImage)
        
        
        // здесь ничего менять не нужно
        let ciContext = CIContext(options: nil)
        let srcScale = secondImg.scale
        let srcOrientation = secondImg.imageOrientation
        
        // здесть меняем филтр
        guard let filteredImageData = sepiaTone else { return nil }
        
        // здесь ничего не меняем
        let filteredImageRef = ciContext.createCGImage(filteredImageData, from: secondCIImage.extent)
        finalImage = UIImage(cgImage: filteredImageRef!, scale: srcScale, orientation: srcOrientation)
        return finalImage
    }
    
    func applyMask(with firstImage: UIImageView, and maskImage: UIImage) -> UIImage? {
        
        // здесь ничего не меняем
        var finalImage = UIImage()
        guard let firstImg = firstImage.image else { return nil }
        guard let firstCIImage = CIImage(image: firstImg) else { return nil }
        firstCIImage.cropped(to: firstImage.bounds)
        
        guard let maskCIImage = CIImage(image: maskImage) else { return nil }
        
        // здесь создаем фильтр
        // c помощью метода, созданного в файле filterManager
        
        //CICategoryBlur
        let maskVaribaleBlur = filterManager.getCIImageWithMaskedVariableBlur(inputImage: firstCIImage, inputMask: maskCIImage)
        
        
        // здесь ничего менять не нужно
        let ciContext = CIContext(options: nil)
        let srcScale = firstImg.scale
        let srcOrientation = firstImg.imageOrientation
        
        // здесь менять фильтры
        guard let filteredImageData = maskVaribaleBlur else { return nil }
        
        // здесь ничего не меняем
        let filteredImageRef = ciContext.createCGImage(filteredImageData, from: firstCIImage.extent)
        finalImage = UIImage(cgImage: filteredImageRef!, scale: srcScale, orientation: srcOrientation)
        return finalImage
    }
}
