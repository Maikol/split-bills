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

        let payments = split.settle(expenses: expenses).map { $0.description }
        print(payments.joined(separator: "\n"))
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

        let overviewSection = Section("Overview")

        expenses.forEach { expense in
            overviewSection <<< ExpenseRow() {
                $0.value = expense
            }
        }

        form += [headerSection, overviewSection]
    }

    private func reloadExpenses() {
        expenses = ExpenseController.shared.getAll(for: split)

        form.removeAll(keepingCapacity: true)
        buildForm()
    }

    @objc private func newExpenseButtonTapped() {
        let viewController = NewExpenseViewController(split: split)
        viewController.delegate = self
        present(UINavigationController(rootViewController: viewController), animated: true, completion: nil)
    }

    // MARK: NewExpenseViewControllerDelegate methods

    func didCreateNewExpense(_ expense: Expense, viewController: UIViewController) {
        ExpenseController.shared.add(expense: expense, in: split)

        reloadExpenses()

        viewController.dismiss(animated: true, completion: nil)
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
