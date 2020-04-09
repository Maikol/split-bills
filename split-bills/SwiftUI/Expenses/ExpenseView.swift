//
//  ExpenseView.swift
//  split-bills
//
//  Created by Carlos DeElias on 9/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import SwiftUI

struct ExpenseView: View {

    @Binding var isPresented: Bool

    @ObservedObject var viewModel: ExpenseViewModel

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
                                .apply(style: .body(.link))
                                .alignment(.center)
                        }
                    }.disabled(!viewModel.isValid)
                }
            }
            .background(Color.light)
            .edgesIgnoringSafeArea(.bottom)
            .navigationBarTitle(Text(viewModel.description), displayMode: .inline)
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

    func saveExpense() {

    }
}

struct ExpenseView_Previews: PreviewProvider {
    static var previews: some View {
        ExpenseView(isPresented: .constant(true), viewModel: .example)
    }
}
