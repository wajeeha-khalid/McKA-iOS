//
//  CourseUnitsViewCell.swift
//  edX
//
//  Created by Naveen Katari on 30/01/17.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit


class CourseUnitsViewCell: MGSwipeTableCell, PKDownloadButtonDelegate {
    
    @IBOutlet weak var unitTitle: UILabel!
    @IBOutlet weak var previousUnitLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var downloadButton: PKDownloadButton!
    @IBOutlet weak var downloadLabel: UILabel!
    @IBOutlet weak var statusImage: UIImageView!
    @IBOutlet weak var ibStateLabel: UILabel!
    
    var unitID: CourseBlockID?
    var downloadActionBlock: ((_ unitID : CourseBlockID, _ sender: CourseUnitsViewCell) -> ())?
    var cancelActionBlock: ((_ unitID : CourseBlockID, _ sender: CourseUnitsViewCell) -> ())?

    
    var downloadState: DownloadState {
        
        didSet {
            
            switch downloadState.state {
                
            case .available :
                downloadButton.isHidden = false
                downloadButton.state = .startDownload
                downloadLabel.text = "Download"
                downloadLabel.textColor = UIColor(red: 185/255, green:  185/255, blue:  185/255, alpha: 1.0)
                downloadLabel.isHidden = false
                //ibStateLabel.text = "Available"
                
            case .active :
                downloadButton.isHidden = false
                downloadButton.state = .downloading
                downloadButton.stopDownloadButton.progress = CGFloat(downloadState.progress/100)
                downloadLabel.isHidden = false
                downloadLabel.text = "Downloading...."
                downloadLabel.textColor = UIColor(red: 0/255, green:  221/255, blue:  253/255, alpha: 1.0)
                //ibStateLabel.text = "Active"
                
            case .complete :
                downloadButton.isHidden = true
                downloadLabel.isHidden = false
                downloadLabel.text = "Downloaded"
                downloadLabel.textColor = UIColor(red: 185/255, green:  185/255, blue:  185/255, alpha: 1.0)
                //ibStateLabel.text = "Complete"
                
            case .notAvailable:
                downloadButton.isHidden = true
                downloadLabel.text = nil
                downloadLabel.isHidden = true
                //ibStateLabel.text = "NotAvailable"
            }
        }
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        downloadState = DownloadState(state: .available, progress: 0.0)
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        downloadButton.startDownloadButton.cleanDefaultAppearance()
        downloadButton.startDownloadButton.contentEdgeInsets = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
        downloadButton.startDownloadButton.setImage(UIImage(named: "ic_blue_download.png"), for: UIControlState())
        downloadButton.startDownloadButton.imageView?.contentMode = .scaleAspectFit
        
        downloadButton.stopDownloadButton.stopButton.contentEdgeInsets = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
        downloadButton.stopDownloadButton.tintColor = UIColor(hexString: "#00DDFD", alpha: 1.0)
        downloadButton.stopDownloadButton.filledLineWidth = 3.0
        
        downloadButton.pendingView.tintColor = UIColor(hexString: "#00DDFD", alpha: 1.0)
        downloadButton.pendingView.radius = 12.0
        downloadButton.delegate = self        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
    
    func getCellDetails(_ block : CourseBlock, index : Int) {
        unitTitle.text =  "\(index + 1). \(block.displayName)"
        self.contentView.layoutIfNeeded()
    }
    
    //MARK: PKDownloadButtonDelegate
    @objc func downloadButtonTapped(_ downloadButton: PKDownloadButton!, currentState state: PKDownloadButtonState) {
        
        switch state {
        case .startDownload:
            
            if let unitID = unitID {
                downloadActionBlock?(unitID, self)
            }
            
        case .pending :
            break
            
        case .downloading :
            if let unitID = unitID {
                cancelActionBlock?(unitID, self)
            }
            
        case .downloaded :
            break
        }
    }
}
