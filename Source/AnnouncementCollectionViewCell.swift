//
//  AnnouncementCollectionViewCell.swift
//  edX
//
//  Created by Abdul Haseeb on 9/6/17.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

class AnnouncementCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var webView: UIWebView!
    var courseAnnounement: CourseAnnouncement?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        webView.delegate = self
    }
    
    func configureCellContent() {
        self.dateLabel.text = courseAnnounement?.date
        loadTemplateHTML()
    }
}

extension AnnouncementCollectionViewCell: UIWebViewDelegate {
    func webViewDidFinishLoad(_ webView: UIWebView){
    }
}

extension AnnouncementCollectionViewCell {
    func loadTemplateHTML() {
        let htmlFile = Bundle.main.path(forResource: "template", ofType: "html")
        let htmlString = try? String(contentsOfFile: htmlFile!, encoding: String.Encoding.utf8)
        let htmlLoadingString = htmlString?.replacingOccurrences(of: "MCKINSEY_PLACEHOLDER", with: courseAnnounement?.content ?? "")
        let path: String = Bundle.main.bundlePath
        let baseURL = URL.init(string: path)
        webView.loadHTMLString(htmlLoadingString ?? "", baseURL: baseURL)
    }
}
