//
//  Cut.swift
//  CoreImageFiltersTest
//
//  Created by Yuliya on 12/11/2024.
//

import AVFoundation
import PhotosUI

// MARK: - Cut effect (model DeepLabV3)
extension CICreationVideoManager {
    func applyCutEffectToComp(assetURL: URL) async throws -> URL? {

        guard let maskFileURL = Bundle.main.path(forResource: "Stroke-Animation-Mask", ofType: "mp4")
        else { return nil}
        let overlayURL = URL(fileURLWithPath: maskFileURL)

        let videoAsset = AVAsset(url: assetURL)
        let videoReader = try? AVAssetReader(asset: videoAsset)
        guard let videoTrack = try! await videoAsset.loadTracks(withMediaType: .video).first else {
            throw CITestingError.noVideoTrack("Track missing in video")
        }
        
        let overlayAsset = AVAsset(url: overlayURL)
        let overlayReader = try? AVAssetReader(asset: overlayAsset)
        guard let overlayTrack = try? await overlayAsset.loadTracks(withMediaType: .video).first else {
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
        
        let overlayOutput = getVideoOutput(videoTrack: overlayTrack)
        overlayReader?.add(overlayOutput)
        
        let imageBufferAdaptor = getImageBufferAdaptor(outputVideoInput: outputVideoInput)
        let ciContext = CIContext()
        
        videoReader?.startReading()
        overlayReader?.startReading()
        
        outputWriter?.startWriting()
        outputWriter?.startSession(atSourceTime: .zero)
        
        let frameDuration = CMTime(value: 1, timescale: ciSettingsModel.fpsRate)
        var presentationTime: CMTime = .zero
        
        var frameNumber = 0
        var timeForAnimation = 0.0
        
        let videoDuration = try! await videoAsset.load(.duration)
        let videoFrameRate = try! await videoTrack.load(.nominalFrameRate)
        let videoFrame = videoDuration.seconds * Double(videoFrameRate)
        let fps = ciSettingsModel.getFpsRatio()

        func recordingProcessedFrame(outputPixelBuffer: CVPixelBuffer?, completion: (() -> Void)?) {
            if let outputPixelBuffer = outputPixelBuffer {
                while !imageBufferAdaptor.assetWriterInput.isReadyForMoreMediaData { }
                imageBufferAdaptor.append(outputPixelBuffer, withPresentationTime: presentationTime)
                presentationTime = CMTimeAdd(presentationTime, frameDuration)
                completion?()
                debugPrint("[Create]: FRAME NUMBER - \(frameNumber)")
            }
        }
        
        while frameNumber < (Int(videoFrame) * fps) {
            
            guard let videoCIImage = getCIImage(with: videoOutput),
                  let maskCIImage = getCIImage(with: overlayOutput)
            else { break }
            
            func linear(time: Float, startValue: Float, change: Float, duration: Float) -> Float {
                return change * time / duration + startValue
            }
            
            autoreleasepool {
                                
                let cutoutResult = cutoutManager.getCutoutObjects(inputImage: videoCIImage)
                guard let cutoutObject = cutoutResult.objectImage
                else { return }
                
                // step 1: 1.1-сut-Blur-Bright (originalCutoutObject + Blur + Bright + Exposure)
                guard let blurredCIImage = filterManager.getCIImageWithBoxBlur(inputImage: cutoutObject, radius: 15),
                      let filteredCIImage = filterManager.getCIImageWithColorControlsFilter(inputImage: blurredCIImage, brightness: 1, contrast: 0.5)
                else { return }
                
                // step 2: add mask to 1.1
                guard let maskedCIImage = filterManager.getCIImageBlendWithMask(inputImage: filteredCIImage,
                                                                                backgroundImage: cutoutObject,
                                                                                maskImage: maskCIImage),
                      let mixedCIImage = filterManager.getCIImageSourceOverCompositing(image: maskedCIImage,
                                                                                       background: videoCIImage),
                      let finalCIImage = filterManager.getCIImageSourceOverCompositing(image: cutoutObject,
                                                                                       background: mixedCIImage)
                else { return }
                        
                // step 3: originalCutoutObject + pазмытие краев = 25px
                // step 4: 1.3-сut-Light-AnimationExpand
                // step 5: 1.4-сut-Normal-AnimationExpand

                
                let extent = videoCIImage.extent
                let outputPixelBuffer = createCVPixelBuffer(forImage: finalCIImage, size: extent.size, context: ciContext)
                
                recordingProcessedFrame(outputPixelBuffer: outputPixelBuffer) {
                    frameNumber += 1
                }
            }
        }
    
        outputVideoInput.markAsFinished()
        await outputWriter?.finishWriting()
        videoReader?.cancelReading()
        overlayReader?.cancelReading()
        
        return outputLink
    }
}
