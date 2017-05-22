//
//  CourseLiveUnitViewCell.swift
//  edX
//
//  Created by Naveen Katari on 30/01/17.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

class CourseLiveUnitViewCell: MGSwipeTableCell, PKDownloadButtonDelegate {
    
    @IBOutlet weak var unitTitle: UILabel!
    @IBOutlet weak var sizeLabel: UILabel!
    @IBOutlet weak var containerViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet var userLevelView: UserLevelView? = UserLevelView()
    @IBOutlet weak var userLevelDetailView: UIView!
    @IBOutlet weak var downloadLabel: UILabel!
    @IBOutlet weak var currentUserLevelLabel: UILabel!
    @IBOutlet weak var maxUserLevelLabel: UILabel!
    @IBOutlet weak var downloadProgressButton: PKDownloadButton!
    @IBOutlet weak var ibStateLabel: UILabel!
    
    
    var currentUserLevel : Int = 0 {
        
        didSet {
            userLevelView!.currentUserLevel = self.currentUserLevel
            currentUserLevelLabel.text = String(self.currentUserLevel)
        }
    }
    
    var maxUserLevel : Int = 8 {
        
        didSet {
            userLevelView!.MaxUserLevel = self.maxUserLevel
            maxUserLevelLabel.text = String(self.maxUserLevel)
        }
    }
    
    var unitID: CourseBlockID?
    var downloadActionBlock: ((unitID : CourseBlockID, sender: CourseLiveUnitViewCell) -> ())?
    var cancelActionBlock: ((unitID : CourseBlockID, sender: CourseLiveUnitViewCell) -> ())?
    
    
    var downloadState: DownloadState {
        
        didSet {
            
            switch downloadState.state {
                
            case .Available:
                downloadProgressButton.hidden = false
                downloadProgressButton.state = .StartDownload
                downloadLabel.text = "Download"
                downloadLabel.textColor = UIColor(red: 185/255, green:  185/255, blue:  185/255, alpha: 1.0)
                downloadLabel.hidden = false
                //ibStateLabel.text = "Available"
                
            case .Active:
                downloadLabel.hidden = false
                downloadLabel.text = "Downloading...."
                downloadLabel.textColor = UIColor(red: 0/255, green:  221/255, blue:  253/255, alpha: 1.0)
                downloadProgressButton.hidden = false
                downloadProgressButton.state = .Downloading
                downloadProgressButton.stopDownloadButton.progress = CGFloat(downloadState.progress/100)
                //ibStateLabel.text = "Active"

            case .Complete :
                downloadLabel.hidden = false
                downloadLabel.text = "Downloaded"
                downloadLabel.textColor = UIColor(red: 185/255, green:  185/255, blue:  185/255, alpha: 1.0)
                downloadProgressButton.hidden = true
                //ibStateLabel.text = "Complete"

            case .NotAvailable:
                downloadLabel.hidden = true
                downloadProgressButton.hidden = true
                //ibStateLabel.text = "NotAvailable"
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        downloadState = DownloadState(state: .Available, progress: 0.0)
        
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
                
        downloadProgressButton.startDownloadButton.cleanDefaultAppearance()
        downloadProgressButton.startDownloadButton.contentEdgeInsets = EdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        downloadProgressButton.startDownloadButton.setImage(UIImage(named: "ic_blue_download.png"), forState: .Normal)
        downloadProgressButton.startDownloadButton.imageView?.contentMode = .ScaleAspectFit
        
        downloadProgressButton.stopDownloadButton.stopButton.contentEdgeInsets = EdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        downloadProgressButton.stopDownloadButton.tintColor = UIColor(hexString: "#00DDFD", alpha: 1.0)
        downloadProgressButton.stopDownloadButton.filledLineWidth = 3.0
        
        downloadProgressButton.pendingView.radius = 12.0
        downloadProgressButton.pendingView.tintColor = UIColor(hexString: "#00DDFD", alpha: 1.0)
        
        downloadProgressButton.delegate = self
        
        sizeLabel.hidden = true
        
        addShadow()
    }
    
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    

    func getCellDetails(block : CourseBlock, index: Int){
        unitTitle.text =  "\(index + 1). \(block.displayName)"
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
        //MARK: PKDownloadButtonDelegate
    func downloadButtonTapped(downloadButton: PKDownloadButton!, currentState state: PKDownloadButtonState) {
        
        switch state {
        case .StartDownload:
            
            downloadButton.state = .Pending
            downloadButton.pendingView.startSpin()
            if let unitID = unitID {
                downloadActionBlock?(unitID: unitID, sender: self)
            }
            
        case .Pending :
            break
            
        case .Downloading :
            if let unitID = unitID {
                cancelActionBlock?(unitID: unitID, sender: self)
            }
            
        case .Downloaded :
            break
        }
    }
    
    private func addShadow(){
        layer.shadowOffset = CGSizeMake(0.0, 3.0)
        layer.shadowColor = UIColor.darkGrayColor().CGColor
        layer.shadowRadius = 20
        layer.shadowOpacity = 0.25
        layoutMargins = UIEdgeInsetsZero
        // Maybe just me, but I had to add it to work:
        clipsToBounds = false
        
        let shadowFrame: CGRect = self.layer.bounds
        let shadowPath: CGPathRef = UIBezierPath(rect: shadowFrame).CGPath
        layer.shadowPath = shadowPath
        layer.zPosition = 10
    }
}
