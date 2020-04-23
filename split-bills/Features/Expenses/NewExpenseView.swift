//
//  NewExpenseView.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 6/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import SwiftUI

struct NewExpenseView: View {

    @Environment(\.presentationMode) var presentationMode

    @ObservedObject var viewModel: NewExpenseViewModel

    var body: some View {
        NavigationView {
            ZStack {
                Color.background
                    .edgesIgnoringSafeArea(.bottom)
                contentView
                    .keyboardAdaptive()
            }
            .navigationBarTitle(Text("expenses.new.title"), displayMode: .inline)
            .navigationBarItems(trailing:
                Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    Text("split-controller.cancel")
                        .apply(font: .body, color: .white)
                }
            )
        }.onAppear { self.viewModel.send(event: .onAppear) }
    }

    private var contentView: some View {
        switch viewModel.state {
        case .idle:
            return Color.background.eraseToAnyView()
        case .loading:
            return Color.background.eraseToAnyView()
        case let .loaded(_, expense):
            return form(for: expense).eraseToAnyView()
        case .saving:
            return Color.background.eraseToAnyView()
        }
    }

    private func form(for expense: ExpenseEditModel) -> some View {
        Form {
            expenseInfoView(with: expense)
            participantsContentView(with: expense)

            Section {
                Button(action: createExpense) {
                    Text("new-split-controller.save")
                        .apply(font: .body, color: .link)
                        .alignment(.center)
                }
            }.disabled(!expense.isValid)
        }
    }

    private func expenseInfoView(with expense: ExpenseEditModel) -> some View {
        Section(header: FormSectionHeader(key: "expenses.new.info-header")) {
            TextField(
                "expenses.new.info-placeholder",
                text: viewModel.binding(for: \.name) { string in NewExpenseViewModel.Event.onNameChange(string) }
            )

            Picker(
                selection: viewModel.binding(for: \.payerIndex) { index in NewExpenseViewModel.Event.onPayerChange(index) },
                label: Text("expenses.new.payer-header").apply(font: .body, color: .dark, weight: .bold))
            {
                ForEach(0 ..< expense.participants.count, id: \.self) {
                    Text(expense.participants[$0].name)
                }
            }

            HStack {
                Text("expenses.new.amount-header")
                TextField("0", text: viewModel.binding(for: \.amount) { string in NewExpenseViewModel.Event.onAmountChange(string) })
                    .accessibility(label: Text("amountTextField"))
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.decimalPad)
            }
        }
    }

    private func participantsContentView(with expense: ExpenseEditModel) -> some View {
        Group {
            Section(header: FormSectionHeader(key: "expenses.new.split-header")) {
                Toggle(isOn: viewModel.binding(for: \.splitEqually) { boolValue in NewExpenseViewModel.Event.onSplitEquallyChange(boolValue) }) {
                    Text("expenses.new.split-equally-header")
                }
            }

            if !expense.splitEqually {
                Section(header: FormSectionHeader(key: "expenses.new.split-differently")) {
                    Picker(selection: viewModel.binding(for: \.expenseTypeIndex) { index in NewExpenseViewModel.Event.onExpenseTypeChange(index) }, label: Text("")) {
                        ForEach(0 ..< ExpenseTypeEditModel.allCases.count) {
                            Text(ExpenseTypeEditModel.allCases[$0].localized).tag($0)
                        }
                    }.pickerStyle(SegmentedPickerStyle())
                }

                splitTypeView(for: expense)
            }
        }
    }

    private func splitTypeView(for expense: ExpenseEditModel) -> some View {
        guard let splitType = ExpenseTypeEditModel(rawValue: expense.expenseTypeIndex) else {
            fatalError("This shouldn't happen")
        }

        switch splitType {
        case .equally:
            return Section {
                participantSelectionView(with: expense.expenseTypeSelections)
            }.eraseToAnyView()
        case .amount:
            return Section {
                participantsAmountsView(with: expense.expenseTypeAmounts)
            }.eraseToAnyView()
        }
    }

    private func participantSelectionView(
        with expenseTypeSelections: [ExpenseTypeEditModel.Selection]
    ) -> some View {
        List {
            ForEach(0 ..< expenseTypeSelections.count, id: \.self) { index in
                ParticipantSelectRow(
                    name: expenseTypeSelections[index].participant.name,
                    isSelected: self.viewModel.binding(for: \.expenseTypeSelections[index].isSelected) { boolValue in
                        NewExpenseViewModel.Event.onExpenseTypeSelectionChange(index, isSelected: boolValue)
                    }
                )
            }
        }
    }

    private func participantsAmountsView(
        with expenseTypeAmounts: [ExpenseTypeEditModel.Amount]
    ) -> some View {
        List {
            ForEach(0 ..< expenseTypeAmounts.count, id: \.self) { index in
                ParticipantTextEntryRow(
                    name: expenseTypeAmounts[index].participant.name,
                    amount: self.viewModel.binding(for: \.expenseTypeAmounts[index].amount) { string in
                        NewExpenseViewModel.Event.onExpenseTypeAmountChange(index, amount: string)
                    }
                )
            }
        }
    }

    func createExpense() {
        viewModel.send(event: .onSaveExpense)
        presentationMode.wrappedValue.dismiss()
    }
}

struct NewExpenseView_Previews: PreviewProvider {
    static var previews: some View {
        NewExpenseView(viewModel: NewExpenseViewModel(splitId: 0))
    }
}
