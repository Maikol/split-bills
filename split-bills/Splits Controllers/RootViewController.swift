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

    fileprivate final class EmptyStateView: UIView {
        let label = UILabel()
        let arrowImage = UIImageView(image: UIImage(named: "down_arrow")!)
    }

    private let headerView = UIView()
    private let titleView = UILabel(style: .headingWhite)
    private let tableView = UITableView()
    private let newBillButton = UIButton(title: "New Bill", style: .headingBrand)

    private let emptyStateView = EmptyStateView()

    private var splits = SplitController.shared.getAll() ?? []

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController!.apply(style: .default)

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
        tableView.register(SplitTableViewCell.self, forCellReuseIdentifier: SplitTableViewCell.reuseIdentifier)
        tableView.allowsMultipleSelection = false
        view.addSubview(tableView)

        newBillButton.addTarget(self, action: #selector(newSplitButtonTapped), for: .touchUpInside)
        view.addSubview(newBillButton)

        emptyStateView.isHidden = !splits.isEmpty
        view.addSubview(emptyStateView)
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

        emptyStateView.snp.makeConstraints { make in
            make.top.equalTo(view.snp.centerY).priority(500)
            make.bottom.lessThanOrEqualTo(newBillButton.snp.top).offset(-30)
            make.left.right.equalToSuperview()
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
        let cell = tableView.dequeueReusableCell(withIdentifier: SplitTableViewCell.reuseIdentifier) as! SplitTableViewCell

        let split = splits[indexPath.row]
        cell.textLabel?.text = split.eventName

        return cell
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }

        let split = splits.remove(at: indexPath.row)
        SplitController.shared.remove(split: split)
        emptyStateView.isHidden = !splits.isEmpty
        tableView.reloadData()
    }

    // MARK: UITableViewDelegate methods

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let viewController = SplitViewController(split: splits[indexPath.row])
        navigationController!.pushViewController(viewController, animated: true)

        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }

    // MARK: NewSplitViewControllerDelegate methods

    func didCreateNewSplit(_ split: Split) {
        SplitController.shared.add(split: split)
        splits.append(split)

        emptyStateView.isHidden = true
        tableView.reloadData()

        let viewController = SplitViewController(split: split)
        navigationController?.setViewControllers([self, viewController], animated: true)
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

private extension RootViewController.EmptyStateView {

    convenience init() {
        self.init(frame: .zero)

        let attributedString = NSMutableAttributedString()

        let boldAttributes = [
            NSAttributedString.Key.foregroundColor: Color.dark.value,
            NSAttributedString.Key.font: Text.body(.darkBold).font
            ] as [NSAttributedString.Key : Any]

        let regularAttributes = [
            NSAttributedString.Key.foregroundColor: Color.dark.value,
            NSAttributedString.Key.font: Text.body(.dark).font
            ] as [NSAttributedString.Key : Any]

        attributedString.append(NSAttributedString(
            string: "You have not added any split bills.\n\nTap the ", attributes: regularAttributes))
        attributedString.append(NSAttributedString(
            string: "New Bill", attributes: boldAttributes))
        attributedString.append(NSAttributedString(
            string: " button to create a new bill.", attributes: regularAttributes))

        label.numberOfLines = 0
        label.textAlignment = .center
        label.attributedText = attributedString
        addSubview(label)
        addSubview(arrowImage)

        label.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
        }

        arrowImage.snp.makeConstraints { make in
            make.top.equalTo(label.snp.bottom).offset(24)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
}

final class SplitTableViewCell: UITableViewCell {

    static let reuseIdentifier = "SplitCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        accessoryType = .disclosureIndicator
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
