//
//  ViewController.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 6/8/18.
//  Copyright © 2018 Carlos Miguel de Elias. All rights reserved.
//

import UIKit
import SnapKit

final class RootViewController: UIViewController, NewSplitViewControllerDelegate, UITableViewDataSource, UITableViewDelegate {

    private let headerView = UIView()
    private let titleView = UILabel(style: .headingWhite)
    private let tableView = UITableView()
    private let newBillButton = UIButton(title: "New Bill", style: .brandBold)

    private var splits = SplitController.shared.getAll() ?? []

    override func viewDidLoad() {
        super.viewDidLoad()

        buildView()
        buildLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController!.isNavigationBarHidden = true
    }

    private func buildView() {
        view.backgroundColor = Color.white.value

        headerView.backgroundColor = Color.brand.value
        headerView.alpha = 0.8
        view.addSubview(headerView)

        titleView.text = "Split Bills"
        headerView.addSubview(titleView)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        view.addSubview(tableView)

        newBillButton.addTarget(self, action: #selector(newSplitButtonTapped), for: .touchUpInside)
        view.addSubview(newBillButton)
    }

    private func buildLayout() {
        headerView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(170)
        }

        titleView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom)
            make.left.right.equalToSuperview()
        }

        newBillButton.snp.makeConstraints { make in
            make.top.equalTo(tableView.snp.bottom)
            make.left.bottom.right.equalToSuperview()
            make.height.equalTo(60)
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

        return cell
    }

    // MARK: UITableViewDelegate methods

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let viewController = SplitViewController(split: splits[indexPath.row])
        navigationController!.pushViewController(viewController, animated: true)

        tableView.deselectRow(at: indexPath, animated: true)
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
