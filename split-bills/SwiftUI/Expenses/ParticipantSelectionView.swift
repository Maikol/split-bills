//
//  ParticipantSelectionView.swift
//  split-bills
//
//  Created by Carlos DeElias on 7/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import SwiftUI

struct ParticipantSelectionView: View {

    @ObservedObject var viewModel: ExpenseViewModel

    var body: some View {
        List {
            ForEach(0 ..< viewModel.selections.count, id: \.self) { index in
                ParticipantSelectRow(
                    name: self.viewModel.selections[index].participant.name,
                    isSelected: self.$viewModel.selections[index].isSelected)
            }
        }
    }
}

struct ParticipantSelection_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ParticipantSelectionView(viewModel: .example)
        }.navigationBarTitle(Text("New Expense"), displayMode: .inline)
    }
}
