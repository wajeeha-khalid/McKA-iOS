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
    var downloadActionBlock: ((_ unitID : CourseBlockID, _ sender: CourseLiveUnitViewCell) -> ())?
    var cancelActionBlock: ((_ unitID : CourseBlockID, _ sender: CourseLiveUnitViewCell) -> ())?
    
    
    var downloadState: DownloadState {
        
        didSet {
            
            switch downloadState.state {
                
            case .available:
                downloadProgressButton.isHidden = false
                downloadProgressButton.state = .startDownload
                downloadLabel.text = "Download"
                downloadLabel.textColor = UIColor(red: 185/255, green:  185/255, blue:  185/255, alpha: 1.0)
                downloadLabel.isHidden = false
                //ibStateLabel.text = "Available"
                
            case .active:
                downloadLabel.isHidden = false
                downloadLabel.text = "Downloading...."
                downloadLabel.textColor = UIColor(red: 0/255, green:  221/255, blue:  253/255, alpha: 1.0)
                downloadProgressButton.isHidden = false
                downloadProgressButton.state = .downloading
                downloadProgressButton.stopDownloadButton.progress = CGFloat(downloadState.progress/100)
                //ibStateLabel.text = "Active"

            case .complete :
                downloadLabel.isHidden = false
                downloadLabel.text = "Downloaded"
                downloadLabel.textColor = UIColor(red: 185/255, green:  185/255, blue:  185/255, alpha: 1.0)
                downloadProgressButton.isHidden = true
                //ibStateLabel.text = "Complete"

            case .notAvailable:
                downloadLabel.isHidden = true
                downloadProgressButton.isHidden = true
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
                
        downloadProgressButton.startDownloadButton.cleanDefaultAppearance()
        downloadProgressButton.startDownloadButton.contentEdgeInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        downloadProgressButton.startDownloadButton.setImage(UIImage(named: "ic_blue_download.png"), for: UIControlState())
        downloadProgressButton.startDownloadButton.imageView?.contentMode = .scaleAspectFit
        
        downloadProgressButton.stopDownloadButton.stopButton.contentEdgeInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        downloadProgressButton.stopDownloadButton.tintColor = UIColor(hexString: "#00DDFD", alpha: 1.0)
        downloadProgressButton.stopDownloadButton.filledLineWidth = 3.0
        
        downloadProgressButton.pendingView.radius = 12.0
        downloadProgressButton.pendingView.tintColor = UIColor(hexString: "#00DDFD", alpha: 1.0)
        
        downloadProgressButton.delegate = self
        
        sizeLabel.isHidden = true
        
        addShadow()
    }
    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    

    func getCellDetails(_ block : CourseBlock, index: Int){
        unitTitle.text =  "\(index + 1). \(block.displayName)"
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
        //MARK: PKDownloadButtonDelegate
    func downloadButtonTapped(_ downloadButton: PKDownloadButton!, currentState state: PKDownloadButtonState) {
        
        switch state {
        case .startDownload:
            
            downloadButton.state = .pending
            downloadButton.pendingView.startSpin()
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
    
    fileprivate func addShadow(){
        layer.shadowOffset = CGSize(width: 0.0, height: 3.0)
        layer.shadowColor = UIColor.darkGray.cgColor
        layer.shadowRadius = 20
        layer.shadowOpacity = 0.25
        layoutMargins = UIEdgeInsets.zero
        // Maybe just me, but I had to add it to work:
        clipsToBounds = false
        
        let shadowFrame: CGRect = self.layer.bounds
        let shadowPath: CGPath = UIBezierPath(rect: shadowFrame).cgPath
        layer.shadowPath = shadowPath
        layer.zPosition = 10
    }
}
