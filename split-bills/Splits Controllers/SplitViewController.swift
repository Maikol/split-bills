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

        let payments = self.payments.map { $0.description }
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

private extension SplitViewController {

    var payments: [Payment] {
        let paymentsValues = Dictionary(grouping: expenses) { expense in
            return expense.payer
        }.mapValues { $0.reduce(0) { return $0 + $1.amount } }

        var owingValues = [Participant: Double]()
        split.participants.forEach { participant in
            let totalOwing = expenses.reduce(0.0) { result, expense in
                guard let weight = expense.participantsWeight.first(where: { $0.participant == participant }) else {
                    return result
                }

                return result + weight.weight * expense.amount
            }

            owingValues[participant] = totalOwing * (-1)
        }

        let mergedValues = paymentsValues.merging(owingValues) { $0 + $1 }.sorted { $0.value > $1.value }
        return settle(mergedValues)
    }

    private func settle(_ values: [(key: Participant, value: Double)]) -> [Payment] {
        guard values.count > 1 else {
            print("Probably something wen't wrong")
            return []
        }

        guard let first = values.first, let last = values.last else {
            fatalError("something went wrong")
        }

        let sum = first.value + last.value

        if sum < 0 {
            let paymen = Payment(payer: last.key, receiver: first.key, amount: abs(first.value))
            var newValues = values.filter { $0.key != first.key && $0.key != last.key  }
            newValues.append((last.key, last.value + first.value))
            return [paymen] + settle(newValues)
        } else {
            let paymen = Payment(payer: last.key, receiver: first.key, amount: abs(last.value))
            var newValues = values.filter { $0.key != first.key && $0.key != last.key  }
            newValues.insert((first.key, first.value + last.value), at: 0)
            return [paymen] + settle(newValues)
        }
    }
}
