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
        return []
    }
    
    func blurFaces(in image: UIImage) -> UIImage? {
        return nil
    }
}
