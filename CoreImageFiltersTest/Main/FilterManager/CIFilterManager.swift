//
//  CIFilterManager.swift
//  CoreImageTest
//
//  Created by Yuliya on 27/08/2024.
//

import UIKit
import CIFilterFactory
import CoreImage

final class CIFilterManager {
    // создаем фильтры и настраиваем
    //
    // func .....(inputImage: CIImage) -> CIImage? {
    //     let filter = CIFilter.#filterName#(inputImage: inputImage, .......)
    //     return filter.outputImage
    // }
}

// MARK: - CICategoryBlur
extension CIFilterManager {
    
    //Bokeh Blur
    func getCIImageWithBokehBlur(inputImage: CIImage) -> CIImage? {
        guard let filter = CIFF.BokehBlur(inputImage: inputImage, radius: 10,
                                          ringAmount: 80, ringSize: 20, softness: 30),
              let ciImage = filter.outputImage
        else { return nil}
        return ciImage
    }
    
    //Box Blur
    func getCIImageWithBoxBlur(inputImage: CIImage, radius: Double) -> CIImage? {
        guard let filter = CIFF.BoxBlur(inputImage: inputImage, radius: radius),
              let ciImage = filter.outputImage
        else { return nil }
        return ciImage
    }
    
    //Motion Blur
    func getCIImageWithMotionBlur(image: CIImage, radius: Double, angle: Double = 0) -> CIImage? {
        guard let filter = CIFF.MotionBlur(inputImage: image, radius: radius, angle: angle),
              let ciImage = filter.outputImage
        else { return nil }
        return ciImage
    }
    
    //Gaussian Blur
    func getCIImageWithGaussianBlurFilter(inputImage: CIImage) -> CIImage? {
        guard let filter = CIFF.GaussianBlur(inputImage: inputImage, radius: 50),
              let ciImage = filter.outputImage
        else { return nil }
        return ciImage
    }
    
    //MaskedVariableBlur (Mask)
    func getCIImageWithMaskedVariableBlur(inputImage: CIImage, inputMask: CIImage) -> CIImage? {
        guard let filter = CIFF.MaskedVariableBlur(inputImage: inputImage, mask: inputMask, radius: 50),
              let ciImage = filter.outputImage
        else { return nil }
        return ciImage
    }
}

// MARK: - CICategoryReduction
extension CIFilterManager {
    
    func getCIImageWithKMeansFilter(inputImage: CIImage) -> CIImage? {
        //        count - maxValue = 128, defaultValue = 8
        //        passes - maxValue = 20, defaultValue = 5
        
        guard  let filter = CIFF.KMeans(inputImage: inputImage,
                                        extent: inputImage.extent,
                                        count: 10,
                                        passes: 10),
               let paletteImage = filter.outputImage,
               let palettizeFilter = CIFF.Palettize(inputImage: inputImage,
                                                    paletteImage: paletteImage),
               let ciImage = palettizeFilter.outputImage
        else { return nil }
        return ciImage
    }
}
    
// MARK: - CICategoryDistortionEffect
extension CIFilterManager {
    //DisplacementDistortion
    func getCIImageWithDisplacementDistortionFilter(inputImage: CIImage,
                                                    displacementImage: CIImage,
                                                    scale: Double) -> CIImage? {
        guard let filter = CIFF.DisplacementDistortion(inputImage: inputImage,
                                                       displacementImage: displacementImage,
                                                       scale: scale),
              let ciImage = filter.outputImage
        else { return nil }
        return ciImage
    }
    /*    func displacementDistortion(inputImage: CIImage) -> CIImage? {
     guard let displacementImage = CIFF.CheckerboardGenerator(color0: CIColor.white,
     color1: CIColor.black,
     width: 200),
     let displacementOutputImage = displacementImage.outputImage,
     let gaussianBlur = CIFF.GaussianBlur(inputImage: displacementOutputImage,
     radius: 40),
     let gaussianBlurOutputImage = gaussianBlur.outputImage,
     let filter = CIFF.DisplacementDistortion(inputImage: inputImage, displacementImage: gaussianBlurOutputImage, scale: 1000),
     let ciImage = filter.outputImage
     else { return nil }
     return ciImage
     }*/
    
}

