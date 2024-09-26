//
//  CICreationVideoManager.swift
//  FiltersTest
//
//  Created by Yuliya on 16/09/2024.
//

import AVFoundation
import PhotosUI

enum CITestingError: Error {
    case noVideoTrack(String)
    case unknown
}

final class CICreationVideoManager {
    
    private let ciSettingsModel = CISettingsModel()
    private let filterManager: CIFilterManager
    
    init(filterManager: CIFilterManager) {
        self.filterManager = filterManager
    }
}

//    MARK: - Create video WITHOUT overlays
extension CICreationVideoManager {
    
    func addFilterToFullComp(assetLink: URL) async throws -> URL {
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
                // blur filter
                guard let finalCIImage = filterManager.getCIImageWithMotionBlur(image: videoCIImage, radius: 20)
                else { return }
                
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

//    MARK: - Create video with CURVE effect
extension CICreationVideoManager {
    func applyCurveToFullComp(assetLink: URL) async throws -> URL {
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
//   TODO: - здесь можно тестировать обработку: tone curve filter
                // tone curve filter
                // в переменную points вводим значения из photoShop(?)
                let points = CurvePoints(photoshopPoint0: .init(x: 0, y: 0),
                                         photoshopPoint1: .init(x: 50, y: 80),
                                         photoshopPoint2: .init(x: 140, y: 150),
                                         photoshopPoint3: .init(x: 200, y: 200),
                                         photoshopPoint4: .init(x: 255, y: 255))
                
                guard let finalCIImage = filterManager.getCIImageWithToneCurveFilter(inputImage: videoCIImage,
                                                                                     points: points
                                                                                     /* параметр "points : ... " можно удалить, тогда возьмутся значения точек по умолчанию */)
                else { return }
                
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

//    MARK: - Create video with COLOR MATRIX effect
extension CICreationVideoManager {
    func applyColorMatrixToFullComp(assetLink: URL) async throws -> URL {
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
//   TODO: - здесь можно тестировать обработку: color matrix effect
                // color matrix effect
                // в переменную vectors вводим необходимые значения
                let vectors = ColorMatrixVectors(inputRVector: CIVector(x: 1.5, y: 0.0, z: 0.0, w: 0.0),     // красный цвет
                                                 inputGVector: CIVector(x: 0.0, y: 1.1, z: 0.0, w: 0.0),     // зеленый цвет
                                                 inputBVector: CIVector(x: 0.0, y: 0.0, z: 1.2, w: 0.0),     // синий цвет
                                                 inputAVector: CIVector(x: 0.0, y: 0.0, z: 0.0, w: 1.1),     // альфа
                                                 inputBiasVector: CIVector(x: 0.0, y: 0.0, z: 0.0, w: 0.0))  // смещение
                
                guard let finalCIImage = filterManager.getCIImageWithColorMatrixFilter(inputImage: videoCIImage,
                                                                                       vectors: vectors
                                                                                       /* параметр "vectors : ... " можно удалить, тогда возьмутся значения точек по умолчанию */)
                else { return }
                
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

//    MARK: - VHS effect
extension CICreationVideoManager {
    func applyVHSEffectToComp(assetURL: URL) async throws -> URL? {
        
        guard let overlayFileURL = Bundle.main.path(forResource: "VHS_Overlay", ofType: "mov"),
              let displaceMapFileURL = Bundle.main.path(forResource: "VHS_DisplaceMap", ofType: "mp4")
        else { return nil}
        
        let overlays: [URL] = [
            URL(fileURLWithPath: overlayFileURL),
            URL(fileURLWithPath: displaceMapFileURL)
        ]
        
        var overlayTracks: [AVAssetTrack] = []
        var overlayReaders: [AVAssetReader?] = []
        var overlayOutputs: [AVAssetReaderTrackOutput] = []
        
        let videoAsset = AVAsset(url: assetURL)
        let videoReader = try? AVAssetReader(asset: videoAsset)
        guard let videoTrack = try! await videoAsset.loadTracks(withMediaType: .video).first else {
            throw CITestingError.noVideoTrack("Track missing in video")
        }
    
        for i in 0..<overlays.count {
            let overlayAsset = AVAsset(url: overlays[i])
            let overlayReader = try? AVAssetReader(asset: overlayAsset)
            guard let overlayTrack = try? await overlayAsset.loadTracks(withMediaType: .video).first else {
                throw CITestingError.noVideoTrack("Track missing in video")
            }
            overlayTracks.append(overlayTrack)
            overlayReaders.append(overlayReader)
        }
        
        let fileManager = FileManager.default
        let tempDirectory = fileManager.temporaryDirectory
        let outputLink = tempDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mp4")
        
        let outputWriter = try? AVAssetWriter(outputURL: outputLink, fileType: .mp4)
        let outputVideoInput = getOutputVideoInput()
        outputWriter?.add(outputVideoInput)
        
        let videoOutput = getVideoOutput(videoTrack: videoTrack)
        videoReader?.add(videoOutput)
        
        for i in 0..<overlays.count {
            let overlayOutput: AVAssetReaderTrackOutput
            overlayOutput = getVideoOutput(videoTrack: overlayTracks[i])
            overlayReaders[i]?.add(overlayOutput)
            overlayOutputs.append(overlayOutput)
        }
        
        let imageBufferAdaptor = getImageBufferAdaptor(outputVideoInput: outputVideoInput)
        let ciContext = CIContext()
        
        videoReader?.startReading()
        overlayReaders.forEach {
            $0?.startReading()
        }
        
        outputWriter?.startWriting()
        outputWriter?.startSession(atSourceTime: .zero)
        
        let frameDuration = CMTime(value: 1, timescale: ciSettingsModel.fpsRate)
        var presentationTime: CMTime = .zero
        
        var frameNumber = 0
        let videoDuration = try! await videoAsset.load(.duration)
        let videoFrameRate = try! await videoTrack.load(.nominalFrameRate)
        let videoFrame = videoDuration.seconds * Double(videoFrameRate)
        let fps = ciSettingsModel.getFpsRatio()
        
        //  в newWhitePoint можно редактировать значение точки белого
        let newWhitePoint = CIColor(red: 208/255.0, green: 208/255.0, blue: 208/255.0)
        
        while frameNumber < (Int(videoFrame) * fps) {
            
            guard let videoCIImage = getCIImage(with: videoOutput),
                  let overlay0CIImage = getCIImage(with: overlayOutputs[0]),
                  let overlay1CIImage = getCIImage(with: overlayOutputs[1])
            else { break }
            
            autoreleasepool {
                
                //   TODO: - здесь поочередно настраиваем все этапы обработки (включая overlays)
                
                // 1. Resolution 270х480 (уменьшение в 16 раз от 1080х1920), с ним будет легче работать, его нужно “убить”
                guard let changedScaleCIImage = filterManager.getCIImageWithLanczosScaleTransformFilter(inputImage: videoCIImage,
                                                                                                        scaleFactor: 0.25),
                // 2. Накладываем оверлей с прозрачностью
                      let mixedOverlayCIImage = filterManager.getMixedCIImageUsingAddFilter(backgroundImage: changedScaleCIImage,
                                                                                            overlayCIImage: overlay0CIImage),
                // 3. Levels: Gamma: 1,24, 4. Output White: 255-> 208
                      let mixedGammaAdjustCIImage = filterManager.getCIImageWithGammaAdjustFilter(inputImage: mixedOverlayCIImage,
                                                                                                  gammaValue: 0.95),
                      let mixedWhitePointCIImage = filterManager.getCIImageWithWhitePointAdjustFilter(inputImage: mixedGammaAdjustCIImage,
                                                                                                      newWhitePoint: newWhitePoint),
                // 5. Brightness: 0 -> 16, 6. Contrast: 0 -> 11
                      let mixedColorControlsCIImage  = filterManager.getCIImageWithColorControlsFilter(inputImage: mixedWhitePointCIImage,
                                                                                                       brightness: 0.005,
                                                                                                       contrast: 1.005),
                // 7. HSB, Saturation 0 -> 10
                      let mixedSaturationCIImage  = filterManager.getCIImageWithColorControlsFilter(inputImage: mixedColorControlsCIImage,
                                                                                                    saturation: 1.7),
                // 8. Noise: Параметры АЕ - Amount 7%
                      let mixedNoiseCIImage = filterManager.getCIImageWithNoise(inputImage: mixedSaturationCIImage),
                // 9. Blur - 0,07px (Box Blur (CIBoxBlur))
                      let mixedBlurCIImage = filterManager.getCIImageWithBoxBlur(inputImage: mixedNoiseCIImage,
                                                                                                    radius: 1 /*0.07*/),
                // 10. Unsharp Mask (CIUnsharpMask): Amount = 350, Radius = 0,7, Threshold = 0
                      let mixedUnsharpMaskCIImage = filterManager.getCIImageWithUnsharpMaskFilter(inputImage: mixedBlurCIImage,
                                                                                       radius: 0.7,
                                                                                       amount: 3.5),
                // 11. Displace Map (displacementDistortion())
                      let mixedDisplacementCIImage = filterManager.getCIImageWithDisplacementDistortionFilter(
                        inputImage: mixedUnsharpMaskCIImage,
                        displacementImage: overlay1CIImage),
                // 12. return to input size ?
                      let finalCIImage = filterManager.getCIImageWithLanczosScaleTransformFilter(inputImage: mixedDisplacementCIImage,
                                                                                                 scaleFactor: 4)
                else { return }
                
                // ниже всё остается неизменным
                let extent = videoCIImage.extent
                let outputPixelBuffer = createCVPixelBuffer(forImage: finalCIImage, size: extent.size, context: ciContext)
                
                if let outputPixelBuffer = outputPixelBuffer {
                    while !imageBufferAdaptor.assetWriterInput.isReadyForMoreMediaData { }
                    imageBufferAdaptor.append(outputPixelBuffer, withPresentationTime: presentationTime)
                    presentationTime = CMTimeAdd(presentationTime, frameDuration)
                    debugPrint("[Create reel]: FRAME NUMBER - \(frameNumber)")
                    frameNumber += 1
                }
            }
        }
        
        outputVideoInput.markAsFinished()
        await outputWriter?.finishWriting()
        videoReader?.cancelReading()
        overlayReaders.forEach {
            $0?.cancelReading()
        }
        
        return outputLink
    }
}






//    MARK: - Clones effect, cutout object
extension CICreationVideoManager {
    /*
    func applyClonesEffectToComp(assetURL: URL) async throws -> URL {
        let videoAsset = AVAsset(url: assetURL)
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
        
        var cutoutObject: CIImage?
        
        while frameNumber < (Int(videoFrame) * fps) {
            
            guard let videoCIImage = getCIImage(with: videoOutput)
            else { break }
            
            func recordingProcessedFrame(outputPixelBuffer: CVPixelBuffer?) {
                if let outputPixelBuffer = outputPixelBuffer {
                    while !imageBufferAdaptor.assetWriterInput.isReadyForMoreMediaData { }
                    imageBufferAdaptor.append(outputPixelBuffer, withPresentationTime: presentationTime)
                    presentationTime = CMTimeAdd(presentationTime, frameDuration)
                    frameNumber += 1
                    debugPrint("[Create reel]: FRAME NUMBER - \(frameNumber)")
                }
            }
            
            autoreleasepool {
                
                //   TODO: - здесь можно тестировать обработку с CutOut объектами
                switch frameNumber {
                case 0...(1 * fps):
                    
                    // remove back
                    guard let removeBackResult = removeBackground(from: videoCIImage),
                          let finalCIImage = removeBackResult.backgroundWithHole,
                          let cutoutObj = removeBackResult.objectWithoutBackground
//                          cutoutObject = cutoutObj
                    else { return }
          
//                    cutoutObject = cutoutObj
                    
                    let extent = videoCIImage.extent
                    let outputPixelBuffer = createCVPixelBuffer(forImage: finalCIImage, size: extent.size, context: ciContext)
                    
                    recordingProcessedFrame(outputPixelBuffer: outputPixelBuffer)
                    
                default:
                    
                    let extent = videoCIImage.extent
                    let outputPixelBuffer = createCVPixelBuffer(forImage: videoCIImage, size: extent.size, context: ciContext)
                    
                    frameNumber += 1
//                    recordingProcessedFrame(outputPixelBuffer: outputPixelBuffer)
                }
            }
        }
        
        outputVideoInput.markAsFinished()
        await outputWriter?.finishWriting()
        videoReader?.cancelReading()
        
        return outputLink
    }
    
    private func removeBackground(from ciImage: CIImage) -> (backgroundWithHole: CIImage?, objectWithoutBackground: CIImage?)? {
        // Размер, к которому будет приведено изображение для работы с моделью
        let targetSize = CGSize(width: 320, height: 320)
        
        let context = CIContext(options: nil)
        
        // Создание уменьшенной версии изображения для обработки в модели
        guard let resizedImage = ciImage.resize(to: targetSize),
              let mlModel = try? u2net(),
              let resizedCGImage = context.createCGImage(resizedImage, from: resizedImage.extent),
              let resultMask = try? mlModel.prediction(input: u2netInput(inputWith: resizedCGImage)).out_p1 else {
            return nil
        }
        
        // Маска результата из модели
        var maskImage = CIImage(cvPixelBuffer: resultMask)
        
        // Масштабирование маски до размеров исходного изображения
        let scaleX = ciImage.extent.width / maskImage.extent.width
        let scaleY = ciImage.extent.height / maskImage.extent.height
        maskImage = maskImage.transformed(by: .init(scaleX: scaleX, y: scaleY))
        
        // Вырезанный объект (без фона)
        guard let objectWithoutBackground = filterManager.getCIImageBlendWithRedMask(inputImage: ciImage, maskImage: maskImage)
        else { return nil }
        
        // Фон с "черной дыркой" от вырезанного объекта
        let backgroundWithHole = filterManager.createBackgroundWithoutObject(from: ciImage, maskImage: maskImage)
        
        return (backgroundWithHole, objectWithoutBackground)
    }
     */
}

// MARK: - вспомогательные методы
extension CICreationVideoManager {
    
    //    MARK: - Get OutputVideoInput
    private func getOutputVideoInput() -> AVAssetWriterInput {
        let outputSettings: [String : Any] = [
            AVVideoCodecKey: ciSettingsModel.videoCodecType,
            AVVideoWidthKey: ciSettingsModel.videoResolution.width,
            AVVideoHeightKey: ciSettingsModel.videoResolution.height
        ]
        
        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: outputSettings)
        videoInput.expectsMediaDataInRealTime = true
        return videoInput
    }
    
    //    MARK: - Get VideoOutput
    private func getVideoOutput(videoTrack: AVAssetTrack) -> AVAssetReaderTrackOutput {
        let readersSettings: [String : Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
        ]
        
        return AVAssetReaderTrackOutput(track: videoTrack, outputSettings: readersSettings)
    }
    
    //    MARK: - Get ImageBufferAdaptor
    private func getImageBufferAdaptor(outputVideoInput: AVAssetWriterInput) -> AVAssetWriterInputPixelBufferAdaptor {
        AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: outputVideoInput, sourcePixelBufferAttributes: nil)
    }
    
    //    MARK: - Get CIImage
    private func getCIImage(with videoOutput: AVAssetReaderTrackOutput) -> CIImage? {
        guard let sampleBuffer = videoOutput.copyNextSampleBuffer() else {
            debugPrint("[RAVideoGeneratorProtocol]: ERROR - cant copyNextSampleBuffer")
            return nil
        }
        guard let pixelBuffer = sampleBuffer.imageBuffer else {
            debugPrint("[RAVideoGeneratorProtocol]: cannot create pixel buffers")
            if CMSampleBufferGetDataBuffer(sampleBuffer) != nil {
                debugPrint("[RAVideoGeneratorProtocol]: got data buffer")
            }
            return nil
        }
        CMSampleBufferInvalidate(sampleBuffer)
        
        return CIImage(cvPixelBuffer: pixelBuffer)
    }

    //    MARK: - Create CVPixelBuffer
    private func createCVPixelBuffer(forImage image: CIImage, size: CGSize, context: CIContext) -> CVPixelBuffer? {
        var cvPixelBuffer: CVPixelBuffer?
        let attributes: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
            kCVPixelBufferMetalCompatibilityKey as String: true,
            kCVPixelBufferOpenGLCompatibilityKey as String: true
        ]
        
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(size.width),
            Int(size.height),
            kCVPixelFormatType_32BGRA,
            attributes as CFDictionary,
            &cvPixelBuffer
        )
        
        guard status == kCVReturnSuccess, let pixelBuffer = cvPixelBuffer 
        else { return nil }
        
        context.render(image, to: pixelBuffer)
        
        return pixelBuffer
    }
}
