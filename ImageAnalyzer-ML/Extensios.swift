//
//  Extensios.swift
//  ImageAnalyzer-ML
//
//  Created by Narely Lima on 11/05/23.
//  Copyright © 2023 Priya Talreja. All rights reserved.
//

import UIKit

extension UIImage {
    var cgImageOrientation : CGImagePropertyOrientation
    {
        switch imageOrientation {
            case .up: return .up
            case .upMirrored: return .upMirrored
            case .down: return .down
            case .downMirrored: return .downMirrored
            case .leftMirrored: return .leftMirrored
            case .right: return .right
            case .rightMirrored: return .rightMirrored
            case .left: return .left
            default: return.up

        }
    }
}
extension CGRect {
    func convertNormalizedRect(imageSize: CGSize) -> CGRect {
        let origin = CGPoint(x: self.origin.x * imageSize.width,
                             y: self.origin.y * imageSize.height)
        let size = CGSize(width: self.size.width * imageSize.width,
                          height: self.size.height * imageSize.height)
        return CGRect(origin: origin, size: size)
        
    }
}

struct RGB: Hashable {
    let red: UInt8
    let green: UInt8
    let blue: UInt8
}

extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

extension UIImage {

    func predominantRGB() -> RGB {

        guard
            let cgImage = cgImage,
            let data = cgImage.dataProvider?.data,
            let bytes = CFDataGetBytePtr(data)
        else { return RGB(red: 0, green: 0, blue: 0) }

        var rgbs: Set<RGB> = Set<RGB>()
        var knowedRGBs: Set<RGB> = Set<RGB>()
        let bytesPerPixel = cgImage.bitsPerPixel / cgImage.bitsPerComponent

        for y in 0 ..< cgImage.height {
            for x in 0 ..< cgImage.width {
                let offset = (y * cgImage.bytesPerRow) + (x * bytesPerPixel)
                let components = RGB(
                    red: bytes[offset],
                    green: bytes[offset + 1],
                    blue:  bytes[offset + 2]
                )
                rgbs.insert(components)
                if !knowedRGBs.contains(components) { knowedRGBs.insert(components) }
            }
        }
        
        var count = 0
        var predominantRGB = RGB(red: 0, green: 0, blue: 0)
        
        for rgb in knowedRGBs {
            let currentRGBCount = rgbs.filter { $0 == rgb }.count
            if currentRGBCount > count {
                count = currentRGBCount
                predominantRGB = rgb
            }
        }
        
        return predominantRGB
    }
}
