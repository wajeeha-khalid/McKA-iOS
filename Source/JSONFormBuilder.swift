//
//  JSONFormBuilder.swift
//  edX
//
//  Created by Michael Katz on 9/29/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation
import edXCore
import SwiftyJSON

private func equalsCaseInsensitive(_ lhs: String, _ rhs: String) -> Bool {
    return lhs.caseInsensitiveCompare(rhs) == .orderedSame
}

/** Model for the built form must allow for reads and updates */
protocol FormData {
    func valueForField(_ key: String) -> String?
    func displayValueForKey(_ key: String) -> String?
    func setValue(_ value: String?, key: String)
}

/** Decorate the cell with the model object */
protocol FormCell  {
    func applyData(_ field: JSONFormBuilder.Field, data: FormData)
}

private func loadJSON(_ jsonFile: String) throws -> JSON {
    var js: JSON
    if let filePath = Bundle.main.path(forResource: jsonFile, ofType: "json") {
        if let data = NSData(contentsOfFile: filePath)  {
            var error: NSError?
            js = JSON(data: data as Data, error: &error)
            if error != nil { throw error! }
        } else {
            js = JSON(NSNull())
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadUnknownError, userInfo: nil)
        }
    }  else {
        js = JSON(NSNull())
        throw NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil)
    }
    return js
}

/** Function to turn a specialized JSON file (https://openedx.atlassian.net/wiki/display/MA/Profile+Forms) into table rows, with various editor views and view controllers */
class JSONFormBuilder {
    
    /** Show a segmented control from a limited set of options */
    class SegmentCell: UITableViewCell, FormCell {
        static let Identifier = "JSONForm.SwitchCell"

        let titleLabel = UILabel()
        let descriptionLabel = UILabel()
        let typeControl = UISegmentedControl()
        var values = [String]()
        
        override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            
            typeControl.tintColor = OEXStyles.shared().piqueGreenColor()
            typeControl.layer.borderColor = UIColor.gray.cgColor
            contentView.addSubview(titleLabel)
            contentView.addSubview(typeControl)
            contentView.addSubview(descriptionLabel)
            
            titleLabel.textAlignment = .natural
            
            descriptionLabel.textAlignment = .natural
            descriptionLabel.numberOfLines = 0
            descriptionLabel.preferredMaxLayoutWidth = 200 //value doesn't seem to matter as long as it's small enough
            
            titleLabel.snp.makeConstraints { (make) -> Void in
                make.leading.equalTo(contentView.snp.leadingMargin)
                make.top.equalTo(contentView.snp.topMargin)
                make.trailing.equalTo(contentView.snp.trailingMargin)
            }
            
            typeControl.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(titleLabel.snp.bottom).offset(6)
                make.leading.equalTo(contentView.snp.leadingMargin)
                make.trailing.equalTo(contentView.snp.trailingMargin)
            }
            
