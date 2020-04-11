//
//  ParticipantAmountRow.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 7/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import SwiftUI

struct ParticipantTextEntryRow: View {

    var name: String
    @Binding var amount: String

    var body: some View {
        HStack {
            Text(name)
                .apply(style: .body(.darkBold))
            Spacer()
            TextField("0", text: $amount)
                .multilineTextAlignment(.trailing)
                .keyboardType(.decimalPad)
                .frame(width: 150)
        }
    }
}

struct ParticipantAmountRow_Previews: PreviewProvider {
    static var previews: some View {
        ParticipantTextEntryRow(name: "Caru", amount: .constant("1"))
    }
}
