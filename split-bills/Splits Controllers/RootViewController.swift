//
//  ViewController.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 6/8/18.
//  Copyright © 2018 Carlos Miguel de Elias. All rights reserved.
//

import UIKit
import SnapKit

final class RootViewController: UIViewController, NewSplitViewControllerDelegate, UITableViewDataSource {

    private let tableView = UITableView()

    private var splits = SplitController.shared.getAll() ?? []

    override func viewDidLoad() {
        super.viewDidLoad()

        buildView()
        buildLayout()
    }

    private func buildView() {
        title = "Home"
        view.backgroundColor = .white

        let newSplitButton = UIBarButtonItem(title: "New split", style: .plain, target: self, action: #selector(newSplitButtonTapped))
        self.navigationItem.rightBarButtonItem = newSplitButton

        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        view.addSubview(tableView)
    }

    private func buildLayout() {
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    @objc private func newSplitButtonTapped() {
        let viewController = NewSplitViewController()
        viewController.delegate = self
        self.navigationController!.pushViewController(viewController, animated: true)
    }

    // MARK: UITableViewDataSource methods

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return splits.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "SplitCell")

        let split = splits[indexPath.row]
        cell.textLabel?.text = split.eventName
        cell.detailTextLabel?.text = split.name

        return cell
    }

    // MARK: NewSplitViewControllerDelegate methods

    func didCreateNewSplit(_ split: Split) {
        SplitController.shared.add(split: split)
        splits.append(split)
        tableView.reloadData()
    }
}

extension UIButton {

    static func defaultButton(withTitle title: String) -> UIButton {
        let button = UIButton(type: .custom)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.blue, for: .normal)

        return button
    }
}
