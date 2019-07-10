//
//  ImagePostViewController.swift
//  LambdaTimeline
//
//  Created by Spencer Curtis on 10/12/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import UIKit
import Photos

class ImagePostViewController: ShiftableViewController {
    
    // MARK: - Properties
    
    var postController: PostController!
    var post: Post?
    var imageData: Data?
    var myImage: UIImage? {
        didSet {
            updateImageView()
        }
    }
    
    // MARK: - Outlets
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var chooseImageButton: UIButton!
    @IBOutlet weak var imageHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var postButton: UIBarButtonItem!
    
    // MARK: - Actions
    
    @IBAction func filter1BtnPressed(_ sender: UIButton) {
        selectedFilter = filter0
        updateImageView()
    }
    @IBAction func filter2BtnPressed(_ sender: UIButton) {
        selectedFilter = filter1
        updateImageView()
    }
    @IBAction func filter3BtnPressed(_ sender: UIButton) {
        selectedFilter = filter2
        updateImageView()
    }
    @IBAction func filter4BtnPressed(_ sender: UIButton) {
        selectedFilter = filter3
        updateImageView()
    }
    @IBAction func filter5BtnPressed(_ sender: UIButton) {
        selectedFilter = filter4
        updateImageView()
    }
    
    
    private let filter0 = CIFilter(name: "CIColorInvert")!
    private let filter1 = CIFilter(name: "CIPhotoEffectChrome")!
    private let filter2 = CIFilter(name: "CIPhotoEffectInstant")!
    private let filter3 = CIFilter(name: "CIPhotoEffectNoir")!
    private let filter4 = CIFilter(name: "CIVignette")!
    private let filter5 = CIFilter(name: "CIGloom")!
    
    private var selectedFilter: CIFilter?
    private let context = CIContext(options: nil)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setImageViewHeight(with: 1.0)
        
        updateViews()
    }
    
    private func updateImageView() {
        guard let image = myImage else { return }
        DispatchQueue.main.async {
            self.imageView?.image = self.applyFilterToImage(to: image)
        }
    }
    
    private func applyFilterToImage(to image: UIImage) -> UIImage {
        let inputImage: CIImage
        
        if let ciImage = image.ciImage {
            inputImage = ciImage
        }else if let cgImage = image.cgImage {
            inputImage = CIImage(cgImage: cgImage)
        }else {
            return image
        }
        selectedFilter?.setValue(inputImage, forKey: kCIInputImageKey)
        
        guard let outputImage = selectedFilter?.outputImage else {
            return image
        }
        
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return image
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    func updateViews() {
        
        guard let imageData = imageData,
            let image = UIImage(data: imageData) else {
                title = "New Post"
                return
        }
        
        title = post?.title
        
        setImageViewHeight(with: image.ratio)
        
        imageView.image = image
        
        chooseImageButton.setTitle("", for: [])
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
    
    @IBAction func createPost(_ sender: Any) {
        
        view.endEditing(true)
        
        guard let imageData = imageView.image?.jpegData(compressionQuality: 0.1),
            let title = titleTextField.text, title != "" else {
            presentInformationalAlertController(title: "Uh-oh", message: "Make sure that you add a photo and a caption before posting.")
            return
        }
        
        postController.createPost(with: title, ofType: .image, mediaData: imageData, ratio: imageView.image?.ratio) { (success) in
            guard success else {
                DispatchQueue.main.async {
                    self.presentInformationalAlertController(title: "Error", message: "Unable to create post. Try again.")
                }
                return
            }
            
            DispatchQueue.main.async {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    @IBAction func chooseImage(_ sender: Any) {
        
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
    
    func setImageViewHeight(with aspectRatio: CGFloat) {
        
        imageHeightConstraint.constant = imageView.frame.size.width * aspectRatio
        
        view.layoutSubviews()
    }
}

extension ImagePostViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        chooseImageButton.setTitle("", for: [])
        
        myImage = info[.originalImage] as? UIImage
        picker.dismiss(animated: true, completion: nil)
        
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return }
        
        imageView.image = image
        
        setImageViewHeight(with: image.ratio)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
