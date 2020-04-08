//
//  NewExpenseView.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 6/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import SwiftUI

struct NewExpenseView: View {

    @EnvironmentObject var controller: ApplicationController

    var split: Split

    @Binding var isPresented: Bool

    @ObservedObject var viewModel: ExpenseViewModel

    init(split: Split, isPresented: Binding<Bool>) {
        self.split = split
        self._isPresented = isPresented
        self.viewModel = ExpenseViewModel(participants: split.participants)
    }

    var body: some View {
        NavigationView {
            Form {
                NewExpenseInfoView(
                    participants: viewModel.participants,
                    description: $viewModel.description,
                    payerIndex: $viewModel.payerIndex,
                    amount: $viewModel.amount)

                NewExpenseParticipantsView(viewModel: viewModel)

                Section {
                    Button(action: createExpense) {
                        Text("expenses.new.add-new-expense")
                            .apply(style: .body(.link))
                            .alignment(.center)
                    }
                    Button(action: createExpense) {
                        Text("new-split-controller.save")
                            .apply(style: .body(.link))
                            .alignment(.center)
                    }
                }.disabled(!viewModel.isValid)
            }
            .background(Color.light)
            .edgesIgnoringSafeArea(.bottom)
            .navigationBarTitle(Text("expenses.new.title"), displayMode: .inline)
            .navigationBarItems(trailing:
                Button(action: {
                    self.isPresented.toggle()
                }) {
                    Text("split-controller.cancel")
                        .apply(style: .body(.white))
                }
            )
        }
    }

    func createExpense() {
        let expense = viewModel.expense(with: split)
        controller.saveExpense(split: split, expense: expense)
        self.isPresented.toggle()
    }
}

private extension ExpenseViewModel {

    func expense(with split: Split) -> Expense {
        guard let type = ExpenseViewModel.SplitTpe(rawValue: splitTypeIndex),
            let amount = Double(amount) else {
            fatalError("This shouldn't happen")
        }

        let payer = split.participants[payerIndex]

        if splitEqually {
            return .equallySplited(with: split, payer: payer, participants: participants, description: description, amount: amount)!
        }

        switch type {
        case .equally:
            let participating = selections.filter { !$0.isSelected }.map { $0.participant }
            return .equallySplited(with: split, payer: payer, participants: participating, description: description, amount: amount)!
        case .amount:
            let participantsAmounts = amounts.compactMap { ($0.participant, Double($0.amount) ?? 0.0) }
            return Expense.splitByAmount(with: split, payer: payer, amounts: participantsAmounts, description: description, amount: amount)!
        }
    }
}

struct NewExpenseView_Previews: PreviewProvider {
    static var previews: some View {
        NewExpenseView(split: .example, isPresented: .constant(true))
    }
}
