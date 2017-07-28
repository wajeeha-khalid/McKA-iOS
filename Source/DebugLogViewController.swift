//
//  DebugLogViewController.swift
//  edX
//
//  Created by Michael Katz on 11/19/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

class DebugLogViewController : UIViewController {
    var textView = UITextView()

    override func viewDidLoad() {
        super.viewDidLoad()

        textView.isEditable = false

        self.view = textView

        loadLog()

        let shareButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(DebugLogViewController.share))
        let clearButton = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(DebugLogViewController.clear))
        navigationItem.rightBarButtonItems = [clearButton, shareButton]
    }

    fileprivate func loadLog() {
        DispatchQueue.global(qos: .utility).async {
            if let textData = try? Data(contentsOf: URL(fileURLWithPath: DebugMenuLogger.instance.filename)) {
                let text = String(data: textData, encoding:  String.Encoding.utf8)
                DispatchQueue.main.async {
                    self.textView.text = text
                }
            }
        }
    }

    func share() {
        let c = UIActivityViewController(activityItems: [self.textView.text], applicationActivities: nil)
        present(c, animated: true, completion: nil)
    }

    func clear() {
        DebugMenuLogger.instance.clear()
        loadLog()
    }
}
