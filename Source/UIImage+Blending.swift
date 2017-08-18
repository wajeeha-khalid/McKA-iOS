//
//  UIImage+Blending.swift
//  edX
//
//  Created by Salman Jamil on 7/17/17.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit
import QuartzCore

extension UIImage {
    static func image(from color: UIColor, size: CGSize) -> UIImage {
        let bounds = CGRect(origin: CGPoint.zero, size: size)
        UIGraphicsBeginImageContext(size)
        guard let context = UIGraphicsGetCurrentContext() else {
            fatalError("Could not obtain a context")
        }
        context.setFillColor(color.cgColor)
        context.fill(bounds)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
    func blendendImage(with image: UIImage, blendMode: CGBlendMode, alpha: CGFloat) -> UIImage {
        UIGraphicsBeginImageContext(size)
        let bounds = CGRect(origin: .zero, size: size)
        draw(in: bounds)
        image.draw(in: bounds, blendMode: blendMode, alpha: alpha)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}

