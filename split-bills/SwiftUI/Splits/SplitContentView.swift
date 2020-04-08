//
//  SplitContentView.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 8/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import SwiftUI

struct SplitContentView: View {

    @ObservedObject var split: Split

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

private extension Split {

    var payments: [Payment] {
        settle(expenses: expenses)
    }
}

struct SplitContentView_Previews: PreviewProvider {
    static var previews: some View {
        SplitContentView(split: .example)
    }
}