// MARK: - CICategoryColorAdjustment
extension CIFilterManager {
    //Exposure
    func getCIImageWithExposureFilter(inputImage: CIImage, inputEV: Double = 0.5) -> CIImage? {
        guard let filter = CIFF.ExposureAdjust(inputImage: inputImage, eV: inputEV),
              let ciImage = filter.outputImage
        else { return nil}
        return ciImage
    }
    
    //Disparity
    func getCIImageWithDepthToDisparityFilter(inputImage: CIImage) -> CIImage? {
        guard let filter = CIFF.DepthToDisparity(inputImage: inputImage),
              let ciImage = filter.outputImage
        else { return nil }
        return ciImage
    }
    
    //Sepia
    func getCIImageWithSepiaToneFilter(inputImage: CIImage) -> CIImage? {
        guard let filter = CIFF.SepiaTone(inputImage: inputImage, intensity: 0.8),
              let ciImage = filter.outputImage
        else { return nil }
        return ciImage
    }
    
    //GammaAdjust
    func getCIImageWithGammaAdjustFilter(inputImage: CIImage, gammaValue: Double = 0.75) -> CIImage? {
        guard let filter = CIFF.GammaAdjust(inputImage: inputImage, power: gammaValue),
              let ciImage = filter.outputImage
        else { return nil }
        return ciImage
    }
    
    //HueAdjust
    func getCIImageWithHueAdjustFilter(inputImage: CIImage, angle: Double = 0.0) -> CIImage? {
        guard let filter = CIFF.HueAdjust(inputImage: inputImage, angle: angle),
              let ciImage = filter.outputImage
        else { return nil }
        return ciImage
    }
    
    //WhitePointAdjust
    func getCIImageWithWhitePointAdjustFilter(inputImage: CIImage, newWhitePoint: CIColor) -> CIImage? {
        // newWhitePoint = CIColor(red: 208/255.0, green: 208/255.0, blue: 208/255.0)
        guard let filter = CIFF.WhitePointAdjust(inputImage: inputImage, color: newWhitePoint),
              let ciImage = filter.outputImage
        else { return nil }
        return ciImage
    }
    
    //TemperatureAndTint
    func getCIImageWithTemperatureAndTintFilter(inputImage: CIImage,
                                                neutral: CGPoint = .init(x: 6500, y: 0),
                                                targetNeutral: CGPoint = .init(x: 6500, y: 0)
    ) -> CIImage? {
        guard let filter = CIFF.TemperatureAndTint(inputImage: inputImage,
                                                   neutral: neutral,
                                                   targetNeutral: targetNeutral),
              let ciImage = filter.outputImage
        else { return nil }
        return ciImage
    }
    
    //Vibrance
    func getCIImageWithVibranceFilter(inputImage: CIImage,
                                      vibrance: Double = 0) -> CIImage? {
        guard let filter = CIFF.Vibrance(inputImage: inputImage,
                                         amount: vibrance),
              let ciImage = filter.outputImage
        else { return nil }
        return ciImage
    }
    
    //Brightness: (диапазон [-1.0, 1.0]), Contrast: (диапазон [0, 4]), Saturation: (диапазон [0, 2])
    func getCIImageWithColorControlsFilter(inputImage: CIImage,
                                           saturation: Double = 1.0,
                                           brightness: Double = 0.0,
                                           contrast: Double = 1.0) -> CIImage? {
        
        // Проверка, что параметры в допустимом диапазоне
        let clampedSaturation = max(0.0, min(saturation, 2.0))
        let clampedBrightness = max(-1.0, min(brightness, 1.0))
        let clampedContrast = max(0.25, min(contrast, 4.0))
        
        // Создаем фильтр с ограниченными значениями
        guard let filter = CIFF.ColorControls(inputImage: inputImage,
                                              saturation: clampedSaturation,
                                              brightness: clampedBrightness,
                                              contrast: clampedContrast),
              let ciImage = filter.outputImage
        else { return nil }
        
        return ciImage
    }
    
