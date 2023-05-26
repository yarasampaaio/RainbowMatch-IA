//
//  ViewController.swift
//  ImageAnalyzer-ML
//
//  Created by Priya Talreja on 26/07/19.
//  Copyright © 2019 Priya Talreja. All rights reserved.
//

import UIKit
import CoreML
import Vision
import CoreImage
import PhotosUI
import SwiftUI

class ViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var labelColor: UILabel!
    
    private var request: VNCoreMLRequest!
    
    private var drawingBoxesView = DrawingBoxesView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBoxesView()
    }
    
    private func setupBoxesView() {
        
        
        imageView.addSubview(drawingBoxesView)
        
        
        drawingBoxesView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            drawingBoxesView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            drawingBoxesView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
            drawingBoxesView.topAnchor.constraint(equalTo: imageView.topAnchor),
            drawingBoxesView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor)
        ])
        
        drawingBoxesView.isUserInteractionEnabled = false
    }
    
    func createCoreMLRequest(image: UIImage) {
        guard let cgImage = image.cgImage else {
            return
        }
        let configuration = MLModelConfiguration()
        
        guard let model = try? TShirtMLModel_2(configuration: configuration).model, let visionModel = try? VNCoreMLModel(for: model) else {
            return
        }
        self.request = VNCoreMLRequest(model: visionModel, completionHandler: { request, error in
            
            if let prediction = (request.results as? [VNRecognizedObjectObservation])?.first {
                DispatchQueue.main.async { [self] in
                    
//                    drawingBoxesView.drawBox(with: [prediction])
                    let boundingBox = prediction.boundingBox
                                                            
                    guard let cgImage = image.cgImage else {
                        return
                        
                    }
                    
                    var croppedImage: UIImage
                    
                    if image.imageOrientation == .right {
                        let uiImageSize = image.size
                        let _ = print(uiImageSize)
                        
                        print("IMAGEM VERTICAL")
                        
                        print(boundingBox)
                        
                        let rect = CGRect(
                            x: boundingBox.origin.x*uiImageSize.width,
                            y: boundingBox.origin.y*uiImageSize.height,
                            width: boundingBox.size.width*uiImageSize.width,
                            height: boundingBox.size.height*uiImageSize.height
                        )
                        
//                        let scaling = CGAffineTransform(scaleX: uiImageSize.width, y: uiImageSize.height)
                        let rotation = CGAffineTransform(rotationAngle: Angle(degrees: -90).radians)
                        let translation = CGAffineTransform(translationX: 0, y: uiImageSize.width)
                        
                        let fixedRect = rect.applying(rotation).applying(translation)
                        
                        
                        
                        croppedImage = UIImage(cgImage: cgImage.cropping(to: fixedRect)!, scale: image.scale, orientation: image.imageOrientation)
                        
                        print(fixedRect.size)
                        print(croppedImage.size)
                        
                        print("fixed rect ratio:", fixedRect.size.height/fixedRect.size.width)
                        print("bouding box ratio:", boundingBox.height/boundingBox.width)
                        print("cropped image ratio:", croppedImage.size.width/croppedImage.size.height)
                        
                    } else {
                        let uiImageSize = image.size
                        let scaledRect = boundingBox.applying(.init(scaleX: uiImageSize.width, y: uiImageSize.height))
                        
                        croppedImage = cropImage(image, toRect: scaledRect)!
                        
//                        croppedImage = UIImage(cgImage: cgImage.cropping(to: scaledRect)!, scale: image.scale, orientation: image.imageOrientation)
                    }
                    
                    imageView.image = croppedImage
                    imageView.contentMode = .scaleAspectFit

                    let resizedImage = croppedImage.resized(to: CGSize(width: 50, height: 50))
                    let rgb = resizedImage.predominantRGB()
                    print(rgb)
                    classify(image: croppedImage)
                    
                }
            }
        })
        
        request.imageCropAndScaleOption = .centerCrop
        
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: image.cgImageOrientation, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
    }
    
    lazy var classificationRequest: VNCoreMLRequest = {
        do {
            // 1
            let healthySnacks = MyColorClassifier4()
            // 2
            let visionModel = try VNCoreMLModel(
                for: healthySnacks.model)
            // 3
            let request = VNCoreMLRequest(model: visionModel,
                                          completionHandler: {
                request, error in
                print("Request is finished!")
                guard let results = request.results as?[VNClassificationObservation] else{return}
                guard let observassion = results.first else{return}
                print(observassion.identifier,observassion.confidence)
                
                DispatchQueue.main.async {
                    self.labelColor.text = "Cor: \(observassion.identifier), Precisão \(observassion.confidence)"
                }
            })
            // 4
            request.imageCropAndScaleOption = .centerCrop
            return request
        } catch {
            fatalError("Failed to create VNCoreMLModel: (error)")
        }
    }()
    
    func classify(image: UIImage) {
        // 1
        guard let ciImage = CIImage(image: image) else {
            print("Unable to create CIImage")
            return
        }
        // 2
        let orientation = CGImagePropertyOrientation(rawValue: UInt32(image.imageOrientation.rawValue))
        // 3
        DispatchQueue.global(qos: .userInitiated).async {
            // 4
            let handler = VNImageRequestHandler(
                ciImage: ciImage,
                orientation: orientation!)
            do {
                try handler.perform([self.classificationRequest])
            } catch {
                print("Failed to perform classification: (error)")
            }
        }
    }
    
    public func cropImage(_ image: UIImage, toRect rect: CGRect) -> UIImage? {
        let data = image.pngData()!
        let ciImage = CIImage(data: data)!
        let croppedImage = ciImage.cropped(to: rect)
        let context = CIContext(options: nil)
        guard let newImage = context.createCGImage(croppedImage, from: croppedImage.extent) else { return nil }
        return UIImage(cgImage: newImage)
    }
    
    @IBAction func photoButtonClicked(_ sender: UIButton) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            presentPhotoPicker(sourceType: .photoLibrary)
            return
        }
        let photoSourcePicker = UIAlertController()
        let takePhoto = UIAlertAction(title: "Take Photo", style: .default) { [unowned self] _ in
            self.presentPhotoPicker(sourceType: .camera)
        }
        let choosePhoto = UIAlertAction(title: "Choose Photo", style: .default) { [unowned self] _ in
            self.presentPhotoPicker(sourceType: .photoLibrary)
        }
        photoSourcePicker.addAction(takePhoto)
        photoSourcePicker.addAction(choosePhoto)
        photoSourcePicker.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(photoSourcePicker, animated: true)
    }
}


extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        
        guard let uiImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            fatalError("Error!")
        }
        
        imageView.image = uiImage
        
        createCoreMLRequest(image: uiImage)
        
    }
    
    private func presentPhotoPicker(sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = sourceType
        present(picker, animated: true)
    }
}

