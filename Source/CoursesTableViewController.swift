//
//  CoursesTableViewController.swift
//  edX
//
//  Created by Anna Callahan on 10/15/15.
//  Copyright © 2015 edX. All rights reserved.
//

import UIKit
import Kingfisher
import SnapKit
class CourseCardCell : UITableViewCell {
    static let margin = 15.0
    
    fileprivate static let cellIdentifier = "CourseCardCell"
    fileprivate let courseView = NewCourseCardView(frame: CGRect.zero)
    fileprivate var course : OEXCourse?
    fileprivate let courseCardBorderStyle = BorderStyle()
    
    override init(style : UITableViewCellStyle, reuseIdentifier : String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.contentView.addSubview(courseView)
        
        courseView.snp.makeConstraints {make in
            make.top.equalTo(self.contentView).offset(CourseCardCell.margin)
            make.bottom.equalTo(self.contentView)
            make.leading.equalTo(self.contentView).offset(CourseCardCell.margin)
            make.trailing.equalTo(self.contentView).offset(-CourseCardCell.margin)
        }
        
        courseView.applyBorderStyle(courseCardBorderStyle)
        
        self.contentView.backgroundColor = OEXStyles.shared.neutralWhiteT()
        
        self.selectionStyle = .none
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
    func coursesTableChoseCourse(_ course : OEXCourse)
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
        
        card.lessonText = formattedLessonCount
        card.couseTitle = title
        card.progress = progress
        
        let placeholder = UIImage(named: "placeholderCourseCardImage")
        let url = courseImageURL.flatMap {
            URL(string: $0, relativeTo: networkManager.baseURL)
        }
        // We are switching to Kingfisher because `RemoteImage` currently has some probelms 
        // especially with cell reuse in tableView...
        card.imageView.kf.setImage(with:url, placeholder: placeholder)
    }
    
    var formattedLessonCount: String {
        if let lessonCount = lessonCount {
            if lessonCount > 1 {
                return "\( lessonCount) Lessons"
            } else {
                return "\(lessonCount) Lesson"
            }
        } else {
            return "fetching lesson count..."
        }
    }
    
}

class CoursesTableViewController: UITableViewController {
    
    enum Context {
        case courseCatalog
        case enrollmentList
    }
    
    typealias Environment = NetworkManagerProvider & OEXRouterProvider & DataManagerProvider
    
    fileprivate let environment : Environment
    fileprivate let context: Context
    weak var delegate : CoursesTableViewControllerDelegate?
    var streams: [edXCore.Stream<Int>] = []
    fileprivate var _courses: [CourseViewModel] = []
    
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
                    return Stream(
                        value: group.children.filter({ (lesson) -> Bool in
                            return lesson.displayName.lowercased().contains("discussion_course") == false
                        }).count
                    )
                })
                stream.listen(self) { [weak self] result in
                    guard let owner = self else {
                        return
                    }
                    
                    let indexOfStream = owner.streams.index {
                        $0 === stream
                    }
                    if let indexOfStream = indexOfStream {
                        owner.streams.remove(at: indexOfStream)
                    }
                    
                    switch result {
                    case .success(let count):
                        if let index = owner.index(for: course.courseID!) {
                            var course = owner.courses[index]
                            course.lessonCount = count
                            owner._courses[index] = course
                            //TODO: Ideally we would like to reload individual rows but currently that is having some problem when a user is un enrolled from course...
                            owner.tableView.reloadData()
                        }
                    case .failure:
                        break
                    }
                }
                streams.append(stream)
            }
        }
    }
    
    func index(for courseID: String) -> Int? {
        return courses.index { course in
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
        self.tableView.separatorStyle = .none
        self.tableView.backgroundColor = OEXStyles.shared.neutralXLight()
        self.tableView.accessibilityIdentifier = "courses-table-view"
        
        self.tableView.snp.makeConstraints {make in
            make.edges.equalTo(self.view)
        }
        
        tableView.register(CourseCardCell.self, forCellReuseIdentifier: CourseCardCell.cellIdentifier)
        
        self.insetsController.addSource(
            ConstantInsetsSource(insets: UIEdgeInsets(top: 0, left: 0, bottom: StandardVerticalMargin, right: 0), affectsScrollIndicators: false)
        )
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.courses.count 
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
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

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let course = self.courses[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: CourseCardCell.cellIdentifier, for: indexPath) as! CourseCardCell

        cell.accessibilityLabel = course.title
        cell.accessibilityHint = Strings.accessibilityShowsCourseContent
        
        cell.courseView.tapAction = {[weak self] card in
            //self?.delegate?.coursesTableChoseCourse(course)
            self!.environment.router?.showLessonForCourseWithID(course.courseID!, fromController: self!)
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
