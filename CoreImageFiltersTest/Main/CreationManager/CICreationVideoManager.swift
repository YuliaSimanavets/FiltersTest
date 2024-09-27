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
    
    let ciSettingsModel = CISettingsModel()
    let filterManager: CIFilterManager
    
    init(filterManager: CIFilterManager) {
        self.filterManager = filterManager
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
    func getOutputVideoInput() -> AVAssetWriterInput {
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
    func getVideoOutput(videoTrack: AVAssetTrack) -> AVAssetReaderTrackOutput {
        let readersSettings: [String : Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
        ]
        
        return AVAssetReaderTrackOutput(track: videoTrack, outputSettings: readersSettings)
    }
    
    //    MARK: - Get ImageBufferAdaptor
    func getImageBufferAdaptor(outputVideoInput: AVAssetWriterInput) -> AVAssetWriterInputPixelBufferAdaptor {
        AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: outputVideoInput, sourcePixelBufferAttributes: nil)
    }
    
    //    MARK: - Get CIImage
    func getCIImage(with videoOutput: AVAssetReaderTrackOutput) -> CIImage? {
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
    func createCVPixelBuffer(forImage image: CIImage, size: CGSize, context: CIContext) -> CVPixelBuffer? {
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
