//
//  CIImageViewModel.swift
//  CoreImageTest
//
//  Created by Yuliya on 22/08/2024.
//

import UIKit

final class CIImageViewModel {
    
    private let filterManager: CIFilterManager
    private let cutoutManager: CICutoutObjectManager
    
    init(filterManager: CIFilterManager, cutoutManager: CICutoutObjectManager) {
        self.filterManager = filterManager
        self.cutoutManager = cutoutManager
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
        
        
        // Curve filter
//        let points = CurvePoints(photoshopPoint0: .init(x: 0.06, y: 0),
//                                 photoshopPoint1: .init(x: 0.234, y: 0.26),
//                                 photoshopPoint2: .init(x: 0.48, y: 0.53),
//                                 photoshopPoint3: .init(x: 0.75, y: 0.7),
//                                 photoshopPoint4: .init(x: 1, y: 0.78))
        // change X / Y - получилось (оси в Ае и xCode меняются местами)
        let points = CurvePoints(photoshopPoint0: .init(x: 0, y: 0.06),
                                 photoshopPoint1: .init(x: 0.26, y: 0.234),
                                 photoshopPoint2: .init(x: 0.53, y: 0.48),
                                 photoshopPoint3: .init(x: 0.7, y: 0.75),
                                 photoshopPoint4: .init(x: 0.78, y: 1))
        
        let curveFilter = filterManager.getCIImageWithToneCurveFilter(inputImage: firstCIImage, points: points)
        
        // здесь ничего менять не нужно
        let ciContext = CIContext(options: nil)
        let srcScale = image.scale
        let srcOrientation = image.imageOrientation
        
        // здесь менять фильтры
        guard let filteredImageData = curveFilter else { return nil }
        
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
    
    func applyDisplacementDistortionMask(for inputImage: UIImageView, displacementImage: UIImage, scale: Double) -> UIImage? {
       
        var finalImage = UIImage()
        guard let image = inputImage.image,
              let firstCIImage = CIImage(image: image)
        else { return nil }
        firstCIImage.cropped(to: inputImage.bounds)
        
        guard let displCIImage = CIImage(image: displacementImage)
        else { return nil }
        displCIImage.cropped(to: inputImage.bounds)
        
        // здесь ничего менять не нужно
        let ciContext = CIContext(options: nil)
        let srcScale = image.scale
        let srcOrientation = image.imageOrientation
        
        let displacementDistortion = filterManager.getCIImageWithDisplacementDistortionFilter(inputImage: firstCIImage,
                                                                                              displacementImage: displCIImage,
                                                                                              scale: scale)
        
        // здесь менять фильтры
        guard let filteredImageData = displacementDistortion else { return nil }
        
        // здесь ничего не меняем
        let filteredImageRef = ciContext.createCGImage(filteredImageData, from: firstCIImage.extent)
        finalImage = UIImage(cgImage: filteredImageRef!, scale: srcScale, orientation: srcOrientation)
        return finalImage
    }
    
    func applyCutout(for inputImage: UIImageView) -> UIImage? {
        
        var finalImage = UIImage()
        guard let image = inputImage.image else { return nil }
        guard let ciImage = CIImage(image: image) else { return nil }
        ciImage.cropped(to: inputImage.bounds)
        
        let ciContext = CIContext(options: nil)
        let srcScale = image.scale
        let srcOrientation = image.imageOrientation
        
        let cutoutObjects = cutoutManager.getCutoutObjects(inputImage: ciImage)
        guard let cutoutObject = cutoutObjects.objectImage
//              let cutoutBackground = cutoutObjects.backgroundWithoutObjectImage
        else { return nil }

        // здесь ничего не меняем
        let filteredImageRef = ciContext.createCGImage(cutoutObject, from: ciImage.extent)
        finalImage = UIImage(cgImage: filteredImageRef!, scale: srcScale, orientation: srcOrientation)
        return finalImage
    }
}
