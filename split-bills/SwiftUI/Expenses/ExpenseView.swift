//
//  ExpenseView.swift
//  split-bills
//
//  Created by Carlos DeElias on 9/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import SwiftUI

struct ExpenseView: View {

    @EnvironmentObject var controller: ApplicationController

    @Binding var isPresented: Bool

    var split: Split
    @ObservedObject var viewModel: ExpenseViewModel

    @State private var showingDeleteAlert = false

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
                        Button(action: saveExpense) {
                            Text("new-split-controller.save")
                                .font(.headline)
                                .alignment(.center)
                        }.foregroundColor(.link)
                        Button(action: {
                            self.showingDeleteAlert.toggle()
                        }) {
                            Text("expenses.new.delete")
                                .font(.headline)
                                .alignment(.center)
                        }.foregroundColor(.error)
                    }.disabled(!viewModel.isValid)
                }
            }
            .alert(isPresented: $showingDeleteAlert) {
                Alert(
                    title: Text("expenses.new.delete-confirmation"),
                    primaryButton: .cancel(),
                    secondaryButton: .destructive(Text("expenses.new.delete"), action: {
                        self.deleteExpense()
                    })
                )
            }
            .background(Color.background)
            .edgesIgnoringSafeArea(.bottom)
            .navigationBarTitle(Text(viewModel.description), displayMode: .inline)
            .navigationBarItems(trailing:
                Button(action: {
                    self.isPresented.toggle()
                }) {
                    Text("split-controller.cancel")
                        .apply(font: .body, color: .white)
                }
            )
        }
    }

    func saveExpense() {
        let expense = viewModel.expense(with: split)
        controller.update(expense: expense, on: split)
        self.isPresented.toggle()
    }

    func deleteExpense() {
        let expense = viewModel.expense(with: split)
        controller.remove(expense: expense, on: split)
        self.isPresented.toggle()
    }
}

struct ExpenseView_Previews: PreviewProvider {
    static var previews: some View {
        ExpenseView(isPresented: .constant(true), split: .example, viewModel: .example)
    }
}
