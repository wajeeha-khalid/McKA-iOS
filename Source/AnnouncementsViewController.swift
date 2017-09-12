//
//  AnnouncementsViewController.swift
//  edX
//
//  Created by Abdul Haseeb on 8/18/17.
//  Copyright © 2017 edX. All rights reserved.
//

//  TODO: In the current senario the app is crashing if there is no announcements or the data is failed to load.

import UIKit
import Foundation

class AnnouncementsViewController: UIViewController {

    public typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & DataManagerProvider & NetworkManagerProvider & OEXRouterProvider & OEXInterfaceProvider & OEXRouterProvider
    
    @IBOutlet weak var noAnnouncementLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    
    fileprivate let environment: Environment
    fileprivate let courseId: String?
    
    var stream: edXCore.Stream<[CourseAnnouncement]>?
    var courseAnnouncements: [CourseAnnouncement]?
    
    let loadController: LoadStateViewController
    
    public init(environment: Environment, courseId: String?) {
        self.environment = environment
        self.courseId = courseId
        loadController = LoadStateViewController()
        
        super.init(nibName: nil, bundle: nil)
        stream = environment.dataManager.courseDataManager.streamForCourseAnnouncements(courseId ?? "")
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addListeners()
        setupUI()
        registerNibs()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        var insets = self.collectionView.contentInset
        let value = 20 
        insets.left = CGFloat(value)
        insets.right = CGFloat(value)
        insets.top = CGFloat(value)
        insets.bottom = CGFloat(value)
        self.collectionView.contentInset = insets
        print("\(value)")
        self.collectionView.decelerationRate = UIScrollViewDecelerationRateFast;
    }

    private func setupUI () {
        self.navigationItem.title = Strings.courseAnnouncements
        loadController.setupInController(self, contentView: self.collectionView)
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func showStreamData() {
        //TODO: adjust the loader view according to states rightnow the app is crashing if data fails to load in web view.
        if (courseAnnouncements != nil) {
            if (courseAnnouncements?.count)! > 0 {
                collectionView.isHidden = false
                collectionView.reloadData()
            } else {
                collectionView.isHidden = false
            }
        }
    }

    private func addListeners() {
        stream?.listen(self, action: { (result) in
            result.ifSuccess({ (courseAnnouncements: [CourseAnnouncement]) -> Void in
                if courseAnnouncements.count > 0 {
                    self.loadController.state = LoadState.loaded
                    self.courseAnnouncements = courseAnnouncements
                    self.noAnnouncementLabel.isHidden = true
                    self.showStreamData()
                } else {
                    self.collectionView.isHidden = true
                    self.loadController.state = LoadState.loaded
                }
                
            })
            result.ifFailure({ (error) in
                self.collectionView.isHidden = true
                self.loadController.state = LoadState.loaded
            })
        })
    }

}

extension AnnouncementsViewController {
    func registerNibs() {
        self.collectionView.register(UINib(nibName: "AnnouncementCollectionViewCell", bundle: nil),
                                     forCellWithReuseIdentifier: "AnnouncementCollectionViewCell")
    }
}

extension AnnouncementsViewController: UICollectionViewDelegate {

}

extension AnnouncementsViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var cellSize = collectionView.bounds.size
        cellSize.width -= 40.0
        cellSize.height -= 20.0
        return cellSize
    }
    
}

extension AnnouncementsViewController: UICollectionViewDataSource {
 
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return courseAnnouncements?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AnnouncementCollectionViewCell",
                                                      for: indexPath) as! AnnouncementCollectionViewCell
        configureCollectionViewCell(indexPath: indexPath, cell: cell)
        return cell
    }

}

extension AnnouncementsViewController {

    func configureCollectionViewCell(indexPath: IndexPath, cell: AnnouncementCollectionViewCell) {
        cell.courseAnnounement = courseAnnouncements?[indexPath.row]
        cell.configureCellContent()
        cell.delegate = self
        addShadowToCell(cell: cell)
    }
    
    func addShadowToCell(cell: UICollectionViewCell) {
        cell.contentView.layer.borderWidth = 1.0
        cell.contentView.layer.borderColor = UIColor.clear.cgColor
        cell.contentView.layer.masksToBounds = true
        cell.layer.shadowColor = UIColor.gray.cgColor
        cell.layer.shadowOffset = CGSize(width: 0, height: 0)
        cell.layer.shadowRadius = 2.0
        cell.layer.shadowOpacity = 1.0
        cell.layer.masksToBounds = false
        cell.layer.shadowPath = UIBezierPath(roundedRect:cell.bounds,
                                             cornerRadius:cell.contentView.layer.cornerRadius).cgPath
    }
}

extension AnnouncementsViewController: AnnouncementsWebViewEvent {

    func showWebNavigationViewController(request: URLRequest) {
        let webNavigationViewController = WebNavigationViewController(request: request,
                                                                      title: Strings.courseAnnouncements)
        let navigationController = UINavigationController(rootViewController: webNavigationViewController)
        self.present(navigationController, animated: false, completion: nil)
    }
    
}
