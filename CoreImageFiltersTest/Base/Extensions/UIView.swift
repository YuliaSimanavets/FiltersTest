//
//  UIView.swift
//  FiltersTest
//
//  Created by Yuliya on 11/09/2024.
//

import AVFoundation
import UIKit

extension UIView {
    func getVideoThumbnailImage(fromURL videoURL: URL?) -> UIImage? {
        guard let videoURL = videoURL else { return nil }
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        let time = CMTime(value: 75, timescale: 30)
        
        do {
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            return UIImage(cgImage: cgImage)
        } catch {
            debugPrint("Error getting video thumbnail image: \(error.localizedDescription)")
            return nil
        }
    }
}
