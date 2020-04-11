//
//  NewExpenseParticipantsView.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 7/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import SwiftUI

struct NewExpenseParticipantsView: View {

    @ObservedObject var viewModel: ExpenseViewModel

    var body: some View {
        Group {
            Section(header: FormSectionHeader(key: "expenses.new.split-header")) {
                Toggle(isOn: $viewModel.splitEqually) {
                    Text("expenses.new.split-equally-header")
                }
            }

            if !viewModel.splitEqually {
                Section(header: FormSectionHeader(key: "expenses.new.split-differently")) {
                    Picker(selection: $viewModel.splitTypeIndex, label: Text("")) {
                        ForEach(0 ..< ExpenseViewModel.SplitTpe.allCases.count) {
                            Text(ExpenseViewModel.SplitTpe.allCases[$0].localized).tag($0)
                        }
                    }.pickerStyle(SegmentedPickerStyle())
                }

                containedView
            }
        }
    }

    private var containedView: some View {
        guard let splitType = ExpenseViewModel.SplitTpe(rawValue: viewModel.splitTypeIndex) else {
            fatalError("This shouldn't happen")
        }

        switch splitType {
        case .equally:
            return Section {
                ParticipantSelectionView(viewModel: viewModel)
            }.eraseToAnyView()
        case .amount:
            return Section {
                ParticipantAmountView(viewModel: viewModel)
            }.eraseToAnyView()
        }
    }
}

struct ParticipantsSectionView_Previews: PreviewProvider {
    static var previews: some View {
        NewExpenseParticipantsView(viewModel: .example)
    }
}
