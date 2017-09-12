//
//  AnnouncementCollectionViewCell.swift
//  edX
//
//  Created by Abdul Haseeb on 9/6/17.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

public protocol AnnouncementsWebViewEvent {
    func showWebNavigationViewController(request: URLRequest)
}

class AnnouncementCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var webView: UIWebView!

    var courseAnnounement: CourseAnnouncement?
    var loadedFirstTime = true
    var delegate: AnnouncementsWebViewEvent?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        webView.delegate = self
    }
    
    func configureCellContent() {
        self.dateLabel.text = courseAnnounement?.date
        loadedFirstTime = true
        loadTemplateHTML()
    }
}

extension AnnouncementCollectionViewCell: UIWebViewDelegate {
    func webViewDidFinishLoad(_ webView: UIWebView){
        loadedFirstTime = false
    }
    
    func webViewDidStartLoad(_ webView: UIWebView){
       
    }
    
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
      
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        loadRequest(request: request)
        return loadedFirstTime
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
    
    func loadRequest(request: URLRequest) {
        if !loadedFirstTime {
            delegate?.showWebNavigationViewController(request: request)
        }
    }
}
