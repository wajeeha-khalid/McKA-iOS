//
//  Icon.swift
//  edX
//
//  Created by Akiva Leffert on 5/14/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit
import FontAwesome

protocol IconRenderer : class {
    var shouldFlip : Bool { get }
    func boundsWithAttributes(_ attributes : [String : AnyObject], inline : Bool) -> CGRect
    func drawWithAttributes(_ attributes : [String : AnyObject], inContext context : CGContext)
}

class FontAwesomeRenderer : IconRenderer {
    let icon : FontAwesome
    
    init(icon : FontAwesome) {
        self.icon = icon
    }
    
    func boundsWithAttributes(_ attributes : [String : AnyObject], inline : Bool) -> CGRect {
        let string = NSAttributedString(string: icon.rawValue, attributes : attributes)
        let drawingOptions = inline ? NSStringDrawingOptions() : .usesLineFragmentOrigin
        
        return string.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude), options: drawingOptions, context: nil).integral
    }
    
    func drawWithAttributes(_ attributes : [String : AnyObject], inContext context: CGContext) {
        let string = NSAttributedString(string: icon.rawValue, attributes : attributes)
        let bounds  = boundsWithAttributes(attributes, inline : false)
        
        string.draw(with: bounds, options: .usesLineFragmentOrigin, context: nil)
    }
    
    var shouldFlip : Bool {
        switch UIApplication.shared.userInterfaceLayoutDirection {
        case .leftToRight:
            return false
        case .rightToLeft:
            // Go through the font awesome representation since those don't change even if the
            // icon's image change and we may use the same icon with different meanings.

            switch icon {
            case .check, .checkSquareO, .infoCircle, .playCircleO:
                return false
            default:
                return true
            }
        }
    }
    
}

private class RotatedIconRenderer : IconRenderer {

    fileprivate let backing : IconRenderer
    
    init(backing : IconRenderer) {
        self.backing = backing
    }
    
    fileprivate func boundsWithAttributes(_ attributes: [String : AnyObject], inline: Bool) -> CGRect {
        let bounds = backing.boundsWithAttributes(attributes, inline: inline)
        // Swap width + height
        return CGRect(x: bounds.minX, y: bounds.minY, width: bounds.height, height: bounds.width)
    }
    
    func drawWithAttributes(_ attributes : [String : AnyObject], inContext context : CGContext) {
        let bounds = self.boundsWithAttributes(attributes, inline: false)
        // Draw rotated
        context.translateBy(x: -bounds.midX, y: -bounds.midY)
        context.scaleBy(x: 1.0, y: -1.0);
        context.rotate(by: CGFloat(-(Float.pi/2)));
        context.translateBy(x: bounds.midY, y: bounds.midX)
        backing.drawWithAttributes(attributes, inContext: context)
    }
    
    var shouldFlip : Bool {
        return backing.shouldFlip
    }
    
}

