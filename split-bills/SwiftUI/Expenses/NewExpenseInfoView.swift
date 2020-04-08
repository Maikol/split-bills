//
//  NewExpenseInfoView.swift
//  split-bills
//
//  Created by Carlos DeElias on 8/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import SwiftUI

struct NewExpenseInfoView: View {

    var participants: [Participant]

    @Binding var description: String
    @Binding var payerIndex: Int
    @Binding var amount: String

    var body: some View {
        Section(header: FormSectionHeader(key: "expenses.new.info-header")) {
            TextField("expenses.new.info-placeholder", text: $description)

            Picker(selection: $payerIndex, label: Text("expenses.new.payer-header").apply(style: .body(.darkBold))) {
                ForEach(0 ..< participants.count, id: \.self) {
                    Text(self.participants[$0].name)
                }
            }

            HStack {
                Text("expenses.new.amount-header")
                Spacer()
                TextField("0", text: $amount)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.decimalPad)
                    .frame(width: 150)
            }
        }
    }
}

struct ExpenseInfoView_Previews: PreviewProvider {
    static var previews: some View {
        NewExpenseInfoView(
            participants: ExpenseViewModel.example.participants,
            description: .constant("Test"),
            payerIndex: .constant(0),
            amount: .constant("50"))
    }
}
