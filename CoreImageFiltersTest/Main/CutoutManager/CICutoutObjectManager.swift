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
    private let filterManager: CIFilterManager
    
    init(filterManager: CIFilterManager) {
        self.filterManager = filterManager
        setupModel()
    }
    
    private func setupModel() {
        if let visionModel = try? VNCoreMLModel(for: DeepLabV3(configuration: .init()).model) {
            self.visionModel = visionModel
        } else {
            fatalError("Could not load Vision model")
        }
    }
    
    // Получение вырезанного объекта, фона и контура
    func getCutoutObjects(inputImage: CIImage) -> (objectImage: CIImage?, backgroundWithoutObjectImage: CIImage?) {
        guard let visionModel = visionModel else {
            print("Vision model not initialized")
            return (nil, nil)
        }

        let request = VNCoreMLRequest(model: visionModel)
        request.imageCropAndScaleOption = .scaleFill
        let handler = VNImageRequestHandler(ciImage: inputImage, options: [:])
        
        let originalSize = UIImage(ciImage: inputImage).size

        do {
            try handler.perform([request])

            guard let observations = request.results as? [VNCoreMLFeatureValueObservation],
                  let outputMultiArrayValue = observations.first?.featureValue.multiArrayValue,
                  let maskCGImage = outputMultiArrayValue.image(min: 0, max: 1)?.resized(to: originalSize).cgImage else {
                print("Failed to retrieve mask CGImage")
                return (nil, nil)
            }
            
            // get image with contour
            guard let contourCIImage = generateContourImage(maskCGImage: maskCGImage,
                                                            originalSize: originalSize,
                                                            baseImage: UIImage(ciImage: inputImage)) else {
                print("Failed to generate contour image")
                return (nil, nil)
            }
            
            // get cutoutObject and background
            let (objectImage, backgroundWithoutObjectImage) = processImages(
                originalCIImage: inputImage,
                maskCGImage: maskCGImage
            )
            
            return (objectImage, backgroundWithoutObjectImage)

        } catch {
            print("Error performing Vision request: \(error)")
            return (nil, nil)
        }
    }

    // Обработка изображения и создание объекта и фона
    private func processImages(originalCIImage: CIImage, maskCGImage: CGImage) -> (CIImage?, CIImage?) {
        
        // Создание маски
        let maskCIImage = CIImage(cgImage: maskCGImage)
        guard let maskAlphaImage = filterManager.getCIImageMaskToAlpha(maskImage: maskCIImage) else {
            print("Mask filter not completed")
            return (nil, nil)
        }
        
        // Извлекаем объект
        guard let objectCIImage = filterManager.getCIImageSourceInCompositing(inputImage: originalCIImage,
                                                                              maskAlphaImage: maskAlphaImage) else {
            print("No result from sourceInCompose")
            return (nil, nil)
        }
        
        // Извлекаем фон без объекта
        guard let backgroundWithoutObjectCIImage = filterManager.getCIImageSourceOutCompositing(inputImage: originalCIImage,
                                                                                                maskAlphaImage: maskAlphaImage) else {
            print("No result from sourceOutCompose")
            return (nil, nil)
        }
        
        return (objectCIImage, backgroundWithoutObjectCIImage)
    }
}

// MARK: - Detection Contour
extension CICutoutObjectManager {
    
    // Получение image с нарисованным контуром
    private func generateContourImage(maskCGImage: CGImage,
                                      originalSize: CGSize,
                                      baseImage: UIImage) -> CIImage? {
        var contourImage: UIImage? = nil

        extractContourPoints(maskCIImage: CIImage(cgImage: maskCGImage), inputImageSize: originalSize) { [weak self] path in
            guard let path = path else { return }
            contourImage = self?.drawPathWithImage(
                cgPath: path,
                originalSize: CGSize(width: originalSize.width / 3, height: originalSize.height / 3),
                baseImage: baseImage
            )
        }

        guard let contourImage else {
            return nil
        }
        return CIImage(image: contourImage)
    }
    
    // Извлечение контура из маски
    private func extractContourPoints(maskCIImage: CIImage,
                                      inputImageSize: CGSize,
                                      completion: @escaping (CGPath?) -> Void) {
        let request = VNDetectContoursRequest { request, error in
            if let error = error {
                print("VNDetectContoursRequest failed: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let observations = request.results as? [VNContoursObservation],
                  let normalizedPath = observations.first?.normalizedPath else {
                print("No valid contours found.")
                completion(nil)
                return
            }
            completion(normalizedPath)
        }

        // Настройка контрастности для лучшего обнаружения контуров
        request.contrastAdjustment = 1.0

        let handler = VNImageRequestHandler(ciImage: maskCIImage, orientation: .downMirrored)
        
        do {
            try handler.perform([request])
        } catch {
            print("Failed to perform VNImageRequestHandler: \(error.localizedDescription)")
            completion(nil)
        }
    }
    
    // Отрисовка контура по исходному изображению
    private func drawPathWithImage(cgPath: CGPath, originalSize: CGSize, baseImage: UIImage) -> UIImage? {
        return UIGraphicsImageRenderer(size: originalSize).image { _ in
            // Отрисовка исходного изображения
            baseImage.draw(in: CGRect(origin: .zero, size: originalSize))

            // Создание UIBezierPath из CGPath
            let path = UIBezierPath(cgPath: cgPath)

            // Масштабирование пути до размеров изображения
            let zoomScale = CGAffineTransform(scaleX: originalSize.width, y: originalSize.height)
            path.apply(zoomScale)

            // Настройка стиля линии
            path.lineWidth = 2.0
            path.lineCapStyle = .round
            UIColor.red.setStroke()

            // Отрисовка контура
            path.stroke()
        }
    }
}
