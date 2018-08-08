//
//  ViewController.swift
//  FaceFinder
//
//  Created by Caleb Stultz on 8/8/18.
//  Copyright © 2018 Caleb Stultz. All rights reserved.
//

import UIKit
import Photos
import Vision

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var indicatorLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        spinner.hidesWhenStopped = true
        setupImageView()
    }
    
    // MARK: Setup Image View
    fileprivate func setupImageView() {
        guard let image = UIImage(named: "face") else { return }
        
        guard let cgImage = image.cgImage else {
            print("UIImage has no CGImage")
            return
        }
        
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        
        let scaledHeight = view.frame.width / image.size.width * image.size.height
        
        imageView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: scaledHeight)
        view.addSubview(imageView)
        
        spinner.startAnimating()
        
        DispatchQueue.global(qos: .background).async {
            self.performVisionRequest(image: cgImage, withScaledHeight: scaledHeight)
        }
    }

    // MARK: Vision Request
    func performVisionRequest(image: CGImage, withScaledHeight scaledHeight: CGFloat) {
        
        let faceDetectionRequest = VNDetectFaceRectanglesRequest { (request, error) in
            if let error = error {
                print("Failed to detect faces:", error)
                return
            }
            
            request.results?.forEach({ (result) in
                guard let faceObservation = result as? VNFaceObservation else { return }
                
                DispatchQueue.main.async {
                    let width = self.view.frame.width * faceObservation.boundingBox.width
                    let height = scaledHeight * faceObservation.boundingBox.height
                    let x = self.view.frame.width * faceObservation.boundingBox.origin.x
                    let y = scaledHeight * (1 - faceObservation.boundingBox.origin.y) - height
                    
                    let yellowView = UIView()
                    yellowView.backgroundColor = .clear
                    yellowView.layer.borderColor = UIColor.yellow.cgColor
                    yellowView.layer.borderWidth = 3
                    yellowView.layer.cornerRadius = 5
                    yellowView.alpha = 0.0
                    yellowView.frame = CGRect(x: x, y: y, width: width, height: height)
                    self.view.addSubview(yellowView)
                    
                    UIView.animate(withDuration: 0.3, animations: {
                        yellowView.alpha = 0.75
                        self.spinner.alpha = 0.0
                        self.indicatorLabel.alpha = 0.0
                    })
                    
                    self.spinner.stopAnimating()
                }
            })
        }
        
        let imageRequestHandler = VNImageRequestHandler(cgImage: image, options: [:])

        do {
            try imageRequestHandler.perform([faceDetectionRequest])
        } catch {
            print("Failed to perform image request: \(error.localizedDescription)")
            return
        }
    }
}
