//
//  CourseLessonsViewController.swift
//  edX
//
//  Created by Shafqat Muneer on 7/17/17.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

// An enum to track the progress of a course component
enum ComponentProgressState: CustomStringConvertible {
    case complete
    case inProgress
    case notStarted
    
    var description: String {
        switch self {
        case .complete:
            return "Completed"
        case .inProgress:
            return "In Progress"
        case .notStarted:
            return "Not Started"
        }
    }
    
    var image: UIImage {
        switch self {
        case .complete:
            return #imageLiteral(resourceName: "completed")
        case .inProgress:
            return #imageLiteral(resourceName: "in_progress")
        case .notStarted:
            return #imageLiteral(resourceName: "downloaded")
        }
    }
}

public protocol LessonViewModelDataSource {
    var lessons: edXCore.Stream<[LessonViewModel]> { get }
}



final class LessonViewModelDataSourceImplementation: LessonViewModelDataSource  {
    
    let querier: CourseOutlineQuerier
    let interface: OEXInterface
    
    init(querier: CourseOutlineQuerier, interface: OEXInterface) {
        self.querier = querier
        self.interface = interface
    }
    
    var lessons: edXCore.Stream<[LessonViewModel]> {
        let courseLoadingStream = querier.childrenOfBlockWithID(nil)
        return courseLoadingStream.transform { group -> edXCore.Stream<[(CourseBlock, ComponentProgressState)]> in
            let streams =  group.children.filter{ lesson in
                lesson.displayName.lowercased().contains("discussion_course") == false
                } .map { lesson in
                    return self.progressForLesson(withID: lesson.blockID).map { progress in
                        (lesson, progress)
                    }
            }
            return joinStreams(streams)
            }.map { progressStates in
                
                progressStates.enumerated().map{ (index, blockState)  in
                    return LessonViewModel(lessonID: blockState.0.blockID, state: blockState.1, title: blockState.0.displayName, number:index )
                }
        }
    }
    private func progressForLesson(withID lessonID: CourseBlockID)  -> edXCore.Stream<ComponentProgressState> {
        
        func units(for lessonID: CourseBlockID) -> edXCore.Stream<[CourseBlock]> {
            return querier.childrenOfBlockWithID(lessonID).transform { lesson -> edXCore.Stream<[CourseBlock]> in
                let x = lesson.children.map({ section in
                    self.querier.childrenOfBlockWithID(section.blockID).map {
                        $0.children
                    }
                })
                
                let flattened = joinStreams(x).map {
                    $0.flatMap { $0 }
                }
                
                return flattened
            }
        }
        
        func numberOfUnits(for lessonID: CourseBlockID) -> edXCore.Stream<Int> {
            return units(for: lessonID).map { $0.count }
        }
        
        
        return numberOfUnits(for: lessonID).transform { totalUnitCount in
            let completedUnits = self.interface.getCompletedUnits(forChapterID: lessonID)
            if completedUnits.count == totalUnitCount {
                return Stream(value: .complete)
            } else if  completedUnits.count > 0 {
                return Stream(value: .inProgress)
            } else {
                
                let lessonUnits = units(for: lessonID).transform { units -> edXCore.Stream<[ComponentProgressState]> in
                    let streams = units.map {
                        self.progressForUnit(withID: $0.blockID)
                    }
                    return joinStreams(streams)
                }
                
                return lessonUnits.map { result in
                    if result.contains(.inProgress) {
                        return .inProgress
                    } else {
                        return .notStarted
                    }
                }
            }
        }
    }
    
    private func progressForUnit(withID unitID: CourseBlockID) -> edXCore.Stream<ComponentProgressState> {
        
        func numberOfComponentsInUnit(withID unitID: CourseBlockID) -> edXCore.Stream<Int> {
            return querier.childrenOfBlockWithID(unitID).map {
                $0.children.count
            }
        }
        
        return numberOfComponentsInUnit(withID: unitID).map { totalComponentCount in
            let viewedComponents = self.interface.getViewedComponents(forVertical: unitID)
            if viewedComponents.count == totalComponentCount {
                return .complete
            } else if viewedComponents.count > 0 {
                return .inProgress
            } else {
                return .notStarted
            }
        }
    }
}

public struct LessonViewModel {
    let lessonID: CourseBlockID
    var state: ComponentProgressState
    let title: String
    let number: Int
}

open class CourseLessonsViewController: OfflineSupportViewController, UITableViewDelegate, UITableViewDataSource {
    
    public typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & DataManagerProvider & NetworkManagerProvider & ReachabilityProvider & OEXRouterProvider & OEXInterfaceProvider & OEXRouterProvider & OEXSessionProvider & OEXConfigProvider
    
    fileprivate let environment: Environment
    fileprivate let courseID: String
    fileprivate let blockIDStream = BackedStream<CourseBlockID?>()
    fileprivate let courseQuerier : CourseOutlineQuerier
    fileprivate var loadController : LoadStateViewController
    fileprivate var titleType : TitleType
    fileprivate var lesssons : [CourseBlock] = []
    private let lessonViewModelDataSource: LessonViewModelDataSource
    var downloadController  : DownloadController
    var lessonViewModel: [LessonViewModel] = []
    var courseProgressStats: ProgressStats?
    fileprivate var courseProgressStatsStream: edXCore.Stream<ProgressStats>?
    
    @IBOutlet weak var lessonsTableView: UITableView!
    @IBOutlet weak var statsTopView: UIView!
    @IBOutlet weak var StatsTopViewBackgroundImageView: UIImageView!
    @IBOutlet weak var progressPercentageLabel: UILabel!
    @IBOutlet weak var progressBarView: UIProgressView!
    @IBOutlet weak var progressCohortAvgLabel: UILabel!
    
