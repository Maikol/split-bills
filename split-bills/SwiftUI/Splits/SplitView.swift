//
//  SplitView.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 4/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import SwiftUI

struct SplitView: View {

    @EnvironmentObject var controller: ApplicationController

    @ObservedObject var split: Split

    @State private var showingNewExpense = false

    var body: some View {
        Group {
            if split.expenses.isEmpty {
                SplitEmptyView() { self.showingNewExpense.toggle() }
                    .sheet(isPresented: $showingNewExpense) {
                        NewExpenseView(split: self.split, isPresented: self.$showingNewExpense).environmentObject(self.controller)
                }
            } else {
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
                            HStack {
                                Text(expense.description)
                                    .apply(style: .body(.dark))
                                Spacer()
                                Text(String(expense.amount))
                                    .apply(style: .body(.darkBold))
                            }
                        }
                    }
                }
            }
        }
        .background(Color.light)
        .edgesIgnoringSafeArea(.bottom)
        .navigationBarTitle(Text(split.eventName), displayMode: .inline)
        .listStyle(GroupedListStyle())
    }
}

private extension Split {

    var payments: [Payment] {
        settle(expenses: expenses)
    }
}

struct SplitView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SplitView(split: .init(id: 0, eventName: "Asado", participants: []))
        }
    }
}
