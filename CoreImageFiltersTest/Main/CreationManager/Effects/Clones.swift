//
//  Clones.swift
//  CoreImageFiltersTest
//
//  Created by Yuliya on 05/11/2024.
//

import AVFoundation
import PhotosUI

// MARK: - Clones effect (model u2netp)
//extension CICreationVideoManager {
//    func applyClonesEffectToComp(assetURL: URL) async throws -> URL? {
//
//        let videoAsset = AVAsset(url: assetURL)
//        let videoReader = try? AVAssetReader(asset: videoAsset)
//        guard let videoTrack = try! await videoAsset.loadTracks(withMediaType: .video).first else {
//            throw CITestingError.noVideoTrack("Track missing in video")
//        }
//        
//        let fileManager = FileManager.default
//        let tempDirectory = fileManager.temporaryDirectory
//        let outputLink = tempDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mp4")
//        
//        let outputWriter = try? AVAssetWriter(outputURL: outputLink, fileType: .mp4)
//        let outputVideoInput = getOutputVideoInput()
//        outputWriter?.add(outputVideoInput)
//        
//        let videoOutput = getVideoOutput(videoTrack: videoTrack)
//        videoReader?.add(videoOutput)
//
//        let imageBufferAdaptor = getImageBufferAdaptor(outputVideoInput: outputVideoInput)
//        let ciContext = CIContext()
//        
//        videoReader?.startReading()
//        
//        outputWriter?.startWriting()
//        outputWriter?.startSession(atSourceTime: .zero)
//        
//        let frameDuration = CMTime(value: 1, timescale: ciSettingsModel.fpsRate)
//        var presentationTime: CMTime = .zero
//        
//        var frameNumber = 0
//        let videoDuration = try! await videoAsset.load(.duration)
//        let videoFrameRate = try! await videoTrack.load(.nominalFrameRate)
//        let videoFrame = videoDuration.seconds * Double(videoFrameRate)
//        let fps = ciSettingsModel.getFpsRatio()
//        
//        var cutoutObject: CIImage?
//        
//        while frameNumber < (Int(videoFrame) * fps) {
//            
//            guard let videoCIImage = getCIImage(with: videoOutput)
//            else { break }
//            
//            func recordingProcessedFrame(outputPixelBuffer: CVPixelBuffer?) {
//                if let outputPixelBuffer = outputPixelBuffer {
//                    while !imageBufferAdaptor.assetWriterInput.isReadyForMoreMediaData { }
//                    imageBufferAdaptor.append(outputPixelBuffer, withPresentationTime: presentationTime)
//                    presentationTime = CMTimeAdd(presentationTime, frameDuration)
//                    frameNumber += 1
//                    debugPrint("[Create]: FRAME NUMBER - \(frameNumber)")
//                }
//            }
//            
//            autoreleasepool {
//                //   TODO: - здесь можно тестировать обработку с CutOut объектами
//                switch frameNumber {
//                case (0 * fps)..<(30 * fps):
//                    
//                    // remove back
//                    guard let removeBackResult = removeBackground(from: videoCIImage),
////                          let finalCIImage = removeBackResult.backgroundWithHole,
//                          let finalCIImage /*cutoutObj*/ = removeBackResult.objectWithoutBackground
//                    else { return }
//          
////                    cutoutObject = cutoutObj
//                    
//                    let extent = videoCIImage.extent
//                    let outputPixelBuffer = createCVPixelBuffer(forImage: finalCIImage, size: extent.size, context: ciContext)
//                    
//                    recordingProcessedFrame(outputPixelBuffer: outputPixelBuffer)
//                    
//                default:
//                    
//                    let extent = videoCIImage.extent
//                    let outputPixelBuffer = createCVPixelBuffer(forImage: videoCIImage, size: extent.size, context: ciContext)
//                    
//                    recordingProcessedFrame(outputPixelBuffer: outputPixelBuffer)
//                }
//            }
//        }
//        
//        outputVideoInput.markAsFinished()
//        await outputWriter?.finishWriting()
//        videoReader?.cancelReading()
//        
//        return outputLink
//    }
//    
//    private func removeBackground(from ciImage: CIImage) -> (backgroundWithHole: CIImage?, objectWithoutBackground: CIImage?)? {
//        // Размер, к которому будет приведено изображение для работы с моделью
//        let targetSize = CGSize(width: 320, height: 320)
//        
//        let context = CIContext(options: nil)
//        
//        // Создание уменьшенной версии изображения для обработки в модели
//        guard let resizedImage = ciImage.resize(to: targetSize),
//              let mlModel = try? u2netp(),
//              let resizedCGImage = context.createCGImage(resizedImage, from: resizedImage.extent),
//              let resultMask = try? mlModel.prediction(input: u2netpInput(in_0With: resizedCGImage)).out_p1 else {
//            return nil
//        }
//        
//        // Маска результата из модели
//        var maskImage = CIImage(cvPixelBuffer: resultMask)
//        
//        // Масштабирование маски до размеров исходного изображения
//        let scaleX = ciImage.extent.width / maskImage.extent.width
//        let scaleY = ciImage.extent.height / maskImage.extent.height
//        maskImage = maskImage.transformed(by: .init(scaleX: scaleX, y: scaleY))
//        
//        // Вырезанный объект (без фона)
//        guard let objectWithoutBackground = filterManager.getCIImageBlendWithRedMask(inputImage: ciImage, maskImage: maskImage)
//        else { return nil }
//        
//        // Фон с "черной дыркой" от вырезанного объекта
//        let backgroundWithHole = filterManager.createBackgroundWithoutObject(from: ciImage, maskImage: maskImage)
//        
//        return (backgroundWithHole, objectWithoutBackground)
//    }
//}

