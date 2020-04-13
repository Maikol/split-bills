//
//  SplitContentView.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 8/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import SwiftUI

struct SplitContentView: View {

    @EnvironmentObject var controller: DatabaseController

    @ObservedObject var split: Split

    var expenseTappedAction: (Expense) -> Void

    var body: some View {
        List {
            Section(header: FormSectionHeader(key: "split.view.settle-header")) {
                ForEach(split.payments) { payment in
                    HStack {
                        Text(payment.payer.name)
                            .apply(font: .body, color: .dark, weight: .bold)
                        Text("split.view.sttle.pays-to")
                            .apply(font: .body, color: .dark)
                        Text(payment.receiver.name)
                            .apply(font: .body, color: .dark, weight: .bold)
                        Spacer()
                        Text(String(format: "%.2f", payment.amount))
                            .apply(font: .body, color: .dark, weight: .bold)
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
                                .apply(font: .body, color: .dark)
                            Spacer()
                            Text(String(expense.amount))
                                .apply(font: .body, color: .dark, weight: .bold)
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
