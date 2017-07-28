//
//  DebugMenuViewController.swift
//  edX
//
//  Created by Michael Katz on 11/19/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

private enum Rows: Int {
    case appVersion, environment, console, count

    static var rowCount: Int { return count.rawValue }

    func decorateCell(_ config: OEXConfig, cell: UITableViewCell) {
        switch self {
        case .appVersion:
            let appVersion = Bundle.main.oex_shortVersionString()
            cell.textLabel?.text = "Version: \(appVersion)"
        case .environment:
            let environmentName = config.environmentName()
            cell.textLabel?.text = "Environment: \(environmentName)"
        case .console:
            cell.textLabel?.text = "Debug Console"
            cell.accessoryType = .disclosureIndicator
        case .count:
            fatalError("should not get here")
        }
    }
}


class DebugMenuViewController: UITableViewController {
    typealias Environment = OEXConfigProvider

    let environment: Environment

    init(environment: Environment) {
        self.environment = environment
        super.init(style: .plain)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Debug"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Rows.rowCount
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        let row = Rows(rawValue: indexPath.row)
        row?.decorateCell(environment.config, cell: cell)

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let console = DebugLogViewController()
        navigationController?.pushViewController(console, animated: true)
    }

}
