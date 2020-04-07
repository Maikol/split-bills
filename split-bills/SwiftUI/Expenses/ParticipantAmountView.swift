//
//  ParticipantAmountView.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 7/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import SwiftUI

struct ParticipantAmountView: View {

    @ObservedObject var viewModel: ExpenseViewModel

    var body: some View {
        List {
            ForEach(0 ..< viewModel.amounts.count, id: \.self) { index in
                ParticipantTextEntryRow(
                    name: self.viewModel.amounts[index].name,
                    amount: self.$viewModel.amounts[index].amount)
            }
        }
    }
}

struct ParticipantAmountView_Previews: PreviewProvider {
    static var previews: some View {
        ParticipantAmountView(viewModel: .example)
    }
}
