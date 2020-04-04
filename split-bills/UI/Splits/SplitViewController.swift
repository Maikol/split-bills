//
//  SplitViewController.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 7/8/18.
//  Copyright © 2018 Carlos Miguel de Elias. All rights reserved.
//

import UIKit
import Eureka
import SnapKit

final class SplitViewController: FormViewController {

    private let viewModel: SplitViewModel

    fileprivate final class EmptyStateView: UIView {
        private let label = UILabel()
        private let imageView = UIImageView(image: UIImage(named: "down_arrow")!)

        private var arrowImageRightConstraint: Constraint?
    }

    private let newSplitButton = UIButton.plusIcon()
    private let emptyStateView = EmptyStateView()

    init(viewModel: SplitViewModel) {
        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.largeTitleDisplayMode = .never

        buildView()
        buildLayout()
        buildForm()
    }

    // TODO: viewWillAppear reload expense
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewModel.reloadExpenses()
        reload()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        emptyStateView.update(rightConstraint: newSplitButton.snp.left)
        view.bringSubviewToFront(newSplitButton)
    }

    private func buildView() {
        title = viewModel.split.eventName

        tableView.backgroundColor = Color.light.value

        newSplitButton.addTarget(self, action: #selector(newExpenseButtonTapped), for: .touchUpInside)
        view.addSubview(newSplitButton)

        emptyStateView.isHidden = !viewModel.expenses.isEmpty
        view.addSubview(emptyStateView)

        let button = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editButtonTapped))
        navigationItem.rightBarButtonItem = button
    }

    private func buildLayout() {
        newSplitButton.snp.makeConstraints { make in
            make.bottom.right.equalToSuperview().inset(24)
            make.size.equalTo(55)
        }

        emptyStateView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(newSplitButton.snp.centerY).offset(8)
        }
    }

    private func buildForm() {
        let settleSection = Section("Settle") {
            $0.tag = "settle"
            var header = HeaderLabel.defaultHeader
            header.onSetupView = { view, _ in
                view.update(title: "Settle")
            }
            $0.header = header
            $0.hidden = Condition.function([]) { [weak self] _ in
                return self?.viewModel.expenses.isEmpty == true
            }
        }

        let payments = viewModel.split.settle(expenses: viewModel.expenses)
        payments.forEach { payment in
            settleSection <<< PaymentRow() {
                $0.value = payment
            }
        }

        let overviewSection = Section("Overview") {
            $0.tag = "overview"
            var header = HeaderLabel.defaultHeader
            header.onSetupView = { view, _ in
                view.update(title: "Overview")
            }
            $0.header = header
            $0.hidden = Condition.function([]) { [weak self] _ in
                return self?.viewModel.expenses.isEmpty == true
            }
        }

        viewModel.expenses.forEach { expense in
            overviewSection <<< ExpenseRow() {
                $0.value = expense
                let deleteAction = SwipeAction(style: .destructive, title: "Delete")
                { [weak self] _, _, completionHandler in
                    guard let sSelf = self else { return }

                    completionHandler?(sSelf.deleteAndReload(expense: expense))
                }

                $0.trailingSwipe.actions = [deleteAction]
            }.onCellSelection { [weak self] _, row in
                guard let self = self, let expense = row.value else { return }

                self.viewModel.open(expense: expense)
            }
        }

        form += [settleSection, overviewSection]
    }

    private func reload() {
        form.removeAll(keepingCapacity: true)
        buildForm()
    }

    // MARK: Actions

    @objc private func newExpenseButtonTapped() {
        viewModel.newExpense()
    }

    @objc private func editButtonTapped() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        alertController.addAction(UIAlertAction(
            title: NSLocalizedString("split-controller.edit", comment: ""),
            style: .default) { [viewModel] _ in
                viewModel.editSplit()
        })

        alertController.addAction(UIAlertAction(
            title: NSLocalizedString("split-controller.delete", comment: ""),
            style: .destructive) { [weak self] _ in
                guard let self = self else { return }

                self.viewModel.deleteSplit()
        })

        alertController.addAction(UIAlertAction(
            title: NSLocalizedString("split-controller.cancel", comment: ""),
            style: .cancel,
            handler: nil))

        present(alertController, animated: true, completion: nil)
    }

    private func deleteAndReload(expense: Expense) -> Bool {
        guard viewModel.delete(expense: expense) else {
            return false
        }

        rebuildPayments()
        return true
    }

    private func rebuildPayments() {
        guard let section = form.sectionBy(tag: "settle") else { return }

        section.removeAll()

        viewModel.payments.forEach { payment in
            section <<< PaymentRow() {
                $0.value = payment
            }
        }

        section.evaluateHidden()
        form.sectionBy(tag: "empty-state")?.evaluateHidden()
        form.sectionBy(tag: "overview")?.evaluateHidden()
    }
}

