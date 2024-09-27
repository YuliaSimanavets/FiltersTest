//
//  ColorCorrection.swift
//  CoreImageFiltersTest
//
//  Created by Yuliya on 27/09/2024.
//

import AVFoundation
import PhotosUI

/* Методы для создания цветовых фильтров:
    colorControls()
    gammaAdjust()
    exposureAdjust()
    hueAdjust()
    whitePointAdjust()
    temperatureAndTint()
    toneCurve()
    vibrance()
    colorMatrix()
*/

extension CICreationVideoManager {
    
    func applyColorFiltersToFullComp(assetLink: URL) async throws -> URL {
        let videoAsset = AVAsset(url: assetLink)
        let videoReader = try? AVAssetReader(asset: videoAsset)
        guard let videoTrack = try? await videoAsset.loadTracks(withMediaType: .video).first else {
            throw CITestingError.noVideoTrack("Track missing in video")
        }
        
        let fileManager = FileManager.default
        let tempDirectory = fileManager.temporaryDirectory
        let outputLink = tempDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mp4")
        
        let outputWriter = try? AVAssetWriter(outputURL: outputLink, fileType: .mp4)
        let outputVideoInput = getOutputVideoInput()
        outputWriter?.add(outputVideoInput)
        
        let ciContext = CIContext()
        let videoOutput = getVideoOutput(videoTrack: videoTrack)
        videoReader?.add(videoOutput)
        
        let imageBufferAdaptor = getImageBufferAdaptor(outputVideoInput: outputVideoInput)
        
        videoReader?.startReading()
        
        outputWriter?.startWriting()
        outputWriter?.startSession(atSourceTime: .zero)
        
        let frameDuration = CMTime(value: 1, timescale: ciSettingsModel.fpsRate)
        var presentationTime: CMTime = .zero
        
        var frameNumber = 0
        let videoDuration = try! await videoAsset.load(.duration)
        let videoFrameRate = try! await videoTrack.load(.nominalFrameRate)
        let videoFrame = videoDuration.seconds * Double(videoFrameRate)
        let fps = ciSettingsModel.getFpsRatio()
        
        while frameNumber < (Int(videoFrame) * fps) {
            
            guard let videoCIImage = getCIImage(with: videoOutput)
            else { break }
            
            autoreleasepool {
                
//   TODO: - здесь можно тестировать обработку: не требующую наложения overlays
                
                // вспомогательные поля со значениями, которые потом передаются в методы
                //whitePointAdjust
                let whitePoint = CIColor(red: 208/255.0,
                                         green: 208/255.0,
                                         blue: 208/255.0)
                //temperatureAndTint
                let neutral = CGPoint(x: 6500, y: 0)
                let targetNeutral = CGPoint(x: 6500, y: 0)
                
                //toneCurve
                //вводим значения из photoShop
                let points = CurvePoints(photoshopPoint0: .init(x: 0, y: 0),
                                         photoshopPoint1: .init(x: 50, y: 80),
                                         photoshopPoint2: .init(x: 140, y: 150),
                                         photoshopPoint3: .init(x: 200, y: 200),
                                         photoshopPoint4: .init(x: 255, y: 255))
                
                //colorControl
                let vectors = ColorMatrixVectors(inputRVector: CIVector(x: 1.5, y: 0.0, z: 0.0, w: 0.0),     // красный,    def: x = 1
                                                 inputGVector: CIVector(x: 0.0, y: 1.1, z: 0.0, w: 0.0),     // зеленый,    def: y = 1
                                                 inputBVector: CIVector(x: 0.0, y: 0.0, z: 1.2, w: 0.0),     // синий,      def: z = 1
                                                 inputAVector: CIVector(x: 0.0, y: 0.0, z: 0.0, w: 1.1),     // альфа,      def: w = 1
                                                 inputBiasVector: CIVector(x: 0.0, y: 0.0, z: 0.0, w: 0.0))  // смещение
                    
                      // colorControls() filter
                guard let colorControls = filterManager.getCIImageWithColorControlsFilter(inputImage: videoCIImage,
                                                                                          saturation: 1.0,       // def value 1.0
                                                                                          brightness: 0.0,       // def value 0.0
                                                                                          contrast:  1.0),       // def value 1.0
                      
                      // gammaAdjust() filter
                      let gammaAdjust = filterManager.getCIImageWithGammaAdjustFilter(inputImage: colorControls,
                                                                                      gammaValue: 0.75),        // def value 0.75
                        
                      // exposureAdjust() filter
                      let exposureAdjust = filterManager.getCIImageWithExposureFilter(inputImage: gammaAdjust,
                                                                                        inputEV: 0.5),          // def value 0.5
                        
                      // hueAdjust() filter
                      let hueAdjust = filterManager.getCIImageWithHueAdjustFilter(inputImage: exposureAdjust,
                                                                                  angle: 4),                    // def value 0.0
                      // whitePointAdjust() filter
                      let whitePointAdjust = filterManager.getCIImageWithWhitePointAdjustFilter(inputImage: hueAdjust,
                                                                                                newWhitePoint: whitePoint),
                      // temperatureAndTint() filter
                            // def value neutral = [6500, 0]
                            // def value targetNeutral = [6500, 0]
                      let temperatureAndTint = filterManager.getCIImageWithTemperatureAndTintFilter(inputImage: whitePointAdjust,
                                                                                                    neutral: neutral,
                                                                                                    targetNeutral: targetNeutral),
                        
                      // toneCurve() filter
                      let toneCurve = filterManager.getCIImageWithToneCurveFilter(inputImage: temperatureAndTint,
                                                                                  points: points),

                      // vibrance() filter
                      let vibrance = filterManager.getCIImageWithVibranceFilter(inputImage: toneCurve,
                                                                                vibrance: 0),        // def value 0, [-1, 1]
                        
                      // colorMatrix() filter
                      let colorMatrix = filterManager.getCIImageWithColorMatrixFilter(inputImage: vibrance,
                                                                                        vectors: vectors)
                else { return }

                let finalCIImage = colorMatrix
                
                // ниже всё остается неизменным
                let extent = videoCIImage.extent
                let outputPixelBuffer = createCVPixelBuffer(forImage: finalCIImage, size: extent.size, context: ciContext)
                
                guard let outputPixelBuffer else { return }
                while !imageBufferAdaptor.assetWriterInput.isReadyForMoreMediaData { }
                imageBufferAdaptor.append(outputPixelBuffer, withPresentationTime: presentationTime)
                presentationTime = CMTimeAdd(presentationTime, frameDuration)
                frameNumber += 1
                debugPrint("[Create reel]: FRAME NUMBER - \(frameNumber)")
            }
        }
        
        outputVideoInput.markAsFinished()
        await outputWriter?.finishWriting()
        videoReader?.cancelReading()
        
        return outputLink
    }
}
