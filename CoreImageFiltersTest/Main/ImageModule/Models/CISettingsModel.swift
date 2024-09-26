//
//  CISettingsModel.swift
//  FiltersTest
//
//  Created by Yuliya on 16/09/2024.
//

import AVFoundation

struct CISettingsModel: Codable {
    var videoResolution: CGSize = CGSize(width: 1080, height: 1920)
    var fpsRate: Int32 = 30
    var videoCodecType: AVVideoCodecType = .h264
    var completedVideoFileName = UUID().uuidString
    var videoBox = "mp4"
    
    func getFpsRatio() -> Int {
        return fpsRate == 30 ? 1 : 2
    }
    
    func getFrames(frames: Int64) -> Int64 {
        return frames * Int64(getFpsRatio())
    }
}

extension AVVideoCodecType: Codable {}
