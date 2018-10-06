//
//  ViewController.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 6/8/18.
//  Copyright © 2018 Carlos Miguel de Elias. All rights reserved.
//

import UIKit
import SnapKit

final class RootViewController: UIViewController,
    NewSplitViewControllerDelegate,
    UITableViewDataSource,
    UITableViewDelegate,
    SplitViewControllerDelegate
{

    fileprivate final class EmptyStateView: UIView {
        let label = UILabel()
        let arrowImage = UIImageView(image: UIImage(named: "down_arrow")!)

        private var arrowImageRightConstraint: Constraint?
    }

    private let tableView = UITableView()
    private let newBillButton = UIButton.plusIcon()

    private let emptyStateView = EmptyStateView()

    private var splits = SplitController.shared.getAll() ?? []

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController!.apply(style: .default)

        buildView()
        buildLayout()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        emptyStateView.update(rightConstraint: newBillButton.snp.left)
        view.bringSubviewToFront(newBillButton)
    }

    private func buildView() {
        title = "Split Bills"
        view.backgroundColor = Color.light.value

        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        tableView.register(SplitTableViewCell.self, forCellReuseIdentifier: SplitTableViewCell.reuseIdentifier)
        tableView.allowsMultipleSelection = false
        tableView.backgroundColor = Color.light.value
        view.addSubview(tableView)

        newBillButton.addTarget(self, action: #selector(newSplitButtonTapped), for: .touchUpInside)
        view.addSubview(newBillButton)

        emptyStateView.isHidden = !splits.isEmpty
        view.addSubview(emptyStateView)
    }

    private func buildLayout() {
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        newBillButton.snp.makeConstraints { make in
            make.bottom.right.equalToSuperview().inset(24)
            make.size.equalTo(55)
        }

        emptyStateView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(newBillButton.snp.centerY).offset(8)
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
        cell.update(title: split.eventName)

        return cell
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }

        let split = splits.remove(at: indexPath.row)
        SplitController.shared.remove(split: split)

        reloadData()
    }

    // MARK: UITableViewDelegate methods

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let viewController = SplitViewController(split: splits[indexPath.row])
        viewController.delegate = self
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

        reloadData()

        let viewController = SplitViewController(split: split)
        viewController.delegate = self
        navigationController?.setViewControllers([self, viewController], animated: true)
    }

    // MARK: SplitViewControllerDelegate methods

    func didRequestDeleting(split: Split, from viewController: UIViewController) {
        guard let index = splits.index(of: split) else { return }

        splits.remove(at: index)
        SplitController.shared.remove(split: split)

        reloadData()

        viewController.navigationController!.popViewController(animated: true)
    }

    // MARK: Reload

    private func reloadData() {
        emptyStateView.isHidden = !splits.isEmpty
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

private extension RootViewController.EmptyStateView {

    convenience init() {
        self.init(frame: .zero)

        let attributedString = NSMutableAttributedString()

        let boldHeadingAttributes = [
            NSAttributedString.Key.foregroundColor: Color.dark.value,
            NSAttributedString.Key.font: Text.heading2DarkBold.font
            ] as [NSAttributedString.Key : Any]

        let boldAttributes = [
            NSAttributedString.Key.foregroundColor: Color.dark.value,
            NSAttributedString.Key.font: Text.bodyLarge(.darkBold).font
            ] as [NSAttributedString.Key : Any]

        let regularAttributes = [
            NSAttributedString.Key.foregroundColor: Color.dark.value,
            NSAttributedString.Key.font: Text.bodyLarge(.dark).font
            ] as [NSAttributedString.Key : Any]

        attributedString.append(NSAttributedString(
            string: "You have not added any split bills.\n\nTap the ", attributes: regularAttributes))
        attributedString.append(NSAttributedString(
            string: "+", attributes: boldHeadingAttributes))
        attributedString.append(NSAttributedString(
            string: " button to create a", attributes: regularAttributes))
        attributedString.append(NSAttributedString(
            string: " new bill", attributes: boldAttributes))
        attributedString.append(NSAttributedString(
            string: ".", attributes: regularAttributes))

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
            arrowImageRightConstraint = make.right.equalToSuperview().constraint
            make.bottom.equalToSuperview()
        }
    }

    func update(rightConstraint: ConstraintRelatableTarget) {
        arrowImageRightConstraint?.deactivate()

        arrowImage.snp.makeConstraints { make in
            make.right.equalTo(rightConstraint).offset(-12)
        }
    }
}

final class SplitTableViewCell: UITableViewCell {

    static let reuseIdentifier = "SplitCell"

    private let splitNameLabel = UILabel(style: .bodyLarge(.dark))

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        accessoryType = .disclosureIndicator

        addSubview(splitNameLabel)

        splitNameLabel.snp.makeConstraints { make in
            let insets = UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 0)
            make.edges.equalToSuperview().inset(insets)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(title: String) {
        splitNameLabel.text = title
    }
}
