//
//  VHS.swift
//  CoreImageFiltersTest
//
//  Created by Yuliya on 27/09/2024.
//

import AVFoundation
import PhotosUI

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
