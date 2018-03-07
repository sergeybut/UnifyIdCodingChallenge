//
//  ViewController.swift
//  Unify.IDChallenge
//
//  Created by Serhii Butenko on 3/7/18.
//  Copyright © 2018 Serhii Butenko. All rights reserved.
//

import UIKit
import CameraManager
import KeychainAccess

final class LoginViewController: UIViewController {
    
    @IBOutlet weak var authenticateButton: UIButton!
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var activityLabel: UILabel!
    
    private let cameraManager = CameraManager()
    private let keychain = Keychain(service: "Sergey.Unify-IDChallenge")
    
    private var timeFiredCount = 0
    
    private var arrayOfImages = [UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        //customize take a picture button
        cameraManager.cameraDevice = .front
        cameraManager.cameraOutputMode = .stillImage
        cameraManager.cameraOutputQuality = .high
        cameraManager.writeFilesToPhoneLibrary = false
        _ = cameraManager.addPreviewLayerToView(cameraView)
        
        cameraView.isHidden = true
        
        activityLabel.text = "Ready to use."
        self.activityIndicator.stopAnimating()
        self.activityIndicator.isHidden = true
    }
    
    @IBAction func authenticateButtonPressed(_ sender: UIButton) {
        cameraView.isHidden = false
        timeFiredCount = 0
        arrayOfImages.removeAll()
        
        for i in 0..<10 {
            self.runWithDelay(0.5 * Double(i)) { [unowned self] in
                self.cameraManager.capturePictureWithCompletion({ (image, error) -> Void in
                    self.timeFiredCount += 1
                    self.arrayOfImages.append(image!)
                    self.keychain[data: "photo\(self.timeFiredCount)"] = UIImagePNGRepresentation(image!)
                    
                    if self.timeFiredCount == 10 {
                        self.processInput()
                    }
                })
            }
            
        }
    }
    
    private func processInput() {
        storeDataWithEncription(array: arrayOfImages)
    }
    
    private func storeDataWithEncription(array: [UIImage]) {
        assert(arrayOfImages.count == 10)
        
        cameraView.isHidden = true
        
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        
        self.activityLabel.text = "Saving..."
        authenticateButton.isEnabled = false
        
        DispatchQueue.global(qos: .background).async {
            for (index, image) in self.arrayOfImages.enumerated() {
                if let data = UIImagePNGRepresentation(image) {
                    self.keychain[data: "photo-\(index)"] = data
                }
                
                if index == 9 {
                    DispatchQueue.main.async {
                        self.activityIndicator.stopAnimating()
                        self.activityIndicator.isHidden = true
                        self.activityLabel.text = "Data has been saved"
                        self.authenticateButton.isEnabled = true
                    }
                }
            }
        }
    }
    
    private func runWithDelay(_ seconds: Double, completion: @escaping () -> ()) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            completion()
        }
    }
}

