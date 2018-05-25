//
//  InitialViewController.swift
//  Watson+CoreML
//
//  Created by Abinesh Solairaj on 26/03/18.
//  Copyright © 2018 Abinesh Solairaj. All rights reserved.
//

import UIKit
import CoreML
import ImageIO
import Vision
import VisualRecognitionV3

var classifierIDs = [String]()
var image: UIImage?
var classifierId = "ModelForCableType_1174562824"

var visualRecognition: VisualRecognition!

class InitialViewController: UIViewController {
    
    let apiKey = "b190cf5ced362c6c897d1361147713b274b708eb"
    let versionAPI = "2017-12-07"
    
    
    
    @IBOutlet weak var scanImageButton: UIButton!
    @IBOutlet weak var syncModelButton: UIButton!
    
    @IBAction func scanImageTapped(_ sender: UIButton) {
        image = nil
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            presentPhotoPicker(sourceType: .photoLibrary)
            return
        }
        
        let photoSourcePicker = UIAlertController()
        let takePhoto = UIAlertAction(title: "Take Photo", style: .default) { [unowned self] _ in
            self.presentPhotoPicker(sourceType: .camera)
        }
        let realTime = UIAlertAction(title: "Real Time", style: .default) { [unowned self] _ in
            self.performSegue(withIdentifier: "selectModel", sender: nil)
        }
        let choosePhoto = UIAlertAction(title: "Gallery", style: .default) { [unowned self] _ in
            self.presentPhotoPicker(sourceType: .photoLibrary)
        }
        
        photoSourcePicker.addAction(takePhoto)
        photoSourcePicker.addAction(realTime)
        photoSourcePicker.addAction(choosePhoto)
        photoSourcePicker.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(photoSourcePicker, animated: true)
        
    }
    
    @IBAction func syncModelButtonTapped(_ sender: UIButton) {
        self.invokeModelUpdate(completion: {
            
        })
    }
    
    
    
    func presentPhotoPicker(sourceType: UIImagePickerControllerSourceType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = sourceType
        present(picker, animated: true)
    }
    
    func invokeModelUpdate(completion: ()->()){
        let failure = { (error: Error) in
            print(error)
            let descriptError = error as NSError
            DispatchQueue.main.async {
                SwiftSpinner.hide()
            }
        }
        
        let success = {
            DispatchQueue.main.async {
                SwiftSpinner.hide()
            }
        }
        
        SwiftSpinner.show("Compiling model...")
        
        visualRecognition.updateLocalModel(classifierID: classifierId, failure: failure, success: success)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        visualRecognition = VisualRecognition(apiKey: apiKey, version: versionAPI)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let localModels = try? visualRecognition.listLocalModels()
        if let models = localModels, models.count > 0{
            classifierIDs = localModels!
        } else {
            self.invokeModelUpdate(completion: {
                let localModels = try? visualRecognition.listLocalModels()
                if let models = localModels, models.count > 0{
                    classifierIDs = localModels!
                }
            })
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if segue.identifier == "selectModel"{
//
//        }
//    }
    
    
}


extension InitialViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // MARK: - Handling Image Picker Selection
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {
        picker.dismiss(animated: true)
        // We always expect `imagePickerController(:didFinishPickingMediaWithInfo:)` to supply the original image.
        image = info[UIImagePickerControllerOriginalImage] as? UIImage
        if classifierIDs.count > 0{
            performSegue(withIdentifier: "selectModel", sender: nil)
        }else{
            
        }
    }
}
