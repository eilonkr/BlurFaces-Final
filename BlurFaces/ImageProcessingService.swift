//
//  ImageProcessingService.swift
//  BlurFaces
//
//  Created by Eilon Krauthammer on 13/05/2022.
//

import UIKit

class ImageProcessingService {
    
    private let ciContext = CIContext()
    private lazy var ciDetector = CIDetector(ofType: CIDetectorTypeFace, context: ciContext)!
    
    func getFaceRects(in image: UIImage, normalizedTo rect: CGRect) -> [CGRect] {
        guard var ciImage = CIImage(image: image) else {
            print("Couldn't create CIImage.")
            return []
        }
        
        // correct the orientation becuase `CIImage.init` can lose it
        ciImage = ciImage.oriented(.init(image.imageOrientation))
        
        let scaleFactorX = rect.width / ciImage.extent.width
        let scaleFactorY = rect.height / ciImage.extent.height
        
        var normalizedRects: [CGRect] = []
        
        // request the results from our detector
        for faceFeature in ciDetector.features(in: ciImage) {
            // every `CIFeature` has a `bounds` property, which is relative to the image dimensions.
            // keep in mind that we work here in CoreImage's coordinate system, meaning that the origin
            // is bottom left, instead of UIKit's top left.
            let faceRect = faceFeature.bounds
            
            // normalize the face feature bounds to the given rect
            let normalizedRect = CGRect(x: faceRect.minX * scaleFactorX,
                                        y: rect.height - (faceRect.maxY * scaleFactorY),
                                        width: faceRect.width * scaleFactorX,
                                        height: faceRect.height * scaleFactorY)
            normalizedRects.append(normalizedRect)
        }
        
        return normalizedRects
    }
    
    func blurFaces(in image: UIImage) -> UIImage? {
        guard let ciImage = CIImage(image: image)?
            .oriented(.init(image.imageOrientation)) else {
            return nil
        }

        // this image will use as a "map" to where
        var maskCanvasImage = CIImage.empty()
            .cropped(to: ciImage.extent)
        
        // request the features from `CIDetector`
        for faceFeature in ciDetector.features(in: ciImage) {
            let faceRect = faceFeature.bounds
            
            // position the mask in the center of the face rect, relative to the image extent.
            let maskCenter = CIVector(x: faceRect.maxX - (faceRect.width/2),
                                      y: faceRect.maxY - (faceRect.height/2))
            
            let radialGradientFilter = CIFilter(name: "CIRadialGradient", parameters: [
                "inputCenter": maskCenter,
                "inputRadius0": faceRect.height/2,
                "inputRadius1": faceRect.height,
                "inputColor0": CIColor.white,
                "inputColor1": CIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.0)
            ])
            
            if let gradientOutput = radialGradientFilter?.outputImage?
                .cropped(to: faceRect.insetBy(dx: -faceRect.width/2, dy: -faceRect.height/2)) {
                
                // "append" the new mask to our mask map
                maskCanvasImage = gradientOutput.composited(over: maskCanvasImage)
            }
        }
        
        // create the blurred copy of the image
        let blurRadius: Double = 30.0
        let blurredImage = ciImage
            .clampedToExtent()
            .applyingGaussianBlur(sigma: blurRadius)
            .cropped(to: ciImage.extent)
        
        // this is where the magic happens -
        // mask the blurred image with our mask map, over the original image
        let resultImage = blurredImage.applyingFilter("CIBlendWithMask", parameters: [
            kCIInputBackgroundImageKey: ciImage,
            kCIInputMaskImageKey: maskCanvasImage
        ])
        
        // create the final image and return it.
        if let cgImage = ciContext.createCGImage(resultImage, from: resultImage.extent) {
            return UIImage(cgImage: cgImage)
        }
            
        return nil
    }
}
