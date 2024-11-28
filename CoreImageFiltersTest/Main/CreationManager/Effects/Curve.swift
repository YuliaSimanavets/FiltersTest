//
//  Curve.swift
//  CoreImageFiltersTest
//
//  Created by Yuliya on 27/09/2024.
//

import AVFoundation
import PhotosUI

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
                let points = CurvePoints(photoshopPoint0: .init(x: 0.06, y: 0),
                                         photoshopPoint1: .init(x: 0.234, y: 0.26),
                                         photoshopPoint2: .init(x: 0.48, y: 0.53),
                                         photoshopPoint3: .init(x: 0.75, y: 0.7),
                                         photoshopPoint4: .init(x: 1, y: 0.78))
                
                guard let finalCIImage = filterManager.getCIImageWithToneCurveFilter(inputImage: videoCIImage
//                                                                                     points: points
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
