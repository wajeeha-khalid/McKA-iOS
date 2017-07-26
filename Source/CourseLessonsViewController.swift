//
//  CourseLessonsViewController.swift
//  edX
//
//  Created by Shafqat Muneer on 7/17/17.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

enum LessonProgressState {
    case complete
    case inProgress
    case notStarted
}

struct LessonViewModel {
    let state: LessonProgressState
    let title: String
    let number: Int
}

public class CourseLessonsViewController: OfflineSupportViewController, UITableViewDelegate, UITableViewDataSource {
    
    public typealias Environment = protocol<OEXAnalyticsProvider, OEXConfigProvider, DataManagerProvider, NetworkManagerProvider, ReachabilityProvider, OEXRouterProvider, OEXInterfaceProvider, OEXRouterProvider, OEXSessionProvider, OEXConfigProvider>
    
    private let environment: Environment
    private let courseID: String
    private let blockIDStream = BackedStream<CourseBlockID?>()
    private let courseQuerier : CourseOutlineQuerier
    private let loadController : LoadStateViewController
    private var courseLoadingStream: Stream<CourseOutlineQuerier.BlockGroup>
    private var progressLoadingStream: Any?
    private var titleType : TitleType
    private var lesssons : [CourseBlock] = []
    var downloadController  : DownloadController
    var lessonViewModel: [LessonViewModel] = []
    
    @IBOutlet weak var lessonsTableView: UITableView!
    
    public init(environment: Environment, courseID: String, rootID : CourseBlockID?) {
        self.environment = environment
        self.courseID = courseID
        courseQuerier = environment.dataManager.courseDataManager.querierForCourseWithID(courseID)
        courseLoadingStream = courseQuerier.childrenOfBlockWithID(nil)
        loadController = LoadStateViewController()
        titleType = TitleType.NavTitle
        downloadController  = DownloadController(courseQuerier: courseQuerier, analytics: environment.analytics)
        super.init(env : environment)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.lessonsTableView.registerNib(UINib(nibName: "CourseLessonTableViewCell", bundle: nil), forCellReuseIdentifier: "CourseLessonTableViewCell")
        
        let courseStream = BackedStream<UserCourseEnrollment>()
        courseStream.backWithStream(environment.dataManager.enrollmentManager.streamForCourseWithID(courseID))
        courseStream.listenOnce(self) {[weak self] in
            self?.resultLoaded($0)
        }
        
        self.addListeners()
    }
    
    private func resultLoaded(result : Result<UserCourseEnrollment>) {
        switch result {
        case let .Success(enrollment):
            self.loadedCourseWithEnrollment(enrollment)
        case let .Failure(error):
            debugPrint("Enrollment error: \(error)")
            break
        }
    }
    
    private func loadedCourseWithEnrollment(enrollment: UserCourseEnrollment) {
        navigationItem.title = enrollment.course.name
    }
    
    //MARK: Listener Method
    private func addListeners() {
        let progressStreams = courseLoadingStream.transform { group -> Stream<[(CourseBlock, LessonProgressState)]> in
            let streams =  group.children.map { lesson in
                return self.progressForLesson(withID: lesson.blockID).map { progress in
                    (lesson, progress)
                }
            }
            return joinStreams(streams)
            }.map { progressStates in
                progressStates.enumerate().map{ (index, blockState)  in
                    return LessonViewModel(state: blockState.1, title: blockState.0.displayName, number:index )
                }
        }
        
        progressStreams.listen(self) { result in
            switch result {
            case .Success(let values):
                self.lessonViewModel = values
                self.lessonsTableView.reloadData()
            case .Failure:
                break
            }
        }
        
        self.progressLoadingStream = progressStreams
    }
    
    //MARK: Calculate Progress
    private func progressForLesson(withID lessonID: CourseBlockID)  -> Stream<LessonProgressState> {
        
        func units(for lessonID: CourseBlockID) -> Stream<[CourseBlock]> {
            return courseQuerier.childrenOfBlockWithID(lessonID).transform { lesson -> Stream<[CourseBlock]> in
                let x = lesson.children.map({ section in
                    self.courseQuerier.childrenOfBlockWithID(section.blockID).map {
                        $0.children
                    }
                })
                
                let flattened = joinStreams(x).map {
                    $0.flatMap { $0 }
                }
                
                return flattened
            }
        }
        
        func numberOfUnits(for lessonID: CourseBlockID) -> Stream<Int> {
            return units(for: lessonID).map { $0.count }
        }
        
        
        return numberOfUnits(for: lessonID).transform { totalUnitCount in
            let completedUnits = self.environment.interface?.getCompletedUnitsForChapterID(lessonID)
            if completedUnits?.count == totalUnitCount {
                return Stream(value: .complete)
            } else if completedUnits?.count > 0 {
                return Stream(value: .inProgress)
            } else {
                
                let lessonUnits = units(for: lessonID).transform { units -> Stream<[LessonProgressState]> in
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
    
    private func progressForUnit(withID unitID: CourseBlockID) -> Stream<LessonProgressState> {
        
        func numberOfComponentsInUnit(withID unitID: CourseBlockID) -> Stream<Int> {
            return courseQuerier.childrenOfBlockWithID(unitID).map {
                $0.children.count
            }
        }
        
        return numberOfComponentsInUnit(withID: unitID).map { totalComponentCount in
            let viewedComponents = self.environment.interface?.getViewedComponentsForVertical(unitID)
            if viewedComponents?.count == totalComponentCount {
                return .complete
            } else if viewedComponents?.count > 0 {
                return .inProgress
            } else {
                return .notStarted
            }
        }
    }
    
    //MARK: Tableview DataSource
    public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 125
    }
    
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.lessonViewModel.count
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let lessonCell = tableView.dequeueReusableCellWithIdentifier("CourseLessonTableViewCell") as! CourseLessonTableViewCell
        lessonCell.selectionStyle = UITableViewCellSelectionStyle.None
        lessonCell.lessonViewModel = lessonViewModel[indexPath.row]
        return lessonCell
    }
    
    public func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 15
    }
    
    public func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.clearColor()
        return headerView
    }
    
    //MARK: Table view delegate
    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.environment.router?.showCoursewareForCourseWithID(self.courseID, fromController: self)
    }
    
    override public func didReceiveMemoryWarning() {
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
