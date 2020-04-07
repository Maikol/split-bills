//
//  ParticipantSelection.swift
//  split-bills
//
//  Created by Carlos DeElias on 7/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import SwiftUI

struct ParticipantAmountRow: View {

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

struct ParticipantAmountView: View {

    @ObservedObject var participants: Participants

    var body: some View {
        List {
            ForEach(0 ..< participants.amounts.count, id: \.self) { index in
                ParticipantAmountRow(
                    name: self.participants.amounts[index].name,
                    amount: self.$participants.amounts[index].amount)
            }
        }
    }
}

struct ParticipantSelectionView: View {

    @ObservedObject var participants: Participants

    var body: some View {
        List {
            ForEach(0 ..< participants.selections.count, id: \.self) { index in
                ParticipantSelectRow(
                    name: self.participants.selections[index].name,
                    isSelected: self.$participants.selections[index].isSelected)
            }
        }
    }
}

struct ParticipantSelection_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ParticipantSelectionView(participants: Participants(names: ["Test"]))
        }.navigationBarTitle(Text("New Expense"), displayMode: .inline)
    }
}
