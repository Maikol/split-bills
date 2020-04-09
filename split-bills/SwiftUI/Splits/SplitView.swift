//
//  SplitView.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 4/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import SwiftUI

struct SplitView: View {

    enum SheetType {
        case newExpense
        case expense(Expense)
    }

    @EnvironmentObject var controller: ApplicationController

    @ObservedObject var split: Split

    @State private var showingModal = false
    @State private var sheetType = SheetType.newExpense

    var body: some View {
        Group {
            if split.expenses.isEmpty {
                SplitEmptyView() {
                    self.sheetType = .newExpense
                    self.showingModal.toggle()
                }
            } else {
                ZStack(alignment: .bottomTrailing) {
                    SplitContentView(split: split) { expense in
                        self.sheetType = .expense(expense)
                        self.showingModal.toggle()
                    }
                    PlusButton {
                        self.sheetType = .newExpense
                        self.showingModal.toggle()
                    }.offset(x: -24, y: -44)
                }
            }
        }
        .sheet(isPresented: $showingModal) {
            self.containedSheet()
        }
        .background(Color.light)
        .edgesIgnoringSafeArea(.bottom)
        .navigationBarTitle(Text(split.eventName), displayMode: .inline)
        .listStyle(GroupedListStyle())
    }

    func containedSheet() -> AnyView {
        switch sheetType {
        case .newExpense:
            return AnyView(NewExpenseView(
                split: self.split,
                isPresented: self.$showingModal
            ).environmentObject(self.controller))
        case let .expense(expense):
            return AnyView(ExpenseView(
                isPresented: self.$showingModal,
                viewModel: expense.viewModel(with: self.split)
            ).environmentObject(self.controller))
        }
    }
}

private extension Expense {

    func viewModel(with split: Split) -> ExpenseViewModel {
        guard let payerIndex = split.participants.firstIndex(of: payer) else {
            fatalError("payer index not found")
        }

        let viewModel = ExpenseViewModel(participants: split.participants)
        viewModel.payerIndex = payerIndex
        viewModel.description = description
        viewModel.amount = String(amount)

        switch splitType {
        case .equallyWithAll:
            viewModel.splitEqually = true
        case .equallyCustom:
            viewModel.splitEqually = false
            viewModel.splitTypeIndex = 0
            viewModel.selections = split.participants.map { participant in
                ParticipantSelectionModel(participant: participant, isSelected: participantsWeight.contains { $0.participant == participant })
            }
        case .byAmount:
            viewModel.splitEqually = false
            viewModel.splitTypeIndex = 1
            viewModel.amounts = split.participants.map { participant in
                let storedAmount = participantsWeight.first { $0.participant == participant }.map { String($0.weight * amount) } ?? ""
                return ParticipantEntryModel(participant: participant, amount: storedAmount)
            }
        case .byWeight:
            fatalError("Shouldn't get here")
        }

        return viewModel
    }
}

struct SplitView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SplitView(split: .init(id: 0, eventName: "Asado", participants: []))
        }
    }
}
