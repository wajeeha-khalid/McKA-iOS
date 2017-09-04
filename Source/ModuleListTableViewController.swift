//
//  ModuleListTableViewController.swift
//  edX
//
//  Created by Salman Jamil on 8/25/17.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

struct ModuleViewModel {
    let identifier: CourseBlockID
    let title: String
    let progress: ComponentProgressState
    let duration: Int
    let number: Int
    
    
    func apply(to cell: ModuleTableViewCell) {
        cell.progressLabel.text = progress.description
        cell.titleLabel.text = "\(number). \(title)"
        cell.progressImageView.image = progress.image
    }
}

fileprivate struct ModuleListOffsets {
    static  let horizontalOffset = 30.0
    static let verticalOffset = 23.0
    static let headerVerticalOffset = 15.0
}

final class ModuleTableHeaderView: UIView {
    
    let titleLabel = UILabel()
    let moduleCountLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
        addSubview(moduleCountLabel)
        
        titleLabel.font = UIFont.systemFont(ofSize: 14.0)
        titleLabel.textColor = UIColor.darkGray
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(self).offset(ModuleListOffsets.horizontalOffset)
            make.top.equalTo(self).offset(ModuleListOffsets.verticalOffset)
        }
        
        moduleCountLabel.textColor = UIColor.black
        moduleCountLabel.font = UIFont.boldSystemFont(ofSize: 24.0)
        moduleCountLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(5.0)
            make.bottom.equalTo(self).offset(-ModuleListOffsets.headerVerticalOffset)
        }
        
        let seperatorView = UIView()
        self.addSubview(seperatorView)
        seperatorView.backgroundColor = UIColor.lightGray
        seperatorView.snp.makeConstraints { make in
            make.leading.equalTo(self).offset(ModuleListOffsets.horizontalOffset)
            make.trailing.equalTo(self).offset(-ModuleListOffsets.horizontalOffset)
            make.height.equalTo(0.5)
            make.bottom.equalTo(self)
        }
        
        backgroundColor = UIColor.white
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class ModuleTableViewCell: UITableViewCell {
    
    
    let titleLabel = UILabel()
    let progressLabel =  UILabel()
    let progressImageView = UIImageView()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(titleLabel)
        contentView.addSubview(progressLabel)
        contentView.addSubview(progressImageView)
        
        titleLabel.font = UIFont.systemFont(ofSize: 16.0)
        titleLabel.textColor = UIColor.black
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(contentView).offset(ModuleListOffsets.horizontalOffset)
            make.top.equalTo(contentView).offset(ModuleListOffsets.verticalOffset)
            make.trailing.lessThanOrEqualTo(progressImageView.snp.leading).offset(-20)
        }
        
        progressLabel.font = UIFont.systemFont(ofSize: 12.0)
        progressLabel.textColor = UIColor(red:0.45, green:0.56, blue:0.65, alpha:1)
        progressLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(5.0)
            make.bottom.equalTo(contentView).offset(-ModuleListOffsets.verticalOffset)
        }
        
        progressImageView.snp.makeConstraints { make in
            make.centerY.equalTo(contentView)
            make.trailing.equalTo(contentView).offset(-ModuleListOffsets.horizontalOffset)
        }
        
        let seperatorView = UIView()
        contentView.addSubview(seperatorView)
        seperatorView.backgroundColor = UIColor.lightGray
        seperatorView.snp.makeConstraints { make in
            make.leading.equalTo(contentView).offset(ModuleListOffsets.horizontalOffset)
            make.trailing.equalTo(contentView).offset(-ModuleListOffsets.horizontalOffset)
            make.height.equalTo(0.5)
            make.bottom.equalTo(contentView)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


protocol ModuleTableViewControllerDelegate: class {
    func moduleTableViewController(_ vc: ModuleTableViewController, didSelectModuleWithID moduleId: CourseBlockID)
}



class ModuleTableViewController: UITableViewController {
    
    let lessonTitle: String
    let modules: [ModuleViewModel]
    private let reuseIdentifier = "ModuleListCell"
    let headerView = ModuleTableHeaderView()
    weak var delegate: ModuleTableViewControllerDelegate?
    
    init(lessonTitle: String, modules: [ModuleViewModel]) {
        self.lessonTitle = lessonTitle
        self.modules = modules
        super.init(style: .plain)
        tableView.register(ModuleTableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.estimatedRowHeight = 70
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        headerView.titleLabel.text = lessonTitle
        headerView.moduleCountLabel.text = formattedStringWith(unitCount: modules.count, unitSingular: "Module")
    }
    
    func formattedStringWith(unitCount : Int,
                             unitSingular: String, unitPlural: String? = nil) -> String {
        let unitPlural = unitPlural ?? "\(unitSingular)s"
        switch unitCount {
        case 0:
            return "No \(unitSingular)"
        case 1:
            return "1 \(unitSingular)"
        case let x:
            return "\(x) \(unitPlural)"
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return modules.count
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let size = headerView.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
        return size.height
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return headerView
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! ModuleTableViewCell
        modules[indexPath.row].apply(to: cell)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        delegate?.moduleTableViewController(self, didSelectModuleWithID: modules[indexPath.row].identifier)
    }
}
