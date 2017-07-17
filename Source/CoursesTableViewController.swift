//
//  CoursesTableViewController.swift
//  edX
//
//  Created by Anna Callahan on 10/15/15.
//  Copyright © 2015 edX. All rights reserved.
//

import UIKit
import Kingfisher

class CourseCardCell : UITableViewCell {
    static let margin = 15.0
    
    private static let cellIdentifier = "CourseCardCell"
    private let courseView = NewCourseCardView(frame: CGRectZero)
    private var course : OEXCourse?
    private let courseCardBorderStyle = BorderStyle()
    
    override init(style : UITableViewCellStyle, reuseIdentifier : String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.contentView.addSubview(courseView)
        
        courseView.snp_makeConstraints {make in
            make.top.equalTo(self.contentView).offset(CourseCardCell.margin)
            make.bottom.equalTo(self.contentView)
            make.leading.equalTo(self.contentView).offset(CourseCardCell.margin)
            make.trailing.equalTo(self.contentView).offset(-CourseCardCell.margin)
        }
        
        courseView.applyBorderStyle(courseCardBorderStyle)
        
        self.contentView.backgroundColor = OEXStyles.sharedStyles().neutralXLight()
        
        self.selectionStyle = .None
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        courseView.imageView.lastRemoteTask?.remove()
    } 
}

protocol CoursesTableViewControllerDelegate : class {
    func coursesTableChoseCourse(course : OEXCourse)
}

struct CourseViewModel {
    var title: String? {
        return course.name
    }
    var lessonCount: Int?
    var progress: CourseProgress {
        if let progress = (course.progress?.doubleValue).map({round($0)}).map({Int($0)}) {
            if  progress == 100 {
                return .completed
            }
            if progress == 0 {
                return .notStarted
            }
            return .inPorgress(progress: Int(progress))
        } else {
            return .notStarted
        }
    }
    var courseImageURL: String? {
        return course.courseImageURL
    }
    let persistImage: Bool
    let course: OEXCourse
    var courseID: String? {
        return course.course_id
    }
    
    func apply(newCard card: NewCourseCardView, networkManager: NetworkManager) {
        if let lessonCount = lessonCount {
            card.lessonText = "\(lessonCount) lessons"
        } else {
            card.lessonText = "fetching lesson count..."
        }
        card.couseTitle = title
        card.progress = progress
        
        let placeholder = UIImage(named: "placeholderCourseCardImage")
        let URL = courseImageURL.flatMap {
            NSURL(string: $0, relativeToURL: networkManager.baseURL)
        }
        // We are switching to Kingfisher because `RemoteImage` currently has some probelms 
        // especially with cell reuse in tableView...
        card.imageView.kf_setImageWithURL(URL, placeholderImage: placeholder)
    }
}

class CoursesTableViewController: UITableViewController {
    
    enum Context {
        case CourseCatalog
        case EnrollmentList
    }
    
    typealias Environment = protocol<NetworkManagerProvider, OEXRouterProvider, DataManagerProvider>
    
    private let environment : Environment
    private let context: Context
    weak var delegate : CoursesTableViewControllerDelegate?
    var streams: [Stream<Int>] = []
    private var _courses: [CourseViewModel] = []
    
    var courses : [CourseViewModel]  {
        get {
            return _courses
        }
        set(courses) {
           _courses = courses
            streams.removeAll()
            courses.forEach { (course) in
                let querier = self.environment.dataManager.courseDataManager.querierForCourseWithID(course.courseID!)
                let stream = querier.childrenOfBlockWithID(nil).transform({ group in
                    return Stream(value: group.children.count)
                })
                stream.listen(self) { [weak self] result in
                    guard let owner = self else {
                        return
                    }
                    
                    let indexOfStream = owner.streams.indexOf {
                        $0 === stream
                    }
                    if let indexOfStream = indexOfStream {
                        owner.streams.removeAtIndex(indexOfStream)
                    }
                    
                    switch result {
                    case .Success(let count):
                        if let index = owner.index(for: course.courseID!) {
                            var course = owner.courses[index]
                            course.lessonCount = count
                            owner._courses[index] = course
                            //TODO: Ideally we would like to reload individual rows but currently that is having some problem when a user is un enrolled from course...
                            owner.tableView.reloadData()
                        }
                    case .Failure:
                        break
                    }
                }
                streams.append(stream)
            }
        }
    }
    
    func index(for courseID: String) -> Int? {
        return courses.indexOf { course in
            course.courseID == courseID
        }
    }
    
    let insetsController = ContentInsetsController()
    
    init(environment : Environment, context: Context) {
        self.context = context
        self.environment = environment
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.separatorStyle = .None
        self.tableView.backgroundColor = OEXStyles.sharedStyles().neutralXLight()
        self.tableView.accessibilityIdentifier = "courses-table-view"
        
        self.tableView.snp_makeConstraints {make in
            make.edges.equalTo(self.view)
        }
        
        tableView.registerClass(CourseCardCell.self, forCellReuseIdentifier: CourseCardCell.cellIdentifier)
        
        self.insetsController.addSource(
            ConstantInsetsSource(insets: UIEdgeInsets(top: 0, left: 0, bottom: StandardVerticalMargin, right: 0), affectsScrollIndicators: false)
        )
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.courses.count ?? 0
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let availableHeight = tableView.frame.size.height
        let numberOfRows = courses.count
        let rowHeight = availableHeight / CGFloat(numberOfRows)
        let maxRowsWithMinHeight = Int(availableHeight - 15) / 120
        let maxHeight = availableHeight / 2
        if rowHeight > maxHeight {
            return maxHeight
        }
        if numberOfRows <= maxRowsWithMinHeight {
            return (availableHeight - 15) / CGFloat(numberOfRows)
        } else {
            return 160
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let course = self.courses[indexPath.row]
        
        let cell = tableView.dequeueReusableCellWithIdentifier(CourseCardCell.cellIdentifier, forIndexPath: indexPath) as! CourseCardCell

        cell.accessibilityLabel = course.title
        cell.accessibilityHint = Strings.accessibilityShowsCourseContent
        
        cell.courseView.tapAction = {[weak self] card in
            //self?.delegate?.coursesTableChoseCourse(course)
           self!.environment.router?.showCoursewareForCourseWithID(course.courseID!, fromController: self!)
        }
        
        course.apply(newCard: cell.courseView, networkManager: environment.networkManager)
        cell.course = course.course

        return cell
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.insetsController.updateInsets()
    }
}