// MARK: - Clones effect (model DeepLabV3)
extension CICreationVideoManager {
    func applyClonesEffectToComp(assetURL: URL) async throws -> URL? {

        let videoAsset = AVAsset(url: assetURL)
        let videoReader = try? AVAssetReader(asset: videoAsset)
        guard let videoTrack = try! await videoAsset.loadTracks(withMediaType: .video).first else {
            throw CITestingError.noVideoTrack("Track missing in video")
        }
        
        let fileManager = FileManager.default
        let tempDirectory = fileManager.temporaryDirectory
        let outputLink = tempDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mp4")
        
        let outputWriter = try? AVAssetWriter(outputURL: outputLink, fileType: .mp4)
        let outputVideoInput = getOutputVideoInput()
        outputWriter?.add(outputVideoInput)
        
        let videoOutput = getVideoOutput(videoTrack: videoTrack)
        videoReader?.add(videoOutput)

        let imageBufferAdaptor = getImageBufferAdaptor(outputVideoInput: outputVideoInput)
        let ciContext = CIContext()
        
        videoReader?.startReading()
        
        outputWriter?.startWriting()
        outputWriter?.startSession(atSourceTime: .zero)
        
        let frameDuration = CMTime(value: 1, timescale: ciSettingsModel.fpsRate)
        var presentationTime: CMTime = .zero
        
        var frameNumber = 0
        var timeForAnim = 0
        
        let videoDuration = try! await videoAsset.load(.duration)
        let videoFrameRate = try! await videoTrack.load(.nominalFrameRate)
        let videoFrame = videoDuration.seconds * Double(videoFrameRate)
        let fps = ciSettingsModel.getFpsRatio()
        
        var cutoutObjects: [CVPixelBuffer] = []
        var anotherBuffers: [CVPixelBuffer] = []
        
        func recordingProcessedFrame(outputPixelBuffer: CVPixelBuffer?, completion: (() -> Void)?) {
            if let outputPixelBuffer = outputPixelBuffer {
                while !imageBufferAdaptor.assetWriterInput.isReadyForMoreMediaData { }
                imageBufferAdaptor.append(outputPixelBuffer, withPresentationTime: presentationTime)
                presentationTime = CMTimeAdd(presentationTime, frameDuration)
//                frameNumber += 1
                completion?()
                debugPrint("[Create]: FRAME NUMBER - \(frameNumber)")
            }
        }
        
        while frameNumber < (Int(videoFrame) * fps) {
            
            guard let videoCIImage = getCIImage(with: videoOutput)
            else { break }
            
            func getFrame(with cutoutCIImage: CIImage) {

                let radius = linear(time: Float(timeForAnim), startValue: 83, change: -83, duration: Float(9 * fps))

                guard let filteredCIImage = filterManager.getCIImageWithMotionBlur(image: cutoutCIImage,
                                                                                   radius: Double(radius),
                                                                                   angle: 1.57)
                else { return }
                
                let cutoutObjectExtent = cutoutCIImage.extent
                guard let cutoutObjectOutputPixelBuffer = createCVPixelBuffer(forImage: filteredCIImage /*cutoutCIImage*/,
                                                                              size: cutoutObjectExtent.size,
                                                                              context: ciContext)
                else { return }
                cutoutObjects.append(cutoutObjectOutputPixelBuffer)
            }
            
            func linear(time: Float, startValue: Float, change: Float, duration: Float) -> Float {
                return change * time / duration + startValue
            }
            
            autoreleasepool {
                switch frameNumber {
                case (0 * fps)..<(20 * fps):
                    
                    let radius = linear(time: Float(timeForAnim), startValue: 83, change: -83, duration: Float(20 * fps))
                    
                    let cutoutResult = cutoutManager.getCutoutObjects(inputImage: videoCIImage)
                    guard let cutoutObjectCIImage = cutoutResult.objectImage,
                          let filteredCutoutObjectCIImage = filterManager.getCIImageWithMotionBlur(
                            image: cutoutObjectCIImage,
                            radius: Double(radius),
                            angle: 1.57),
                          let finalCIImage = filterManager.getCIImageSourceOverCompositing(
                            image: filteredCutoutObjectCIImage,
                            background: videoCIImage)
                    else { return }
          
//                    getFrame(with: cutoutObjectCIImage)
                    
                    let extent = videoCIImage.extent
                    let outputPixelBuffer = createCVPixelBuffer(forImage: finalCIImage, size: extent.size, context: ciContext)

                    recordingProcessedFrame(outputPixelBuffer: outputPixelBuffer) {
                        frameNumber += 1
                        timeForAnim += 1
                    }
                    
                default:
                    timeForAnim = 0
                    let extent = videoCIImage.extent
                    let outputPixelBuffer = createCVPixelBuffer(forImage: videoCIImage, size: extent.size, context: ciContext)
                    
                    guard let outputPixelBuffer = outputPixelBuffer else { return }
                    recordingProcessedFrame(outputPixelBuffer: outputPixelBuffer) {
                        frameNumber += 1
                    }
//                    anotherBuffers.append(outputPixelBuffer)
//                    frameNumber += 1
                }
            }
        }
        
//        frameNumber = 10
//        while frameNumber < (Int(videoFrame) * fps) {
//
//            switch frameNumber {
//            case (10 * fps)..<(20 * fps):
//                
//                cutoutObjects.forEach { buffer in
//                    recordingProcessedFrame(outputPixelBuffer: buffer) {
//                        frameNumber += 1
//                    }
//                }
//                
//            default:
//                
//                anotherBuffers.forEach { buffer in
//                    recordingProcessedFrame(outputPixelBuffer: buffer) {
//                        frameNumber += 1
//                    }
//                }
//            }
//        }
        
        outputVideoInput.markAsFinished()
        await outputWriter?.finishWriting()
        videoReader?.cancelReading()
        
        return outputLink
    }
}
