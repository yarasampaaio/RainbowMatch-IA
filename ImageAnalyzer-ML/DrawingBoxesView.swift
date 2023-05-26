//
//  DrawingBoxesView.swift
//  ImageAnalyzer-ML
//
//  Created by Narely Lima on 11/05/23.
//  Copyright © 2023 Priya Talreja. All rights reserved.
//

import UIKit
import Vision

final class DrawingBoxesView: UIView {

    func drawBox(with predictions: [VNRecognizedObjectObservation]) -> CGRect {

        layer.sublayers?.forEach {
            $0.removeFromSuperlayer()
        }

        var rect: CGRect = .zero

        predictions.forEach {
            rect = drawBox(with: $0)
        }

        return rect
    }

    private func drawBox(with prediction: VNRecognizedObjectObservation) -> CGRect {
        let scale = CGAffineTransform.identity.scaledBy(x: bounds.width, y: bounds.height)
        print("Scale vale: \(scale)")
        let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -1)
        print("Transform vale: \(transform)")
        let rectangle = prediction.boundingBox.applying(transform).applying(scale)
        print("Rectangle vale: \(rectangle)")
        let newlayer = CALayer()
        newlayer.frame = rectangle
        print("newlayer vale: \(newlayer)")
        
        print("red box ratio:", rectangle.height/rectangle.width)

        newlayer.backgroundColor = UIColor.clear.cgColor
        newlayer.borderColor = UIColor.red.cgColor
        newlayer.borderWidth = 2
        newlayer.cornerRadius = 4

        layer.addSublayer(newlayer)

        return rectangle
    }
}
