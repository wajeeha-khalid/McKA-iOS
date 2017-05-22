//
//  UserLevelView.swift
//  ChartsDemo
//
//  Created by Suman Roy on 08/02/17.
//  Copyright © 2017 Sourcebits. All rights reserved.
//

import UIKit

let π:CGFloat = CGFloat(M_PI)

class UserLevelView: UIView {
    
    var currentUserLevel: Int = 5 {
        
        didSet{
            self.setNeedsDisplay()
        }
    }
    var arcWidth: CGFloat = 5
    var separatorColor: UIColor = .whiteColor()
    var currentUserLevelColor: UIColor = UIColor(hexString: "DFE2E4", alpha: 1.0)
    var MaxUserLevel: Int = 8{
        
        didSet{
            self.setNeedsDisplay()
        }
    }
    
    var separatorWidth:CGFloat = 3.0
    
    var userLevelGradientStartColor: UIColor = UIColor(hexString: "27FEBD", alpha: 1.0)
    var userLevelGradientEndColor: UIColor = UIColor(hexString: "00DDFD", alpha: 1.0)
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.*/
    override func drawRect(rect: CGRect) {
        // Step 1 - Draw the Donut shape.
        
        let center = CGPoint(x:bounds.width/2, y: bounds.height/2)
        
        let radius: CGFloat = max(bounds.width, bounds.height)
        
        let startAngle: CGFloat = 3 * π / 2
        let endAngle: CGFloat = startAngle + 2 * π
        
        let path = UIBezierPath(arcCenter: center,
                                radius: radius/2 - arcWidth/2,
                                startAngle: startAngle,
                                endAngle: endAngle,
                                clockwise: true)
        
        path.lineWidth = arcWidth
        currentUserLevelColor.setStroke()
        path.stroke()
        
        /*=======================================================================*/
        // Step 2 - Draw the path for user level gradient
        
        
        let arcLengthPerGlass = ( 2 * π ) / CGFloat(MaxUserLevel)
        
        currentUserLevel = MaxUserLevel >= currentUserLevel ? currentUserLevel : MaxUserLevel
        
        let outlineEndAngle = arcLengthPerGlass * CGFloat(currentUserLevel) + startAngle
        
        //draw the outer arc
        let outlinePath = UIBezierPath(arcCenter: center,
                                       radius: bounds.width/2 ,
                                       startAngle: startAngle,
                                       endAngle: outlineEndAngle,
                                       clockwise: true)
        
        //draw the inner arc
        outlinePath.addArcWithCenter( center,
                                      radius: bounds.width/2 - arcWidth ,
                                      startAngle: outlineEndAngle,
                                      endAngle: startAngle,
                                      clockwise: false)
        
        // close the path
        outlinePath.closePath()
        
        /*=======================================================================*/
        // Step 3 - Fill the Gradient into the previusly marked path
        
        let colors = [userLevelGradientStartColor.CGColor, userLevelGradientEndColor.CGColor]
        
        // set up the color space
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        // set up the color stops
        let colorLocations:[CGFloat] = [0.0, 1.0]
        
        // create the gradient
        let gradient = CGGradientCreateWithColors(colorSpace,
                                                  colors as CFArray,
                                                  colorLocations)
        
        let context = UIGraphicsGetCurrentContext()
        
        CGContextSaveGState(context!)
        
        CGContextSetLineWidth(context!,arcWidth)
        CGContextSetLineJoin(context!, .Round)
        CGContextSetLineCap(context!, .Round)
        
        CGContextAddPath(context!, outlinePath.CGPath)
        CGContextReplacePathWithStrokedPath(context!)
        CGContextClip(context!)
        
        // draw the gradient
        let startPoint = CGPoint(x: 2 * rect.width/3 , y:0)
        let endPoint = CGPoint( x: rect.width/3, y: rect.height)
        
        //outlinePath is used to decidide the color clipping
        
        outlinePath.addClip()
        
        
        
        CGContextDrawLinearGradient(context!, gradient!, startPoint, endPoint, [ .DrawsAfterEndLocation, .DrawsBeforeStartLocation ] )
        CGContextRestoreGState(context!)
        
        
        CGContextSaveGState(context!)
        
        /*=======================================================================*/
        // Step 4 - Draw the separators at equal distances along the path
        
        if MaxUserLevel > 1 {
            separatorColor.setFill()
            
            //2 - the marker rectangle positioned at the top left
            let markerPath = UIBezierPath(rect:
                CGRect(x: -separatorWidth/2,
                    y: 0,
                    width: separatorWidth,
                    height: arcWidth))
            
            //3 - move top left of context to the previous center position
            CGContextTranslateCTM(context!,
                                  rect.width/2,
                                  rect.height/2)
            
            for i in 1...MaxUserLevel {
                //4 - save the centred context
                CGContextSaveGState(context!)
                
                //5 - calculate the rotation angle
                let angle = arcLengthPerGlass * CGFloat(i) + startAngle - π/2
                
                //rotate and translate
                CGContextRotateCTM(context!, angle)
                CGContextTranslateCTM(context!,
                                      0,
                                      rect.height/2 - arcWidth)
                
                //6 - fill the marker rectangle
                markerPath.fill()
                
                //7 - restore the centred context for the next rotate
                CGContextRestoreGState(context!)
            }
            
            //8 - restore the original state in case of more painting
            CGContextRestoreGState(context!)
            
        }
    }    
}
