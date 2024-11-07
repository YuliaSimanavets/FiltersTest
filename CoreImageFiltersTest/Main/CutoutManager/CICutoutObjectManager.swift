//
//  CICutoutObjectManager.swift
//  CoreImageFiltersTest
//
//  Created by Yuliya on 07/11/2024.
//

import CoreImage
import Vision
import UIKit

class CICutoutObjectManager {
    
    private var visionModel: VNCoreMLModel?
    private let segmentationModel = DeepLabV3()
    
    private let filterManager: CIFilterManager

    init(filterManager: CIFilterManager) {
        self.filterManager = filterManager
        setupModel()
    }

    private func setupModel() {
        if let visionModel = try? VNCoreMLModel(for: segmentationModel.model) {
            self.visionModel = visionModel
        } else {
            fatalError("Could not load Vision model")
        }
    }

    // Метод для получения вырезанного объекта и фона
    func getCutoutObjects(inputImage: CIImage) -> (objectImage: CIImage?, backgroundWithoutObjectImage: CIImage?) {
        guard let visionModel = visionModel else {
            print("Vision model not initialized")
            return (nil, nil)
        }
        
        let request = VNCoreMLRequest(model: visionModel)
        request.imageCropAndScaleOption = .scaleFill

        let handler = VNImageRequestHandler(ciImage: inputImage, options: [:])
        
        let image = UIImage(ciImage: inputImage)
        let originalSize = image.size
        
        do {
            try handler.perform([request])
            guard let observations = request.results as? [VNCoreMLFeatureValueObservation],
                  let outputMultiArrayValue = observations.first?.featureValue.multiArrayValue,
                  let maskCGImage = outputMultiArrayValue.image(min: 0, max: 1)?.resized(to: originalSize).cgImage
            else {
                print("Failed to retrieve mask CGImage")
                return (nil, nil)
            }
            
            return processImages(originalCIImage: inputImage, maskCGImage: maskCGImage)
            
        } catch {
            print("Error performing request: \(error)")
            return (nil, nil)
        }
    }

    // Метод обработки изображения и создания объекта и фона
    private func processImages(originalCIImage: CIImage, maskCGImage: CGImage) -> (CIImage?, CIImage?) {
        
        // Создание маски
        let maskCIImage = CIImage(cgImage: maskCGImage)
        guard let maskAlphaImage = filterManager.getCIImageMaskToAlpha(maskImage: maskCIImage)
        else {
            print("Mask filter not completed")
            return (nil, nil)
        }

        // Извлекаем объект
        guard let objectCIImage = filterManager.getCIImageSourceInCompositing(inputImage: originalCIImage,
                                                                              maskAlphaImage: maskAlphaImage)
        else {
            print("No result from sourceInCompose")
            return (nil, nil)
        }
       
        // Извлекаем фон без объекта
        guard let backgroundWithoutObjectCIImage = filterManager.getCIImageSourceOutCompositing(inputImage: originalCIImage,
                                                                                                maskAlphaImage: maskAlphaImage)
        else {
            print("No result from sourceOutCompose")
            return (nil, nil)
        }
        
        return (objectCIImage, backgroundWithoutObjectCIImage)
    }
    
    /*
    //  Метод обработки изображения и создания объекта и фона (черная дырка)
    private func processImages(originalCIImage: CIImage, maskCGImage: CGImage) -> (CIImage?, CIImage?) {
        
        // Создание маски альфа-канала из маски
        let maskCIImage = CIImage(cgImage: maskCGImage)
        guard let maskAlphaImage = filterManager.getCIImageMaskToAlpha(maskImage: maskCIImage) else {
            print("Mask filter not completed")
            return (nil, nil)
        }

        // Извлекаем объект (оставляем только объект, используя маску)
        guard let objectCIImage = filterManager.getCIImageSourceInCompositing(inputImage: originalCIImage,
                                                                              maskAlphaImage: maskAlphaImage) else {
            print("No result from sourceInCompose")
            return (nil, nil)
        }
       
        // Создание чёрного цвета
        let blackColorImage = CIImage(color: .black).cropped(to: originalCIImage.extent)

        // Используем маску, чтобы сделать дыры чёрными на фоне
        let maskedBlackBackground = blackColorImage
            .applyingFilter("CISourceInCompositing", parameters: ["inputBackgroundImage": maskAlphaImage])

        // Накладываем чёрный фон с маской на исходное изображение, чтобы убрать объект
        let backgroundWithoutObjectCIImage = originalCIImage
            .applyingFilter("CISourceOutCompositing", parameters: ["inputBackgroundImage": maskAlphaImage])
            .applyingFilter("CISourceOverCompositing", parameters: ["inputBackgroundImage": maskedBlackBackground])
        
        return (objectCIImage, backgroundWithoutObjectCIImage)
    }
     */
}

