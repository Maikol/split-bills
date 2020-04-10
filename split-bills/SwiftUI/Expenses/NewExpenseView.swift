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
            KeyboardHost {
                Form {
                    NewExpenseInfoView(
                        participants: viewModel.participants,
                        description: $viewModel.description,
                        payerIndex: $viewModel.payerIndex,
                        amount: $viewModel.amount)

                    NewExpenseParticipantsView(viewModel: viewModel)

                    Section {
                        Button(action: createExpense) {
                            Text("new-split-controller.save")
                                .apply(style: .body(.link))
                                .alignment(.center)
                        }
                    }.disabled(!viewModel.isValid)
                }
            }
            .background(Color.background)
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

struct NewExpenseView_Previews: PreviewProvider {
    static var previews: some View {
        NewExpenseView(split: .example, isPresented: .constant(true))
    }
}