    //Noise
    func getCIImageWithNoise(inputImage: CIImage, noiseAmount: Double = 0.07) -> CIImage? {
        let width = Int(inputImage.extent.width)
        let height = Int(inputImage.extent.height)
        let noiseImage = generateNoiseImage(width: width, height: height, noiseAmount: noiseAmount)
        
        guard let filter = CIFF.AdditionCompositing(inputImage: noiseImage, backgroundImage: inputImage),
              let ciImage = filter.outputImage
        else { return nil }
        return ciImage
    }
    // Вспомогательная функция для создания изображения noise
    func generateNoiseImage(width: Int, height: Int, noiseAmount: Double) -> CIImage? {
        // Создаем шумовой пиксельный массив
        let noiseData = UnsafeMutablePointer<UInt8>.allocate(capacity: width * height * 4) // 4 канала (RGBA)
        
        for i in 0 ..< width * height {
            let noiseValue = UInt8(arc4random_uniform(UInt32(noiseAmount * 255.0))) // шум
            noiseData[i * 4] = noiseValue        // R
            noiseData[i * 4 + 1] = noiseValue    // G
            noiseData[i * 4 + 2] = noiseValue    // B
            noiseData[i * 4 + 3] = 64            // Alpha
        }
        
        // Создаем CGImage из шума
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapContext = CGContext(data: noiseData, width: width, height: height,
                                      bitsPerComponent: 8, bytesPerRow: width * 4, space: colorSpace,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        guard let cgImage = bitmapContext?.makeImage() else { return nil }
        return CIImage(cgImage: cgImage)
    }
    
    //CIToneCurve
    func getCIImageWithToneCurveFilter(inputImage: CIImage,
                                       points: CurvePoints = .init(photoshopPoint0: .init(x: 0, y: 0),
                                                                   photoshopPoint1: .init(x: 63.75, y: 63.75),
                                                                   photoshopPoint2: .init(x: 127.5, y: 127.5),
                                                                   photoshopPoint3: .init(x: 191.25, y: 191.25),
                                                                   photoshopPoint4: .init(x: 255, y: 255))
    ) -> CIImage? {
        guard let filter = CIFF.ToneCurve(inputImage: inputImage, point0: points.point0, point1: points.point1,
                                          point2: points.point2, point3: points.point3, point4: points.point4),
              let ciImage = filter.outputImage
        else { return nil }
        return ciImage
    }
    
    //ColorMatrix
    func getCIImageWithColorMatrixFilter(inputImage: CIImage,
                                         vectors: ColorMatrixVectors = .init(inputRVector: CIVector(x: 1.0, y: 0.0, z: 0.0, w: 0.0),
                                                                             inputGVector: CIVector(x: 0.0, y: 1.0, z: 0.0, w: 0.0),
                                                                             inputBVector: CIVector(x: 0.0, y: 0.0, z: 1.0, w: 0.0),
                                                                             inputAVector: CIVector(x: 0.0, y: 0.0, z: 0.0, w: 1.0),
                                                                             inputBiasVector: CIVector(x: 0.0, y: 0.0, z: 0.0, w: 0.0))
    ) -> CIImage? {
        guard let filter = CIFF.ColorMatrix(inputImage: inputImage,
                                            rVector: vectors.rVector,
                                            gVector: vectors.gVector,
                                            bVector: vectors.bVector,
                                            aVector: vectors.aVector,
                                            biasVector: vectors.biasVector),
              let ciImage = filter.outputImage
        else { return nil }
        return ciImage
    }
}
    
// MARK: - CICategoryColorEffect
extension CIFilterManager {
    
    //CIMaskToAlpha (черные значения становятся полностью прозрачными)
    func getCIImageMaskToAlpha(maskImage: CIImage) -> CIImage? {
        guard let filter = CIFF.MaskToAlpha(inputImage: maskImage),
              let ciImage = filter.outputImage
        else { return nil }
        return ciImage
    }
}

// MARK: - CICategoryGeometryAdjustment
extension CIFilterManager {
    
    //LanczosScaleTransform
    func getCIImageWithLanczosScaleTransformFilter(inputImage: CIImage, scaleFactor: Double) -> CIImage? {
        guard let filter = CIFF.LanczosScaleTransform(inputImage: inputImage, scale: scaleFactor),
              let scaledCIImage = filter.outputImage
        else { return nil }
        
//Если нужно изменит положение scaledCIImage относительно холста
//        let originalSize = inputImage.extent.size
//        let scaledImageSize = scaledCIImage.extent.size
//
//        let centerX = (originalSize.width - scaledImageSize.width) / 2
//        let centerY = (originalSize.height - scaledImageSize.height) / 2
//        let translatedImage = scaledImage.transformed(by: CGAffineTransform(translationX: centerX, y: centerY))
        
        return scaledCIImage /*translatedImage*/
    }
}

// MARK: - CICategorySharpen
extension CIFilterManager {
    