// Abstracts out FontAwesome so that we can swap it out if necessary
// And also give some of our icons more semantics names
public enum Icon {
    case answered
    case announcements
    case arrowUp
    case arrowDown
    case camera
    case circleO
    case checkCircleO
    case closed
    case comment
    case comments
    case country
    case courseware
    case contentCanDownload
    case contentDidDownload
    case courseEffort
    case courseEnd
    case courseHTMLContent
    case courseModeFull
    case courseModeVideo
    case courseProblemContent
    case courseUnknownContent
    case courseVideoContent
    case courseVideoPlay
    case create
    case discussions
    case dropdown
    case filter
    case recent
    case followStar
    case graded
    case handouts
    case internetError
    case menu
    case noTopics
    case noSearchResults
    case openURL
    case pinned
    case rotateDevice
    case question
    case reportFlag
    case settings
    case sort
    case spinner
    case transcript
    case unknownError
    case upVote
    case user
    case videoFullscreen
    case videoPlay
    case videoPause
    case videoRewind
    case videoShrink
    case warning
    case headPhones  /// Added By Ravi on 17thFeb2017 for AudioPodcast

    
    fileprivate var renderer : IconRenderer {
        switch self {
        case .sort:
            return RotatedIconRenderer(backing: FontAwesomeRenderer(icon: .exchange))
        case .rotateDevice:
            return RotatedIconRenderer(backing: FontAwesomeRenderer(icon: .mobile))
        case .headPhones:
            return FontAwesomeRenderer(icon: .headphones)
        case .arrowUp: /// Added By Ravi on 17thFeb2017 for AudioPodcast
            return FontAwesomeRenderer(icon: .longArrowUp)
        case .arrowDown:
            return FontAwesomeRenderer(icon: .longArrowDown)
        case .camera:
            return FontAwesomeRenderer(icon: .camera)
        case .comment:
            return FontAwesomeRenderer(icon: .comment)
        case .comments:
            return FontAwesomeRenderer(icon: .comments)
        case .question:
            return FontAwesomeRenderer(icon: .question)
        case .answered:
            return FontAwesomeRenderer(icon: .checkSquareO)
        case .filter:
            return FontAwesomeRenderer(icon: .filter)
        case .user:
            return FontAwesomeRenderer(icon: .user)
        case .create:
            return FontAwesomeRenderer(icon: .plusCircle)
        case .pinned:
            return FontAwesomeRenderer(icon: .thumbTack)
        case .transcript:
            return FontAwesomeRenderer(icon: .fileTextO)
        case .announcements:
            return FontAwesomeRenderer(icon: .bullhorn)
        case .circleO:
            return FontAwesomeRenderer(icon: .circleO)
        case .checkCircleO:
            return FontAwesomeRenderer(icon: .checkCircleO)
        case .contentCanDownload:
            return FontAwesomeRenderer(icon: .arrowDown)
        case .contentDidDownload:
            return FontAwesomeRenderer(icon: .check)
        case .courseEffort:
            return FontAwesomeRenderer(icon: .dashboard)
        case .courseVideoPlay:
            return FontAwesomeRenderer(icon: .playCircleO)
        case .courseEnd:
            return FontAwesomeRenderer(icon: .clockO)
        case .courseHTMLContent:
            return FontAwesomeRenderer(icon: .fileO)
        case .courseModeFull:
            return FontAwesomeRenderer(icon: .list)
        case .recent:
            return FontAwesomeRenderer(icon: .arrowsV)
        case .country:
            return FontAwesomeRenderer(icon: .mapMarker)
        case .courseModeVideo:
            return FontAwesomeRenderer(icon: .film)
        case .courseProblemContent:
            return FontAwesomeRenderer(icon: .thList)
        case .courseware:
            return FontAwesomeRenderer(icon: .listAlt)
        case .courseUnknownContent:
            return FontAwesomeRenderer(icon: .laptop)
        case .courseVideoContent:
            return FontAwesomeRenderer(icon: .film)
        case .menu:
            return FontAwesomeRenderer(icon: .bars)
        case .reportFlag:
            return FontAwesomeRenderer(icon: .flag)
        case .upVote:
            return FontAwesomeRenderer(icon: .plus)
        case .followStar:
            return FontAwesomeRenderer(icon: .star)
        case .discussions:
            return FontAwesomeRenderer(icon: .commentsO)
        case .dropdown:
            return FontAwesomeRenderer(icon: .caretDown)
        case .graded:
            return FontAwesomeRenderer(icon: .check)
        case .handouts:
            return FontAwesomeRenderer(icon: .fileTextO)
        case .internetError:
            return FontAwesomeRenderer(icon: .wifi)
        case .openURL:
            return FontAwesomeRenderer(icon: .shareSquareO)
        case .settings:
            return FontAwesomeRenderer(icon: .cog)
        case .spinner:
            return FontAwesomeRenderer(icon: .spinner)
        case .unknownError:
            return FontAwesomeRenderer(icon: .exclamationCircle)
        case .noTopics:
            return FontAwesomeRenderer(icon: .list)
        case .noSearchResults:
            return FontAwesomeRenderer(icon: .infoCircle)
        case .videoFullscreen:
            return FontAwesomeRenderer(icon: .expand)
        case .videoPlay:
            return FontAwesomeRenderer(icon: .play)
        case .videoPause:
            return FontAwesomeRenderer(icon: .pause)
        case .videoRewind:
            return FontAwesomeRenderer(icon: .history)
        case .videoShrink:
            return FontAwesomeRenderer(icon: .compress)
        case .closed:
            return FontAwesomeRenderer(icon: .lock)
        case .warning:
            return FontAwesomeRenderer(icon: .exclamation)
        }
    }
    
    
    // Do not make this public, since interacting with Icon text directly makes it difficult to account for Right to Left

    public var accessibilityText : String? {
        switch self {
        case .courseVideoContent:
            return Strings.accessibilityVideo
        case .courseHTMLContent:
            return Strings.accessibilityHtml
        case .courseProblemContent:
            return Strings.accessibilityProblem
        case .courseUnknownContent:
            return Strings.accessibilityUnknown
        default:
            return nil
        }
    }
    
    fileprivate func imageWithStyle(_ style : OEXTextStyle, sizeOverride : CGFloat? = nil, inline : Bool = false) -> UIImage {
        var attributes = style.attributes
        let textSize = sizeOverride ?? OEXTextStyle.pointSize(for: style.size)
        attributes[NSFontAttributeName] = Icon.fontWithSize(textSize)
        
        let bounds = renderer.boundsWithAttributes(attributes as [String : AnyObject], inline: inline)
        let imageSize = bounds.size
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: imageSize.width, height: imageSize.height), false, 0)

        if renderer.shouldFlip {
            let context = UIGraphicsGetCurrentContext()
            context!.translateBy(x: imageSize.width, y: 0)
            context!.scaleBy(x: -1, y: 1)
        }
        
        renderer.drawWithAttributes(attributes as [String : AnyObject], inContext: UIGraphicsGetCurrentContext()!)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!.withRenderingMode(.alwaysTemplate)
    }

    public func attributedTextWithStyle(_ style : OEXTextStyle, inline : Bool = false) -> NSAttributedString {
        var attributes = style.attributes
        attributes[NSFontAttributeName] = Icon.fontWithSize(style.size)
        let bounds = renderer.boundsWithAttributes(attributes as [String : AnyObject], inline : inline)
        
        let attachment = NSTextAttachment(data: nil, ofType: nil)
        attachment.image = imageWithStyle(style).withRenderingMode(UIImageRenderingMode.alwaysOriginal)
        attachment.bounds = bounds
        return NSAttributedString(attachment: attachment)
    }
    
    /// Returns a template mask image at the given size
    public func imageWithFontSize(_ size : CGFloat) -> UIImage {
        return imageWithStyle(OEXTextStyle(weight: .normal, size: .base, color: UIColor.black), sizeOverride:size)
    }
    
    func barButtonImage(deltaFromDefault delta : CGFloat = 0) -> UIImage {
        return imageWithFontSize(18 + delta)
    }
    
    fileprivate static func fontWithSize(_ size : CGFloat) -> UIFont {
        return UIFont.fontAwesome(ofSize:size)
    }
    
    fileprivate static func fontWithSize(_ size : OEXTextSize) -> UIFont {
        return fontWithSize(OEXTextStyle.pointSize(for: size))
    }
    
    fileprivate static func fontWithTitleSize() -> UIFont {
        return fontWithSize(17)
    }
}
