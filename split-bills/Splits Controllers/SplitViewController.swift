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

protocol SplitViewControllerDelegate: class {
    func didRequestDeleting(split: Split, from viewController: UIViewController)
}

final class SplitViewController: FormViewController, NewExpenseViewControllerDelegate {

    weak var delegate: SplitViewControllerDelegate?

    fileprivate final class EmptyStateView: UIView {
        private let label = UILabel()
        private let imageView = UIImageView(image: UIImage(named: "down_arrow")!)

        private var arrowImageRightConstraint: Constraint?
    }

    private let newSplitButton = UIButton.plusIcon()
    private let emptyStateView = EmptyStateView()

    private let split: Split
    private var expenses: [Expense]

    init(split: Split) {
        self.split = split
        expenses = ExpenseController.shared.getAll(for: split)

        super.init(nibName: nil, bundle: nil)
    }

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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        emptyStateView.update(rightConstraint: newSplitButton.snp.left)
        view.bringSubviewToFront(newSplitButton)
    }

    private func buildView() {
        title = split.eventName

        tableView.backgroundColor = Color.light.value

        newSplitButton.addTarget(self, action: #selector(newExpenseButtonTapped), for: .touchUpInside)
        view.addSubview(newSplitButton)

        emptyStateView.isHidden = !expenses.isEmpty
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
                return self?.expenses.isEmpty == true
            }
        }

        let payments = split.settle(expenses: expenses)
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
                return self?.expenses.isEmpty == true
            }
        }

        expenses.forEach { expense in
            overviewSection <<< ExpenseRow() {
                $0.value = expense
                let deleteAction = SwipeAction(style: .destructive, title: "Delete")
                { [weak self] _, _, completionHandler in
                    guard let sSelf = self else { return }

                    completionHandler?(sSelf.deleteAndReload(expense: expense))
                }

                $0.trailingSwipe.actions = [deleteAction]
            }.onCellSelection { [weak self] _, row in
                guard let expense = row.value else { return }

                self?.pushNewExpenseViewController(expense: expense)
            }
        }

        form += [settleSection, overviewSection]
    }

    private func reloadExpenses() {
        expenses = ExpenseController.shared.getAll(for: split)

        form.removeAll(keepingCapacity: true)
        buildForm()
    }

    // MARK: Actions

    @objc private func newExpenseButtonTapped() {
        pushNewExpenseViewController()
    }

    @objc private func editButtonTapped() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        alertController.addAction(UIAlertAction(title: "Edit", style: .default) { [weak self] _ in
            guard let self = self else { return }

            let viewController = NewSplitViewController(split: self.split)
            let navigationController = UINavigationController(rootViewController: viewController, style: .default)
            viewController.addDismissButton()
            self.present(navigationController, animated: true, completion: nil)
        })

        alertController.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self = self else { return }

            self.delegate?.didRequestDeleting(split: self.split, from: self)
        })

        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        present(alertController, animated: true, completion: nil)
    }

    private func pushNewExpenseViewController(expense: Expense? = nil) {
        let viewController = NewExpenseViewController(split: split, expense: expense)
        viewController.delegate = self

        var navigationViewControllers = navigationController!.viewControllers.filter { !($0 is NewExpenseViewController) }
        navigationViewControllers.append(viewController)
        navigationController!.setViewControllers(navigationViewControllers, animated: true)
    }

    private func saveAndReload(expense: Expense) {
        if expense.id != INTMAX_MAX {
            ExpenseController.shared.update(expense: expense)
        } else {
            ExpenseController.shared.add(expense: expense, in: split)
        }

        reloadExpenses()
    }

    private func deleteAndReload(expense: Expense) -> Bool {
        guard ExpenseController.shared.remove(expense: expense) else {
            return false
        }

        expenses.removeAll { $0 == expense }
        rebuildPayments()
        return true
    }

    private func rebuildPayments() {
        guard let section = form.sectionBy(tag: "settle") else { return }

        section.removeAll()

        let payments = split.settle(expenses: expenses)
        payments.forEach { payment in
            section <<< PaymentRow() {
                $0.value = payment
            }
        }

        section.evaluateHidden()
        form.sectionBy(tag: "empty-state")?.evaluateHidden()
        form.sectionBy(tag: "overview")?.evaluateHidden()
    }

    // MARK: NewExpenseViewControllerDelegate methods

    func didRequestSaveExpenseAndDismiss(_ expense: Expense, from viewController: UIViewController) {
        saveAndReload(expense: expense)

        navigationController!.popViewController(animated: true)
    }

    func didRequestSaveAndCreateNewExpense(_ expense: Expense, from viewController: UIViewController) {
        saveAndReload(expense: expense)

        pushNewExpenseViewController()
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
                .font: Text.body(.darkBold).font
            ] as [NSAttributedString.Key : Any]

            let regularAttributes = [
                .foregroundColor: Color.dark.value,
                .font: Text.body(.dark).font
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
            .font: Text.bodyLarge(.darkBold).font
            ] as [NSAttributedString.Key : Any]

        let regularAttributes = [
            .foregroundColor: Color.dark.value,
            .font: Text.bodyLarge(.dark).font
            ] as [NSAttributedString.Key : Any]

        attributedString.append(NSAttributedString(string: "Add ", attributes: regularAttributes))
        attributedString.append(NSAttributedString(string: "New Expenses", attributes: boldAttributes))
        attributedString.append(NSAttributedString(string: " to this bill", attributes: regularAttributes))
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
