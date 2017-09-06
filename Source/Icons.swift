//
//  Icons.swift
//  edX
//
//  Created by Salman Jamil on 8/30/17.
//  Copyright © 2017 edX. All rights reserved.
//

import Foundation
import CoreGraphics

fileprivate func makeCircleWith(size: CGSize, backgroundColor: UIColor) -> UIImage? {
    UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
    let context = UIGraphicsGetCurrentContext()
    context?.setFillColor(backgroundColor.cgColor)
    context?.setStrokeColor(UIColor.clear.cgColor)
    let bounds = CGRect(origin: .zero, size: size)
    context?.addEllipse(in: bounds)
    context?.drawPath(using: .fill)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image
}

func makeArrowWithCircularBackground(ofSize circleSize: CGSize, backgroundColor: UIColor, arrowWidth: CGFloat, arrowHeight: CGFloat = 2.0, arrowColor: UIColor, arrowDirection: ArrowDirection) -> UIImage {
    UIGraphicsBeginImageContextWithOptions(circleSize, false, 0.0)
    let context = UIGraphicsGetCurrentContext()
    context?.setFillColor(backgroundColor.cgColor)
    context?.setStrokeColor(UIColor.clear.cgColor)
    let bounds = CGRect(origin: .zero, size: circleSize)
    context?.addEllipse(in: bounds)
    context?.drawPath(using: .fill)
    let arrow = IconBuilder.arrowWith(width: Double(arrowWidth), lineHeight: arrowHeight, color: arrowColor, direction: arrowDirection)
    let rect = CGRect(origin: CGPoint(x: bounds.midX, y: bounds.midY), size: .zero).insetBy(dx: -arrow.size.width / 2, dy: -arrow.size.height / 2)
    context?.draw(arrow.cgImage!, in: rect)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image!
}

fileprivate func rotate(_ image: UIImage, by angle: CGFloat) -> UIImage {
    let transfrom = CGAffineTransform(rotationAngle: angle)
    let targetRect = CGRect(origin: .zero, size: image.size).applying(transfrom)
    UIGraphicsBeginImageContextWithOptions(targetRect.size, false, 0.0)
    let context = UIGraphicsGetCurrentContext()
    context?.translateBy(x: targetRect.width / 2, y: targetRect.height / 2)
    context?.rotate(by: angle)
    context?.scaleBy(x: 1.0, y: -1.0)
    context?.draw(image.cgImage!, in: CGRect(x: -(image.size.width / 2), y: -(image.size.height / 2), width: image.size.width, height: image.size.height))
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image!
}

fileprivate func makeArrowWith(width: Double, lineHeight: CGFloat ,strokeColor: UIColor) -> UIImage? {
    let angleInDegrees = 38.0
    let angleInRadians = angleInDegrees.radians
    let hypotenuse = width * 0.75
    let height = hypotenuse * sin(angleInRadians) * 2
    let offset:Double = 2
    let size = CGSize(width: width + offset, height: height)
    UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
    let context = UIGraphicsGetCurrentContext()
    let x = hypotenuse * cos(angleInRadians)
    let y = hypotenuse * sin(angleInRadians)
    context?.move(to: CGPoint(x: x, y: 0))
    context?.addLine(to: CGPoint(x: offset, y: y))
    context?.addLine(to: CGPoint(x: x, y: y  * 2))
    context?.move(to: CGPoint(x: offset, y: y))
    context?.addLine(to: CGPoint(x: width, y: y))
    context?.setStrokeColor(strokeColor.cgColor)
    context?.setLineJoin(.miter)
    context?.setLineWidth(lineHeight)
    context?.strokePath()
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image
}

enum ArrowDirection {
    case up
    case down
    case left
    case right
}


