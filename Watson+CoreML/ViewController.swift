//
//  ViewController.swift
//  Watson+CoreML
//
//  Created by Abinesh Solairaj on 22/03/18.
//  Copyright © 2018 Abinesh Solairaj. All rights reserved.
//

import UIKit
import CoreML
import AVFoundation
import ImageIO
import Vision
import VisualRecognitionV3

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate/*, UIPickerViewDelegate, UIPickerViewDataSource */{
    
    
    var previewLayer :AVCaptureVideoPreviewLayer? = nil
    let session = AVCaptureSession()
    
    
    //IBOutlets
    @IBOutlet weak var classifierLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var selectedModelLabel: UILabel!
    @IBOutlet weak var videoView: UIView!
    
    
    
    func invokeModelUpdate(){
        let failure = { (error: Error) in
            print(error)
            let descriptError = error as NSError
            DispatchQueue.main.async {
                self.selectedModelLabel.text = descriptError.code == 401 ? "Error updating model: Invalid Credentials" : "Error updating model"
                SwiftSpinner.hide()
            }
        }
        
        let success = {
            DispatchQueue.main.async {
                self.selectedModelLabel.text = "Current Model: \(classifierId)"
                SwiftSpinner.hide()
            }
        }
        
        SwiftSpinner.show("Compiling model...")
        
        visualRecognition.updateLocalModel(classifierID: classifierId, failure: failure, success: success)
    }
    
    // Function to show an alert with an alert Title String and alertMessage String
    func showAlert(_ alertTitle: String, alertMessage: String) {
        let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func classifyImage(for image: UIImage, localThreshold: Double = 0.0) {
        
        classifierLabel.text = "Classifying..."
        
        let failure = { (error: Error) in
            self.showAlert("Could not classify image", alertMessage: error.localizedDescription)
        }
        
        visualRecognition.classifyWithLocalModel(image: image, classifierIDs: [classifierId], threshold: localThreshold, failure: failure) { classifiedImages in
            
            var topClassification = ""
            
            if classifiedImages.images.count > 0 && classifiedImages.images[0].classifiers.count > 0 && classifiedImages.images[0].classifiers[0].classes.count > 0 {
                topClassification = classifiedImages.images[0].classifiers[0].classes[0].className
            } else {
                topClassification = "Unrecognized"
            }
            
            // Update UI on main thread
            DispatchQueue.main.async {
                // Display top classification ranked by confidence in the UI.
                self.classifierLabel.text = "\(topClassification)"
            }
        }
    }
    
    func setupCamera() {
        let availableCameraDevices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back)
        
        var activeDevice: AVCaptureDevice?
        
        for device in availableCameraDevices.devices as [AVCaptureDevice]{
            if device.position == .back {
                activeDevice = device
                break
            }
        }
        
        do {
            let camInput = try AVCaptureDeviceInput(device: activeDevice!)
            
            if session.canAddInput(camInput) {
                session.addInput(camInput)
            }
        } catch {
            print("no camera")
        }
        
        //        guard cameraAuthentication() else {return}
        
        let videoOutput = AVCaptureVideoDataOutput()
        
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "buffer queue", qos: .userInteractive, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil))
        
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        let bounds = videoView!.layer.bounds
        previewLayer!.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewLayer!.bounds = bounds
        previewLayer!.position = CGPoint(x: bounds.size.width/2, y: bounds.size.height/2)
        self.videoView!.layer.addSublayer(previewLayer!)
        
        session.startRunning()
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Note: Pixel buffer is already correctly rotated based on device rotation
        // See: deviceOrientationDidChange(_:) comment
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        let ciImage: CIImage = CIImage(cvImageBuffer: pixelBuffer)
        let analyzeImage: UIImage = self.convert(ciImage: ciImage)
        classifyImage(for: analyzeImage, localThreshold: 0.8)
    }
    
    func convert(ciImage:CIImage) -> UIImage{
        let context: CIContext = CIContext.init(options: nil)
        let cgImage: CGImage = context.createCGImage(ciImage, from: ciImage.extent)!
        let image: UIImage = UIImage.init(cgImage: cgImage)
        return image
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if image != nil{
            imageView.isHidden = false
            videoView.isHidden = true
            self.imageView.image = image
            classifyImage(for: image!, localThreshold: 0.2)
        }else{
            videoView.isHidden = false
            imageView.isHidden = true
            self.setupCamera()
        }
        self.selectedModelLabel.text = "Selected Model: \(classifierId)"
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

extension CGImagePropertyOrientation {
    /**
     Converts a `UIImageOrientation` to a corresponding
     `CGImagePropertyOrientation`. The cases for each
     orientation are represented by different raw values.
     
     - Tag: ConvertOrientation
     */
    init(_ orientation: UIImageOrientation) {
        switch orientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        }
    }
}

