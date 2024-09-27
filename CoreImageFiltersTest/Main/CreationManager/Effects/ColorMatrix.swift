//
//  ColorMatrix.swift
//  CoreImageFiltersTest
//
//  Created by Yuliya on 27/09/2024.
//

import AVFoundation
import PhotosUI

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
