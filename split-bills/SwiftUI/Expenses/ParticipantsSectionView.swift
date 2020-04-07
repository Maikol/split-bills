//
//  ParticipantsSectionView.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 7/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import SwiftUI

struct ParticipantsSectionView: View {

    @ObservedObject var viewModel: ExpenseViewModel

    var body: some View {
        containedView()
    }

    private func containedView() -> AnyView {
        switch viewModel.splitTypeIndex {
        case 0:
            return AnyView(Section {
                ParticipantSelectionView(viewModel: viewModel)
            })
        case  1:
            return AnyView(Section {
                ParticipantAmountView(viewModel: viewModel)
            })
        default:
            fatalError("This shouldn't happen")
        }
    }
}

struct ParticipantsSectionView_Previews: PreviewProvider {
    static var previews: some View {
        ParticipantsSectionView(viewModel: .example)
    }
}
