//
//  ExperiencesViewController.swift
//  MediaProgramming
//
//  Created by Yvette Zhukovsky on 1/18/19.
//  Copyright © 2019 Yvette Zhukovsky. All rights reserved.
//
import Photos
import MapKit
import UIKit
import CoreImage

class ExperiencesViewController: UIViewController,UITextFieldDelegate {

    @IBOutlet var titleText: UITextField!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var addImageButton: UIButton!
    @IBOutlet var recordButton: UIButton!
    
    private var recorder: AVAudioRecorder?
    var experiencesController: ExperiencesController?
    var coordinate: CLLocationCoordinate2D?
    
    private let context = CIContext(options: nil)

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleText.delegate = self
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func updateViews() {
        guard isViewLoaded else { return }
        
        let isRecording = recorder?.isRecording ?? false
        let recordButtonTitle = isRecording ? "Stop recording" : "Record Audio"
        recordButton.setTitle(recordButtonTitle, for: .normal)
    }
    
    @IBAction func recording(_ sender: Any) {
        let isRecording = recorder?.isRecording ?? false
        if isRecording {
            endRecording()
        } else {
            beginRecording()
        }
    }
    
    func makeBlackWhite(img: UIImage) -> UIImage? {
        guard  let cgImage = img.cgImage  else {return nil}
        let imageFilter = CIFilter(name: "CIPhotoEffectNoir")!

        let ciImage = CIImage(cgImage: cgImage)
        imageFilter.setValue(ciImage, forKey: "inputImage")
        
        guard let outputCIimage = imageFilter.outputImage,
            let outputCGImage = context.createCGImage(outputCIimage, from: outputCIimage.extent) else {return nil}
        return UIImage(cgImage: outputCGImage)
        
    }
    
//    private var imageData: UIImage?{
//        didSet{
//
//            applyFilter()
//        }
//    }
    
    
    
    private func newRecordingURL() -> URL {
        let fm = FileManager.default
        let documentsDir = try! fm.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return documentsDir.appendingPathComponent(UUID().uuidString).appendingPathExtension("caf")
    }
    
    private func beginRecording() {
        do {
            let format = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 1)!
            recorder = try AVAudioRecorder(url: newRecordingURL(), format: format)
            recorder?.record()
            updateViews()
        } catch {
            NSLog("Error beginning the recording...")
        }
    }
    
    private func endRecording() {
        recorder?.stop()
        updateViews()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showVideo" {
            guard let url = recorder?.url,
                let imageData = imageView.image,
                let coordinate = self.coordinate else { return }
            
            if let vc = segue.destination as? VideoViewController {
                vc.audioURL = url
                vc.imageData = imageData
                vc.experienceTitle = titleText.text
                vc.experiencesController = experiencesController
                vc.coordinate = coordinate
            }
        }
    }
}

extension ExperiencesViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        addImageButton.setTitle("", for: [])
        picker.dismiss(animated: true, completion: nil)
        guard let imageData = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return }
        
        imageView?.image = makeBlackWhite(img: imageData)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    private func presentInformationalAlertController(title: String?, message: String?, dismissActionCompletion: ((UIAlertAction) -> Void)? = nil, completion: (() -> Void)? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: dismissActionCompletion)
        
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: completion)
    }
    
    private func presentImagePickerController() {
        
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            presentInformationalAlertController(title: "Error", message: "The photo library is unavailable")
            return
        }
        
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func choosePhoto(_ sender: Any) {
        let authorizationStatus = PHPhotoLibrary.authorizationStatus()
        
        switch authorizationStatus {
        case .authorized:
            presentImagePickerController()
        case .notDetermined:
            
            PHPhotoLibrary.requestAuthorization { (status) in
                
                guard status == .authorized else {
                    NSLog("User did not authorize access to the photo library")
                    self.presentInformationalAlertController(title: "Error", message: "In order to access the photo library, you must allow this application access to it.")
                    return
                }
                
                self.presentImagePickerController()
            }
            
        case .denied:
            self.presentInformationalAlertController(title: "Error", message: "In order to access the photo library, you must allow this application access to it.")
        case .restricted:
            self.presentInformationalAlertController(title: "Error", message: "Unable to access the photo library. Your device's restrictions do not allow access.")
            
        }
        presentImagePickerController()
    }


   
    
    
}


