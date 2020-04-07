//
//  ParticipantSelection.swift
//  split-bills
//
//  Created by Carlos DeElias on 7/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import SwiftUI

struct ParticipantAmountView: View {

    @ObservedObject var participants: Participants

    var body: some View {
        List {
            ForEach(0 ..< participants.participants.count, id: \.self) { index in
                ParticipantSelectRow(
                    name: self.participants.participants[index].name,
                    isSelected: self.$participants.participants[index].isSelected)
            }
        }
    }
}

struct ParticipantSelectionView: View {

    @ObservedObject var participants: Participants

    var body: some View {
        List {
            ForEach(0 ..< participants.participants.count, id: \.self) { index in
                ParticipantSelectRow(
                    name: self.participants.participants[index].name,
                    isSelected: self.$participants.participants[index].isSelected)
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
