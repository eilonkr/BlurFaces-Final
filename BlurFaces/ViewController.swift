//
//  ViewController.swift
//  BlurFaces
//
//  Created by Eilon Krauthammer on 09/05/2022.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var showRectsButton: UIBarButtonItem!
    
    var pickedImage: UIImage?
    
    var showRects: Bool = false {
        didSet {
            showRectsButton.title = showRects ? "Blur Faces" : "Show Rects"
            guard let pickedImage = pickedImage else { return }
            if showRects {
                imageView.image = pickedImage
                generateFaceBoundingBoxes(for: pickedImage)
            } else {
                blurFaces(in: pickedImage)
                debugRectContainerView.subviews.forEach {
                    $0.removeFromSuperview()
                }
            }
        }
    }
    
    private let imageProcessingService = ImageProcessingService()
    
    private lazy var imagePicker: UIImagePickerController = {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        return picker
    }()
    
    var debugRectContainerView = UIView()
    
    private var imageViewHeightConstraint: NSLayoutConstraint?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(debugRectContainerView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        debugRectContainerView.frame = imageView.frame
    }
    
    func generateFaceBoundingBoxes(for image: UIImage) {
        debugRectContainerView.subviews.forEach {
            $0.removeFromSuperview()
        }
        
        for faceRect in imageProcessingService.getFaceRects(in: image, normalizedTo: imageView.frame) {
            let rectView = UIView(frame: faceRect)
            rectView.backgroundColor = nil
            rectView.layer.borderColor = UIColor.green.cgColor
            rectView.layer.borderWidth = 1.5
            debugRectContainerView.addSubview(rectView)
        }
    }
    
    func blurFaces(in image: UIImage) {
        let resultImage = imageProcessingService.blurFaces(in: image)
        imageView.image = resultImage
    }
    
    @IBAction func pickImageTapped() {
        present(imagePicker, animated: true)
    }
    
    @IBAction func showRectsTapped(_ sender: Any) {
        showRects.toggle()
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        guard let image = info[.originalImage] as? UIImage else {
            return
        }
        
        pickedImage = image
        imageView.image = image
        
        // make sure that the image view is sized to fit the aspect ratio of the picked image,
        // so that the bounding boxes will be correcly located
        imageViewHeightConstraint?.isActive = false
        let imageRatio = image.size.width / image.size.height
        imageViewHeightConstraint = imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 1/imageRatio)
        imageViewHeightConstraint?.isActive = true
        
        view.layoutIfNeeded()
        if showRects {
            generateFaceBoundingBoxes(for: image)
        } else {
            blurFaces(in: image)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
