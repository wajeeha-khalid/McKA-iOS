//
//  OEXVideoPlayerSettings.swift
//  edX
//
//  Created by Michael Katz on 9/9/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

private let cellId = "CustomCell"

private typealias RowType = (title: String, value: Any)
private struct OEXVideoPlayerSetting {
    let title: String
    let rows: [RowType]
    let isSelected: (_ row: Int) -> Bool
    let callback: (_ value: Any)->()
}

@objc protocol OEXVideoPlayerSettingsDelegate {
    func showSubSettings(_ chooser: UIAlertController)
    func setCaption(_ language: String)
    func setPlaybackSpeed(_ speed: OEXVideoSpeed)
    func videoInfo() -> OEXVideoSummary
}


private func setupTable(_ table: UITableView) {
    table.layer.cornerRadius = 10
    table.layer.shadowColor = UIColor.black.cgColor
    table.layer.shadowRadius = 1.0
    table.layer.shadowOffset = CGSize(width: 1, height: 1)
    table.layer.shadowOpacity = 0.8
    table.separatorInset = UIEdgeInsets.zero
    
    table.register(UINib(nibName: "OEXClosedCaptionTableViewCell", bundle: nil), forCellReuseIdentifier: cellId)
}

@objc class OEXVideoPlayerSettings : NSObject {
    
    let optionsTable: UITableView = UITableView(frame: CGRect.zero, style: .plain)
    fileprivate lazy var settings: [OEXVideoPlayerSetting] = {
        self.updateMargins() //needs to be done here because the table loads the data too soon otherwise and it's nil
        
        let rows:[RowType] = [("0.5x",  OEXVideoSpeed.slow), ("1.0x", OEXVideoSpeed.default), ("1.5x", OEXVideoSpeed.fast), ("2.0x", OEXVideoSpeed.xFast)]
        let speeds = OEXVideoPlayerSetting(title: "Video Speed", rows:rows , isSelected: { (row) -> Bool in
            var selected = false
            let savedSpeed = OEXInterface.getCCSelectedPlaybackSpeed()
            
            let speed = rows[row].value as! OEXVideoSpeed
            
            selected = savedSpeed == speed
            
            return selected
            }) {[weak self] value in
                let speed = value as! OEXVideoSpeed
                self?.delegate?.setPlaybackSpeed(speed)
        }
        
        if let transcripts: [String: String] = self.delegate?.videoInfo().transcripts as? [String: String] {
            var rows = [RowType]()
            for lang: String in transcripts.keys {
                let locale = Locale(identifier: lang)
                let displayLang: String = (locale as NSLocale).displayName(forKey: NSLocale.Key.languageCode, value: lang)!
                let item: RowType = (title: displayLang, value: lang)
                rows.append(item)
            }
            
            
            let cc = OEXVideoPlayerSetting(title: "Closed Captions", rows: rows, isSelected: { (row) -> Bool in
                var selected = false
                if let selectedLanguage:String = OEXInterface.getCCSelectedLanguage() {
                    let lang = rows[row].value as! String
                    selected = selectedLanguage == lang
                }
                return selected
                }) {[weak self] value in
                self?.delegate?.setCaption(value as! String)
            }
            return [cc, speeds]
        } else {
            return [speeds]
        }
    }()
    weak var delegate: OEXVideoPlayerSettingsDelegate?

    func updateMargins() {
        optionsTable.layoutMargins = UIEdgeInsets.zero
    }
    
    init(delegate: OEXVideoPlayerSettingsDelegate, videoInfo: OEXVideoSummary) {
        self.delegate = delegate

        super.init()
        
        optionsTable.dataSource = self
        optionsTable.delegate = self
        setupTable(optionsTable)
    }
}

extension OEXVideoPlayerSettings: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! OEXClosedCaptionTableViewCell
        cell.selectionStyle = .none
        
        cell.lbl_Title?.font = UIFont(name: "OpenSans", size: 12)
        cell.viewDisable?.backgroundColor = UIColor.white
        cell.layoutMargins = UIEdgeInsets.zero
        cell.backgroundColor = UIColor.white
     
        let setting = settings[indexPath.row]
        cell.lbl_Title?.text = setting.title
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedSetting = settings[indexPath.row]
        
        let alert = UIAlertController(title: selectedSetting.title, message: nil, preferredStyle: .actionSheet)
        
        for (i, row) in selectedSetting.rows.enumerated() {
            var title = row.title
            if selectedSetting.isSelected(i) {
                //Can't use font awesome here
                title = String(format: Strings.videoSettingSelected, row.title)
            }

            alert.addAction(UIAlertAction(title: title, style:.default, handler: { _ in
                selectedSetting.callback(value: row.value)
            }))
        }
        alert.addCancelAction()
        delegate?.showSubSettings(alert)
    }
}

