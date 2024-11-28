//
//  Clones + Overlays.swift
//  CoreImageFiltersTest
//
//  Created by Yuliya on 19/11/2024.
//

import AVFoundation
import PhotosUI

// MARK: - Clones effect (model DeepLabV3)
extension CICreationVideoManager {
    func applyClonesEffectWithOverlaysToComp(assetURL: URL) async throws -> URL? {

        guard let betweenOverlayFileURL = Bundle.main.path(forResource: "Clones_betweenOverlay", ofType: "mp4"),
              let endOverlayFileURL = Bundle.main.path(forResource: "Clones_endOverlay", ofType: "mp4")
        else { return nil}
        
        let overlays: [URL] = [
            URL(fileURLWithPath: betweenOverlayFileURL),
            URL(fileURLWithPath: endOverlayFileURL)
        ]
        
        var overlayTracks: [AVAssetTrack] = []
        var overlayReaders: [AVAssetReader?] = []
        var overlayOutputs: [AVAssetReaderTrackOutput] = []
        
        for i in 0..<overlays.count {
            let overlayAsset = AVAsset(url: overlays[i])
            let overlayReader = try? AVAssetReader(asset: overlayAsset)
            guard let overlayTrack = try? await overlayAsset.loadTracks(withMediaType: .video).first else {
                throw CITestingError.noVideoTrack("Track missing in video")
            }
            overlayTracks.append(overlayTrack)
            overlayReaders.append(overlayReader)
        }
        
        for i in 0..<overlays.count {
            let overlayOutput: AVAssetReaderTrackOutput
            overlayOutput = getVideoOutput(videoTrack: overlayTracks[i])
            overlayReaders[i]?.add(overlayOutput)
            overlayOutputs.append(overlayOutput)
        }
        
        overlayReaders.forEach {
            $0?.startReading()
        }
        
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
        
        let videoDuration = try! await videoAsset.load(.duration)
        let videoFrameRate = try! await videoTrack.load(.nominalFrameRate)
        let videoFrame = videoDuration.seconds * Double(videoFrameRate)
        let fps = ciSettingsModel.getFpsRatio()

        func recordingProcessedFrame(outputPixelBuffer: CVPixelBuffer?) {
            if let outputPixelBuffer = outputPixelBuffer {
                while !imageBufferAdaptor.assetWriterInput.isReadyForMoreMediaData { }
                imageBufferAdaptor.append(outputPixelBuffer, withPresentationTime: presentationTime)
                presentationTime = CMTimeAdd(presentationTime, frameDuration)
                frameNumber += 1
                debugPrint("[Create]: FRAME NUMBER - \(frameNumber)")
            }
        }
        
        while frameNumber < (Int(videoFrame) * fps) {
            
            guard let videoCIImage = getCIImage(with: videoOutput)
            else { break }

            autoreleasepool {
                switch frameNumber {
                case (0 * fps)..<(20 * fps):
                                        
                    let cutoutResult = cutoutManager.getCutoutObjects(inputImage: videoCIImage)
                    guard let cutoutObjectCIImage = cutoutResult.objectImage,
                          let betweenOverlayCIImage = getCIImage(with: overlayOutputs[0]),
                          let endOverlayCIImage = getCIImage(with: overlayOutputs[1])
                    else { return }
                    
                    guard let mixedOverlayWithOriginalCIImage = filterManager
                        .getCIImageAdditionFilter(inputImage: videoCIImage, overlayImage: betweenOverlayCIImage),
                          let mixedWithObjectCIImage = filterManager
                        .getCIImageSourceOverCompositing(image: cutoutObjectCIImage, background: mixedOverlayWithOriginalCIImage),
                          let finalCIImage = filterManager
                        .getCIImageAdditionFilter(inputImage: mixedWithObjectCIImage, overlayImage: endOverlayCIImage)
                    else { return }
                              
                    let extent = videoCIImage.extent
                    let outputPixelBuffer = createCVPixelBuffer(forImage: /*mixedWithObjectCIImage*/ finalCIImage, size: extent.size, context: ciContext)

                    recordingProcessedFrame(outputPixelBuffer: outputPixelBuffer)
                    
                default:
                    let extent = videoCIImage.extent
                    let outputPixelBuffer = createCVPixelBuffer(forImage: videoCIImage, size: extent.size, context: ciContext)
                    
                    guard let outputPixelBuffer = outputPixelBuffer else { return }
                    recordingProcessedFrame(outputPixelBuffer: outputPixelBuffer)

                }
            }
        }

        outputVideoInput.markAsFinished()
        await outputWriter?.finishWriting()
        videoReader?.cancelReading()
        
        return outputLink
    }
}
