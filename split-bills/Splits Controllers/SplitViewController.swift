//
//  SplitViewController.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 7/8/18.
//  Copyright © 2018 Carlos Miguel de Elias. All rights reserved.
//

import UIKit
import Eureka

final class SplitViewController: FormViewController, NewExpenseViewControllerDelegate {

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

        buildView()
        buildForm()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController!.isNavigationBarHidden = false
    }

    private func buildView() {
        view.backgroundColor = .white

        let button = UIBarButtonItem(title: "New expense", style: .plain, target: self, action: #selector(newExpenseButtonTapped))
        navigationItem.rightBarButtonItem = button
    }

    private func buildForm() {
        let headerSection = Section() {
            var header = HeaderFooterView<SplitHeaderView>(.class)
            header.onSetupView = { view, section in
                let size = view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
                section.header?.height = { size.height }
            }
            $0.header = header
        }

        let settleSection = Section("Settle")

        let payments = split.settle(expenses: expenses)
        payments.forEach { payment in
            settleSection <<< PaymentRow() {
                $0.value = payment
            }
        }

        let overviewSection = Section("Overview")

        expenses.forEach { expense in
            overviewSection <<< ExpenseRow() {
                $0.value = expense
            }
        }

        form += [headerSection, settleSection, overviewSection]
    }

    private func reloadExpenses() {
        expenses = ExpenseController.shared.getAll(for: split)

        form.removeAll(keepingCapacity: true)
        buildForm()
    }

    @objc private func newExpenseButtonTapped() {
        pushNewExpenseViewController()
    }

    private func pushNewExpenseViewController() {
        let viewController = NewExpenseViewController(split: split)
        viewController.delegate = self

        var navigationViewControllers = navigationController!.viewControllers.filter { !($0 is NewExpenseViewController) }
        navigationViewControllers.append(viewController)
        navigationController!.setViewControllers(navigationViewControllers, animated: true)
    }

    private func saveAndReload(expense: Expense) {
        ExpenseController.shared.add(expense: expense, in: split)
        reloadExpenses()
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

final class SplitHeaderView: UIView {

    private let imageView = UIImageView(image: UIImage(named: "Money-Icon")!)

    override init(frame: CGRect) {
        super.init(frame: .zero)

        imageView.contentMode = .scaleAspectFit

        addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
            make.height.equalTo(104)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class ExpenseRow: Row<ExpenseCell>, RowType {

    required public init(tag: String?) {
        super.init(tag: tag)
    }
}

class ExpenseCell: Cell<Expense>, CellType {

    private let descriptionLabel = UILabel()
    private let amountLabel = UILabel()

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
    private let amountLabel = UILabel()

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
                NSAttributedString.Key.foregroundColor: Color.dark.value,
                NSAttributedString.Key.font: Text.body(.darkBold).font
            ] as [NSAttributedString.Key : Any]

            let regularAttributes = [
                NSAttributedString.Key.foregroundColor: Color.dark.value,
                NSAttributedString.Key.font: Text.body(.dark).font
            ] as [NSAttributedString.Key : Any]

            attributedString.append(NSAttributedString(string: payer.name, attributes: boldAttributes))
            attributedString.append(NSAttributedString(string: " pays to ", attributes: regularAttributes))
            attributedString.append(NSAttributedString(string: receiver.name, attributes: boldAttributes))

            descriptionLabel.attributedText = attributedString
            amountLabel.text = String(format: "%.2f", amount)
        }
    }
}
