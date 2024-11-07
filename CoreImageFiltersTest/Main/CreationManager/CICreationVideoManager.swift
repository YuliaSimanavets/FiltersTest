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
    let cutoutManager: CICutoutObjectManager
    
    init(filterManager: CIFilterManager, cutoutManager: CICutoutObjectManager) {
        self.filterManager = filterManager
        self.cutoutManager = cutoutManager
    }
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
