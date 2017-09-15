//
//  HTMLStyles.swift
//  edX
//
//  Created by Salman Jamil on 9/11/17.
//  Copyright © 2017 edX. All rights reserved.
//

import Foundation


func makeTempelateWith(fontSize: Int = 14) -> (String) -> String {
    return { body in
        return "<html> <head> <style type=\"text/css\">  body {  font-size: \(fontSize)px;  font-family: -apple-system, Arial, sans-serif; color: white; margin-bottom: 0px; padding-bottom: 0px; line-height: 20px; } </style> </head> <body> \(body) </body> </html>"
    }
}

let questionTemplate: (String) -> String = makeTempelateWith(fontSize: 14)

extension String {
    func styled(with template: (String) -> String) -> String {
        return template(self)
    }
}

extension NSAttributedString {
    convenience public init?(styled: String, textAlignment: NSTextAlignment = .justified, color: UIColor = .black) {
        guard let data = styled.data(using: .unicode) else {
            return nil
        }
        do {
            let string = try NSMutableAttributedString(data: data,
                                                       options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType], documentAttributes: nil)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = textAlignment
            
            string.addAttributes(
                [NSParagraphStyleAttributeName : paragraphStyle,
                 NSForegroundColorAttributeName: color],
                range: NSMakeRange(0, string.length)
            )
            
            self.init(attributedString: string.removingTrailingNewLine)
        } catch {
            return nil
        }
    }
    
    var removingTrailingNewLine: NSAttributedString {
        if string.hasSuffix("\n") {
            return attributedSubstring(from: NSRange(location:0, length: length - 1))
        }
        return self
    }
}