struct IconBuilder {
    static func arrowWith(width: Double, lineHeight: CGFloat = 3.0, color: UIColor, direction: ArrowDirection) -> UIImage {
        let image = makeArrowWith(width: width, lineHeight: lineHeight, strokeColor: color)!
        switch direction {
        case .left:
            return image
        case .right:
            return rotate(image, by: CGFloat((180.0).radians))
        case .up:
            return rotate(image, by: CGFloat((-90.0).radians))
        case .down:
            return rotate(image, by: CGFloat((90.0).radians))
        }
    }
    
    static func circleWith(size: CGSize, backgroundColor: UIColor) -> UIImage {
        return makeCircleWith(size: size, backgroundColor: backgroundColor)!
    }
    
    static func arrowWithCircularBackground(ofSize circleSize: CGSize, backgroundColor: UIColor, arrowWidth: CGFloat, arrowHeight: CGFloat = 2.0, arrowColor: UIColor, arrowDirection: ArrowDirection) -> UIImage {
        return makeArrowWithCircularBackground(ofSize: circleSize, backgroundColor: backgroundColor, arrowWidth:arrowWidth, arrowHeight: arrowHeight, arrowColor:arrowColor, arrowDirection:arrowDirection)
    }
}

extension IconBuilder {
    static var nextComponentIcon: UIImage = {
        return IconBuilder.arrowWithCircularBackground(
            ofSize: CGSize(width: 24, height: 24),
            backgroundColor : UIColor.clear,
            arrowWidth: 16.0,
            arrowHeight: 2.0,
            arrowColor: UIColor(colorLiteralRed: 38/255.0, green: 144/255.0, blue: 240/255.0, alpha: 1.0),
            arrowDirection: .right
        )
    }()
    
    static var prevComponentIcon: UIImage = {
        return IconBuilder.arrowWithCircularBackground(
            ofSize: CGSize(width: 24, height: 24),
            backgroundColor : UIColor.clear,
            arrowWidth: 16.0,
            arrowHeight: 2.0,
            arrowColor: UIColor(colorLiteralRed: 38/255.0, green: 144/255.0, blue: 240/255.0, alpha: 1.0),
            arrowDirection: .left
        )
    }()
    
    static var nextModuleIcon: UIImage = {
        return IconBuilder.arrowWithCircularBackground(
            ofSize: CGSize(width: 24, height: 24),
            backgroundColor : UIColor(colorLiteralRed: 38/255.0, green: 144/255.0, blue: 240/255.0, alpha: 1.0),
            arrowWidth: 12.0,
            arrowHeight: 1.5,
            arrowColor: UIColor.white,
            arrowDirection: .right
        )
    }()
    
    static var prevModuleIcon: UIImage = {
        return IconBuilder.arrowWithCircularBackground(
            ofSize: CGSize(width: 24, height: 24),
            backgroundColor : UIColor(colorLiteralRed: 38/255.0, green: 144/255.0, blue: 240/255.0, alpha: 1.0),
            arrowWidth: 12.0,
            arrowHeight: 1.5,
            arrowColor: UIColor.white,
            arrowDirection: .left
        )
    }()
    
    static var pervLessonIcon: UIImage = {
        return IconBuilder.arrowWithCircularBackground(
            ofSize: CGSize(width: 24, height: 24),
            backgroundColor : UIColor.lightGray,
            arrowWidth: 12.0,
            arrowHeight: 1.5,
            arrowColor: UIColor.white,
            arrowDirection: .left
        )
    }()
    
    static var nextLessonIcon: UIImage = {
        return IconBuilder.arrowWithCircularBackground(
            ofSize: CGSize(width: 24, height: 24),
            backgroundColor : UIColor.lightGray,
            arrowWidth: 12.0,
            arrowHeight: 1.5,
            arrowColor: UIColor.white,
            arrowDirection: .right
        )
    }()
}



fileprivate extension Double {
    var radians: Double {
        return self * (Double.pi / 180)
    }
}

fileprivate extension CGFloat {
    var radian: CGFloat {
        return self * (CGFloat.pi / 180)
    }
}
