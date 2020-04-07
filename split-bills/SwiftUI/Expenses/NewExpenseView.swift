//
//  NewExpenseView.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 6/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import SwiftUI

struct NewExpenseView: View {

    static private let splitTypes = ["Equally", "Amount"]

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
                Section(header: FormSectionHeader(key: "expenses.new.info-header")) {
                    TextField("expenses.new.info-placeholder", text: $viewModel.description)

                    Picker(selection: $viewModel.payerIndex, label: Text("expenses.new.payer-header").apply(style: .body(.darkBold))) {
                        ForEach(0 ..< split.participants.count, id: \.self) {
                            Text(self.split.participants[$0].name)
                        }
                    }

                    HStack {
                        Text("expenses.new.amount-header")
                        Spacer()
                        TextField("0", text: $viewModel.amount)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                            .frame(width: 150)
                    }
                }

                Section(header: FormSectionHeader(key: "expenses.new.split-header")) {
                    Toggle(isOn: $viewModel.splitEqually) {
                        Text("expenses.new.split-equally-header")
                    }
                }

                if !viewModel.splitEqually {
                    Section(header: FormSectionHeader(key: "expenses.new.split-differently")) {
                        Picker(selection: $viewModel.splitTypeIndex, label: Text("")) {
                            ForEach(0 ..< NewExpenseView.splitTypes.count) {
                                Text(NewExpenseView.splitTypes[$0]).tag($0)
                            }
                        }.pickerStyle(SegmentedPickerStyle())
                    }

                    ParticipantsSectionView(viewModel: viewModel)
                }

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

    }
}

struct NewExpenseView_Previews: PreviewProvider {
    static var previews: some View {
        NewExpenseView(split: .example, isPresented: .constant(true))
    }
}