            descriptionLabel.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(typeControl.snp.bottom).offset(6)
                make.leading.equalTo(contentView.snp.leadingMargin)
                make.trailing.equalTo(contentView.snp.trailingMargin)
                make.bottom.equalTo(contentView.snp.bottomMargin)
            }
        }
        
        func applyData(_ field: JSONFormBuilder.Field, data: FormData) {
            let titleStyle = OEXTextStyle(weight: .normal, size: .base, color: OEXStyles.shared().neutralBlackT())
            let descriptionStyle = OEXMutableTextStyle(weight: .light, size: .xSmall, color: OEXStyles.shared().neutralDark())
            descriptionStyle.lineBreakMode = .byTruncatingTail
            
            titleLabel.attributedText = titleStyle.attributedString(withText: field.title)
            descriptionLabel.attributedText = descriptionStyle.attributedString(withText: field.instructions)
            
            if let hint = field.accessibilityHint {
                typeControl.accessibilityHint = hint
            }
            
            values.removeAll(keepingCapacity: true)
            typeControl.removeAllSegments()
            if let optionsValues = field.options?["values"]?.arrayObject {
                for valueDict in optionsValues {
                    let dict = valueDict as? NSDictionary
                    let title = dict?["name"] as! String
                    let value = dict?["value"] as! String
                    typeControl.insertSegment(withTitle: title, at: values.count, animated: false)
                    values.append(value)
                }

            }
            
            if let val = data.valueForField(field.name), let selectedIndex = values.index(of: val) {
                typeControl.selectedSegmentIndex = selectedIndex
            }

        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    /** Show a cell that provides a long list of options in a new viewcontroller */
    class OptionsCell: UITableViewCell, FormCell {
        static let Identifier = "JSONForm.OptionsCell"
        fileprivate let choiceView = ChoiceLabel()
        
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            setup()
        }
        
        override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            setup()
        }
        
        func setup() {
            accessoryType = .disclosureIndicator
            contentView.addSubview(choiceView)
            choiceView.snp.makeConstraints { (make) -> Void in
                make.edges.equalTo(contentView).inset(UIEdgeInsets(top: 0, left: StandardHorizontalMargin, bottom: 0, right: StandardHorizontalMargin))
            }
        }
        
        func applyData(_ field: Field, data: FormData) {
            choiceView.titleText = Strings.formLabel(label: field.title!)
            choiceView.valueText = data.displayValueForKey(field.name) ?? field.placeholder ?? ""
        }
    }
    
    /** Show an editable text area in a new view */
    class TextAreaCell: UITableViewCell, FormCell {
        static let Identifier = "JSONForm.TextAreaCell"
        fileprivate let choiceView = ChoiceLabel()
        
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            setup()
        }

        override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            setup()
        }
        
        func setup() {
            accessoryType = .disclosureIndicator
            contentView.addSubview(choiceView)
            choiceView.snp.makeConstraints { (make) -> Void in
                make.edges.equalTo(contentView).inset(UIEdgeInsets(top: 0, left: StandardHorizontalMargin, bottom: 0, right: StandardHorizontalMargin))
            }
        }
        
        func applyData(_ field: Field, data: FormData) {
            choiceView.titleText = Strings.formLabel(label: field.title ?? "")
            let placeholderText = field.placeholder
            choiceView.valueText = data.valueForField(field.name) ?? placeholderText ?? ""
        }
    }
    
    /** Add the cell types to the tableview */
    static func registerCells(_ tableView: UITableView) {
        tableView.register(OptionsCell.self, forCellReuseIdentifier: OptionsCell.Identifier)
        tableView.register(TextAreaCell.self, forCellReuseIdentifier: TextAreaCell.Identifier)
        tableView.register(SegmentCell.self, forCellReuseIdentifier: SegmentCell.Identifier)
    }
    
    /** Fields parsed out of the json. Each field corresponds to it's own row with specialized editor */
    struct Field {
        enum FieldType: String {
            case Select = "select"
            case TextArea = "textarea"
            case Switch = "switch"
            
            init?(jsonVal: String?) {
                if let str = jsonVal {
                    if let type = FieldType(rawValue: str) {
                        self = type
                    } else {
                        return nil
                    }
                } else {
                    return nil
                }
            }
            
            var cellIdentifier: String {
                switch self {
                case .Select:
                    return OptionsCell.Identifier
                case .TextArea:
                    return TextAreaCell.Identifier
                case .Switch:
                    return SegmentCell.Identifier
                }
            }
        }

        //Field Data types Supported by the form builder
        enum DataType : String {
            case StringType = "string"
            case CountryType = "country"
            case LanguageType = "language"
            
            init(_ rawValue: String?) {
                guard let val = rawValue else { self = .StringType; return }                
                switch val {
                case "country":
                    self = .CountryType
                case "language":
                    self = .LanguageType
                default:
                    self = .StringType
                }
            }
        }
        
        let type: FieldType
        let name: String
        var cellIdentifier: String { return type.cellIdentifier }
        var title: String?
        
        let instructions: String?
        let subInstructions: String?
        let accessibilityHint: String?
        let options: [String: JSON]?
        let dataType: DataType
        let defaultValue: String?
        let placeholder: String?
        
        init (json: JSON) {
            type = FieldType(jsonVal: json["type"].string)!
            title = json["label"].string
            name = json["name"].string!
            
            instructions = json["instructions"].string
            subInstructions = json["sub_instructions"].string
            options = json["options"].dictionary
            dataType = DataType(json["data_type"].string)
            defaultValue = json["default"].string
            accessibilityHint = json["accessibility_hint"].string
            placeholder = json["placeholder"].string
        }
        
        fileprivate func attributedChooserRow(_ icon: Icon, title: String, value: String?) -> NSAttributedString {
            let iconStyle = OEXTextStyle(weight: .normal, size: .base, color: OEXStyles.shared().neutralBase())
            let icon = icon.attributedTextWithStyle(iconStyle)
            
            let titleStyle = OEXTextStyle(weight: .normal, size: .base, color: OEXStyles.shared().neutralBlackT())
            let titleAttrStr = titleStyle.attributedString(withText: " " + title)
            
            let valueStyle = OEXTextStyle(weight: .normal, size: .base, color: OEXStyles.shared().neutralDark())
            let valAttrString = valueStyle.attributedString(withText: value)
            
            return  NSAttributedString.joinInNaturalLayout([icon, titleAttrStr, valAttrString])
        }
        
        fileprivate func selectAction(_ data: FormData, controller: UIViewController) {
            let selectionController = JSONFormTableViewController<String>()
            var tableData = [ChooserDatum<String>]()
            
            if let rangeMin:Int = options?["range_min"]?.int, let rangeMax:Int = options?["range_max"]?.int {
                let range = rangeMin...rangeMax
                let titles = range.map { String($0)} .reversed()
                tableData = titles.map { ChooserDatum(value: $0, title: $0, attributedTitle: nil) }
            } else if let file = options?["reference"]?.string {
                do {
                    let json = try loadJSON(file)
                    if let values = json.array {
                        tableData = values.map { ChooserDatum(value: $0["value"].string!, title: $0["name"].string, attributedTitle: nil)}
                    }
                } catch {
                    Logger.logError("JSON", "Error parsing JSON: \(error)")
                }
            }
            
            var defaultRow = -1
            
            let allowsNone = options?["allows_none"]?.bool ?? false
            if allowsNone {
                let noneTitle = Strings.Profile.noField(fieldName: title!.oex_lowercaseStringInCurrentLocale())
                tableData.insert(ChooserDatum(value: "--", title: noneTitle, attributedTitle: nil), at: 0)
                defaultRow = 0
            }
            
            if let alreadySetValue = data.valueForField(name) {
                defaultRow = tableData.index { equalsCaseInsensitive($0.value, alreadySetValue) } ?? defaultRow
            }
            
            if dataType == .CountryType {
                if let id = (Locale.current as NSLocale).object(forKey: NSLocale.Key.countryCode) as? String {
                    let countryName = (Locale.current as NSLocale).displayName(forKey: NSLocale.Key.countryCode, value: id)
                    let title = attributedChooserRow(Icon.country, title: Strings.Profile.currentLocationLabel, value: countryName)
                    
                    tableData.insert(ChooserDatum(value: id, title: nil, attributedTitle: title), at: 0)
                    if defaultRow >= 0 { defaultRow += 1 }
                }
            } else if dataType == .LanguageType {
                if let id = (Locale.current as NSLocale).object(forKey: NSLocale.Key.languageCode) as? String {
                    let languageName = (Locale.current as NSLocale).displayName(forKey: NSLocale.Key.languageCode, value: id)
                    let title = attributedChooserRow(Icon.comment, title: Strings.Profile.currentLanguageLabel, value: languageName)
                    
                    tableData.insert(ChooserDatum(value: id, title: nil, attributedTitle: title), at: 0)
                    if defaultRow >= 0 { defaultRow += 1 }
                }
            }
            
            let dataSource = ChooserDataSource(data: tableData)
            dataSource.selectedIndex = defaultRow
            
            
            selectionController.dataSource = dataSource
            selectionController.title = title
            selectionController.instructions = instructions
            selectionController.subInstructions = subInstructions
            
            selectionController.doneChoosing = { value in
                if allowsNone && value != nil && value! == "--" {
                    data.setValue(nil, key: self.name)
                } else {
                    data.setValue(value, key: self.name)
                }
            }
            
            controller.navigationController?.pushViewController(selectionController, animated: true)
        }
        
        /** What happens when the user selects the row */
        func takeAction(_ data: FormData, controller: UIViewController) {
            switch type {
            case .Select:
               selectAction(data, controller: controller)
            case .TextArea:
                let text = data.valueForField(name)
                let textController = JSONFormBuilderTextEditorViewController(text: text, placeholder: placeholder)
                textController.title = title
                
                textController.doneEditing = { value in
                    if value == "" {
                        data.setValue(nil, key: self.name)
                    } else {
                        data.setValue(value, key: self.name)
                    }
                }
                
                controller.navigationController?.pushViewController(textController, animated: true)
            case .Switch:
                //no action on cell selection - let control in cell handle action
                break;
            }
        }
    }
    
    let json: JSON
    lazy var fields: [Field]? = {
        return self.json["fields"].array?.map { return Field(json: $0) }
        }()

    
    init?(jsonFile: String) {
        do {
            json = try loadJSON(jsonFile)
        } catch {
            json = JSON(NSNull())
            return nil
        }
    }
    
    init(json: JSON) {
        self.json = json
    }
    
}

