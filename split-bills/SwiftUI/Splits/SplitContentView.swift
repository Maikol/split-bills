//
//  SplitContentView.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 8/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import SwiftUI

struct SplitContentView: View {

    @EnvironmentObject var controller: ApplicationController

    @ObservedObject var split: Split

    var expenseTappedAction: (Expense) -> Void

    var body: some View {
        List {
            Section(header: FormSectionHeader(key: "split.view.settle-header")) {
                ForEach(split.payments) { payment in
                    HStack {
                        Text(payment.payer.name)
                            .apply(style: .body(.darkBold))
                        Text("split.view.sttle.pays-to")
                            .apply(style: .body(.dark))
                        Text(payment.receiver.name)
                            .apply(style: .body(.darkBold))
                        Spacer()
                        Text(String(format: "%.2f", payment.amount))
                            .apply(style: .body(.darkBold))
                    }
                }
            }

            Section(header: FormSectionHeader(key: "split.view.overview-header")) {
                ForEach(split.expenses) { expense in
                    Button(action: {
                        self.expenseTappedAction(expense)
                    }) {
                        HStack {
                            Text(expense.description)
                                .apply(style: .body(.dark))
                            Spacer()
                            Text(String(expense.amount))
                                .apply(style: .body(.darkBold))
                        }
                    }.foregroundColor(.primary)
                }.onDelete(perform: removeExpense)
            }
        }
    }

    private func removeExpense(at offsets: IndexSet) {
        for index in offsets {
            let expense = split.expenses[index]
            controller.remove(expense: expense, on: split)
        }
    }
}

private extension Split {

    var payments: [Payment] {
        settle(expenses: expenses).sorted { $0.payer.name < $1.payer.name }
    }
}

struct SplitContentView_Previews: PreviewProvider {
    static var previews: some View {
        SplitContentView(split: .example, expenseTappedAction: { _ in })
    }
}