final class ExpenseRow: Row<ExpenseCell>, RowType {

    required public init(tag: String?) {
        super.init(tag: tag)
    }
}

class ExpenseCell: Cell<Expense>, CellType {

    private let descriptionLabel = UILabel(style: .bodyLarge(.dark))
    private let amountLabel = UILabel(style: .body(.darkBold))

    required init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        buildView()
        buildLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func buildView() {
        accessoryType = .disclosureIndicator

        contentView.addSubview(descriptionLabel)

        amountLabel.textAlignment = .right
        contentView.addSubview(amountLabel)
    }

    private func buildLayout() {
        descriptionLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(12)
        }

        amountLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.right.equalToSuperview().offset(-12)
            make.left.equalTo(descriptionLabel.snp.right).offset(12)
            make.width.lessThanOrEqualTo(72)
        }
    }

    open override func setup() {
        super.setup()

        selectionStyle = .none
    }
    
    open override func update() {
        super.update()

        height = { 60 }
        row.title = nil

        detailTextLabel?.text = nil

        descriptionLabel.text = row.value?.description
        amountLabel.text = row.value.flatMap { String($0.amount) }
    }
}

final class PaymentRow: Row<PaymentCell>, RowType {

    required public init(tag: String?) {
        super.init(tag: tag)
    }
}

class PaymentCell: Cell<Payment>, CellType {

    private let descriptionLabel = UILabel()
    private let amountLabel = UILabel(style: .body(.darkBold))

    required init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        buildView()
        buildLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func buildView() {
        descriptionLabel.minimumScaleFactor = 0.6
        descriptionLabel.adjustsFontSizeToFitWidth = true
        contentView.addSubview(descriptionLabel)

        amountLabel.textAlignment = .right
        contentView.addSubview(amountLabel)
    }

    private func buildLayout() {
        descriptionLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(12)
        }

        amountLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.right.equalToSuperview().offset(-12)
            make.left.equalTo(descriptionLabel.snp.right).offset(12)
            make.width.lessThanOrEqualTo(84)
        }
    }

    open override func setup() {
        super.setup()

        selectionStyle = .none
    }

    open override func update() {
        super.update()

        height = { 60 }
        row.title = nil

        detailTextLabel?.text = nil

        if let payer = row.value?.payer, let receiver = row.value?.receiver, let amount = row.value?.amount {
            let attributedString = NSMutableAttributedString()

            let boldAttributes = [
                .foregroundColor: Color.dark.value,
                .font: Style.body(.darkBold).font
            ] as [NSAttributedString.Key : Any]

            let regularAttributes = [
                .foregroundColor: Color.dark.value,
                .font: Style.body(.dark).font
            ] as [NSAttributedString.Key : Any]

            attributedString.append(NSAttributedString(string: payer.name, attributes: boldAttributes))
            attributedString.append(NSAttributedString(string: " pays to ", attributes: regularAttributes))
            attributedString.append(NSAttributedString(string: receiver.name, attributes: boldAttributes))

            descriptionLabel.attributedText = attributedString
            amountLabel.text = String(format: "%.2f", amount)
        }
    }
}

extension SplitViewController.EmptyStateView {

    convenience init() {
        self.init(frame: .zero)

        let attributedString = NSMutableAttributedString()

        let boldAttributes = [
            .foregroundColor: Color.dark.value,
            .font: Style.bodyLarge(.darkBold).font
            ] as [NSAttributedString.Key : Any]

        let regularAttributes = [
            .foregroundColor: Color.dark.value,
            .font: Style.bodyLarge(.dark).font
            ] as [NSAttributedString.Key : Any]

        attributedString.append(NSAttributedString(
            string: NSLocalizedString("split-controller.empty-view.text-1", comment: ""),
            attributes: regularAttributes))
        attributedString.append(NSAttributedString(
            string: NSLocalizedString("split-controller.empty-view.text-2", comment: ""),
            attributes: boldAttributes))
        attributedString.append(NSAttributedString(
            string: NSLocalizedString("split-controller.empty-view.text-3", comment: ""),
            attributes: regularAttributes))
        label.attributedText = attributedString
        label.numberOfLines = 0
        label.textAlignment = .center
        addSubview(label)

        imageView.contentMode = .scaleAspectFit
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        addSubview(imageView)

        label.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
        }

        imageView.snp.makeConstraints { make in
            make.top.equalTo(label.snp.bottom).offset(24)
            arrowImageRightConstraint = make.right.equalToSuperview().constraint
            make.bottom.equalToSuperview()
        }
    }

    func update(rightConstraint: ConstraintRelatableTarget) {
        arrowImageRightConstraint?.deactivate()

        imageView.snp.makeConstraints { make in
            make.right.equalTo(rightConstraint).offset(-12)
        }
    }
}