    public init(environment: Environment, courseID: String, rootID : CourseBlockID?, lessonViewModelDataSource: LessonViewModelDataSource) {
        self.environment = environment
        self.courseID = courseID
        courseQuerier = environment.dataManager.courseDataManager.querierForCourseWithID(courseID)
        loadController = LoadStateViewController()
        titleType = TitleType.navTitle
        downloadController  = DownloadController(courseQuerier: courseQuerier, analytics: environment.analytics)
        self.lessonViewModelDataSource = lessonViewModelDataSource
        super.init(env : environment)
        self.courseProgressStatsStream = getCourseProgressStatsStream()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        addRightBarButtonsItems()
        self.lessonsTableView.register(UINib(nibName: "CourseLessonTableViewCell", bundle: nil), forCellReuseIdentifier: "CourseLessonTableViewCell")
        
        let courseStream = BackedStream<UserCourseEnrollment>()
        courseStream.backWithStream(environment.dataManager.enrollmentManager.streamForCourseWithID(courseID))
        courseStream.listenOnce(self) {[weak self] in
            self?.resultLoaded($0)
        }
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.loadController.setupInController(self, contentView: self.lessonsTableView)
        self.addListeners()
        self.setupProgressListener()
        self.addRightBarButtonsItems()
        self.applyThemeingToStatsTopView()
    }
    
    fileprivate func resultLoaded(_ result : Result<UserCourseEnrollment>) {
        switch result {
        case let .success(enrollment):
            self.loadedCourseWithEnrollment(enrollment)
        case let .failure(error):
            debugPrint("Enrollment error: \(error)")
            break
        }
    }
    
    fileprivate func loadedCourseWithEnrollment(_ enrollment: UserCourseEnrollment) {
        navigationItem.title = enrollment.course.name
    }
    
    //MARK: Listener Method
    fileprivate func addListeners() {

        lessonViewModelDataSource.lessons.listen(self) { result in
            switch result {
            case .success(let values):
                self.lessonViewModel = values
                self.lessonsTableView.reloadData()
            case .failure:
                break
            }
        }
        
    }
    
    fileprivate func setupProgressListener() {
        self.courseProgressStatsStream?.listen(self, action: { (result) in
            
            switch result {
            case let .success(courseProgress):
                self.courseProgressStats = courseProgress
                self.progressPercentageLabel.text = String(Int(self.courseProgressStats!.ratio * 100))
                self.progressBarView.setProgress(self.courseProgressStats!.ratio, animated: true)
                self.progressCohortAvgLabel.text = "Cohort Avg: \(Int(self.courseProgressStats!.cohortAvg! * 100))%"
                if let lessonsProgress = self.courseProgressStats?.lessonsProgress {
                    self.lessonViewModel.enumerated().forEach({ (lesson: (offset: Int, element: LessonViewModel)) in
                        let filteredLesson = lessonsProgress.filter({ (lessonProgress) -> Bool in
                            lessonProgress.blockID == lesson.element.lessonID
                        })
                        if filteredLesson.count > 0{
                            self.lessonViewModel[lesson.offset].state = filteredLesson.first!.componentProgress
                        }
                    })
                }
                self.lessonsTableView.reloadData()
                self.loadController.state = .loaded
            case .failure:
                self.loadController.state = .loaded
                break
            }
        })
    }
    
    //MARK: Tableview DataSource
    open func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 125
    }
    
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.lessonViewModel.count
    }
    
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let lessonCell = tableView.dequeueReusableCell(withIdentifier: "CourseLessonTableViewCell") as! CourseLessonTableViewCell
        lessonCell.selectionStyle = UITableViewCellSelectionStyle.none
        lessonCell.lessonViewModel = lessonViewModel[indexPath.row]
        return lessonCell
    }
    
    open func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 15
    }
    
    open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.clear
        return headerView
    }
    
    //MARK: Table view delegate
    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let blockID = lessonViewModel[indexPath.row].lessonID
        if let controller = self.environment.router?.unitControllerForCourseID(courseID, sequentialID:nil, blockID: blockID, initialChildID: nil, courseProgressStats: self.courseProgressStats) {
            
            controller.chapterID = blockID
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"", style:.plain, target:nil, action:nil)
            self.navigationController?.pushViewController(controller, animated: true)
        }
        
    }
    
    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func reloadViewData() {
        reload()
    }
    
    //MARK : Refresh View
    func reload() {
        self.blockIDStream.backWithStream(Stream(value : courseID))
    }
}

extension CourseLessonsViewController {
    fileprivate func addRightBarButtonsItems() {
        let menuButtonItem = UIBarButtonItem(image: UIImage(named: "menu"),
                                            style: .plain,
                                            target: self,
                                            action: #selector(self.showMenu))

        self.navigationItem.rightBarButtonItems = [menuButtonItem]
    }
    
    @objc fileprivate func showMenu()  {
        environment.router?.showMenuAlert(controller: self, courseId: self.courseID)
    }
    
    fileprivate func applyThemeingToStatsTopView() {
        if let image = UIImage(named: "navigationBarBackground") {
            let color = BrandingThemes.shared.getNavigationBarColor()
            let colorImage = UIImage.image(from: color, size: image.size)
            let blended = image.blendendImage(with: colorImage, blendMode: .normal, alpha: 1.0)
            StatsTopViewBackgroundImageView.image = blended
        } else {
            statsTopView.backgroundColor = BrandingThemes.shared.getNavigationBarColor()
        }
    }
}

extension CourseLessonsViewController {
    func getCourseProgressStatsStream() -> edXCore.Stream<ProgressStats> {
        let request = CourseProgressAPI.getProgressFor(courseId: self.courseID)
        return self.environment.networkManager.streamForRequest(request, persistResponse: true)
    }
}
