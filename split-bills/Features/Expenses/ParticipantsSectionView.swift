//
//  ParticipantsSectionView.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 7/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import SwiftUI

struct NewExpenseParticipantsView: View {

    static private let splitTypes = ["Equally", "Amount"]

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
                        ForEach(0 ..< NewExpenseParticipantsView.splitTypes.count) {
                            Text(NewExpenseParticipantsView.splitTypes[$0]).tag($0)
                        }
                    }.pickerStyle(SegmentedPickerStyle())
                }

                containedView()
            }
        }
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
        NewExpenseParticipantsView(viewModel: .example)
    }
}