    //UnsharpMask
    //amount = intensity (диапазон [0, 1]), radius диапазон [0.0, 100.0]
    func getCIImageWithUnsharpMaskFilter(inputImage: CIImage, radius: Double = 2.5, amount: Double) -> CIImage? {
        guard let filter = CIFF.UnsharpMask(inputImage: inputImage, radius: radius, intensity: amount),
              let ciImage = filter.outputImage
        else { return nil }
        return ciImage
    }
}

// MARK: - CICategoryStylize
extension CIFilterManager {
    
    //CIBlendWithRedMask
    func getCIImageBlendWithRedMask(inputImage: CIImage, maskImage: CIImage) -> CIImage? {
        guard let filter = CIFF.BlendWithRedMask(inputImage: inputImage, maskImage: maskImage),
              let ciImage = filter.outputImage
        else { return nil }
        return ciImage
    }
    
    // Метод для создания фона с «черной дыркой» (на основе инвертированной маски)
    func createBackgroundWithoutObject(from backImage: CIImage, maskImage: CIImage) -> CIImage? {
        guard let invertedMask = invertMask(maskImage)
        else { return nil }
        
        // Применяем инвертированную маску к изображению для создания "дыры" на фоне
        guard let blendWithMaskFilter = CIFF.BlendWithMask(maskImage: invertedMask),
              let backgroundCIImage = blendWithMaskFilter.outputImage
        else { return nil }
        
        return backgroundCIImage
    }
    // Метод для инвертирования маски
    func invertMask(_ maskImage: CIImage) -> CIImage? {
        guard let filter = CIFF.ColorInvert(inputImage: maskImage),
              let ciImage = filter.outputImage
        else { return nil }
        return ciImage
    }
}
    
// MARK: - CICategoryCompositeOperation
extension CIFilterManager {
    
    //SourceOverCompositing
    func getCIImageSourceOverCompositing(image: CIImage, background: CIImage) -> CIImage? {
        guard let filter = CIFF.SourceOverCompositing(inputImage: image, backgroundImage: background),
              let ciImage = filter.outputImage
        else { return nil }
        return ciImage
    }
    
    //SourceOutCompositing
    func getCIImageSourceOutCompositing(inputImage: CIImage, maskAlphaImage: CIImage) -> CIImage? {
        guard let filter = CIFF.SourceOutCompositing(inputImage: inputImage, backgroundImage: maskAlphaImage),
              let ciImage = filter.outputImage
        else { return nil }
        return ciImage
    }
    
    //SourceInCompositing
    func getCIImageSourceInCompositing(inputImage: CIImage, maskAlphaImage: CIImage) -> CIImage? {
        guard let filter = CIFF.SourceInCompositing(inputImage: inputImage, backgroundImage: maskAlphaImage),
              let ciImage = filter.outputImage
        else { return nil }
        return ciImage
    }
    
    //AdditionFilter (with overlay)
    func getCIImageAdditionFilter(inputImage: CIImage, overlayImage: CIImage) -> CIImage? {
        guard let filter = CIFF.AdditionCompositing(inputImage: overlayImage, backgroundImage: inputImage),
              let ciImage = filter.outputImage
        else { return nil }
        return ciImage
    }
}

extension CIFilterManager {
    
    //Add overlay
    func getMixedCIImageUsingAddFilter(backgroundImage: CIImage, overlayCIImage: CIImage, overlayInputEV: Double = 1.5) -> CIImage? {
        guard let highExpOverlayImage = getCIImageWithExposureFilter(inputImage: overlayCIImage, inputEV: overlayInputEV),
              let mixedCIImage = getCIImageAdditionFilter(inputImage: backgroundImage, overlayImage: highExpOverlayImage)
        else { return nil }

        let lowExpMixedImage = getCIImageWithExposureFilter(inputImage: mixedCIImage, inputEV:  -1)
        
        return lowExpMixedImage
    }
    
}
