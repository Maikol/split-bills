//
//  SplitDetailView.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 4/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import SwiftUI

struct SplitDetailView: View {

    @ObservedObject var viewModel: SplitDetailViewModel

    var body: some View {
        ZStack {
            Color.background
                .edgesIgnoringSafeArea(.bottom)
            contentView
        }
        .sheet(item: $viewModel.activeSheet, onDismiss: {
            self.viewModel.send(event: .onReload)
        }) { sheet in
            self.containedSheet(sheet)
        }
        .onAppear { self.viewModel.send(event: .onAppear) }
    }

    private var contentView: some View {
        switch viewModel.state {
        case .idle:
            return Color.background.eraseToAnyView()
        case .loading:
            return Color.background.eraseToAnyView()
        case let .loaded(item) where item.expenses.isEmpty:
            return splitEmptyView.eraseToAnyView()
        case let .loaded(item):
            return content(for: item).eraseToAnyView()
        }
    }

    private var splitEmptyView: some View {
        SplitEmptyView() {
            self.viewModel.presentSheet(with: .newExpense)
        }
    }

    private func content(for item: SplitDetailViewModel.SplitItem) -> some View {
        ZStack(alignment: .bottomTrailing) {
            contentLists(for: item)
            PlusButton {
                self.viewModel.presentSheet(with: .newExpense)
            }.offset(x: -24, y: -44)
        }
        .listStyle(GroupedListStyle())
        .navigationBarTitle(Text(item.name), displayMode: .inline)
    }

    private func contentLists(for item: SplitDetailViewModel.SplitItem) -> some View {
        List {
            Section(header: FormSectionHeader(key: "split.view.settle-header")) {
                list(of: item.payments)
            }

            Section(header: FormSectionHeader(key: "split.view.overview-header")) {
                list(of: item.expenses)
            }
        }
    }

    private func list(of payments: [SplitDetailViewModel.Payment]) -> some View {
        ForEach(payments) { payment in
            HStack {
                Text(payment.payer.name)
                    .apply(font: .body, color: .dark, weight: .bold)
                Text("split.view.sttle.pays-to")
                    .apply(font: .body, color: .dark)
                Text(payment.receiver.name)
                    .apply(font: .body, color: .dark, weight: .bold)
                Spacer()
                Text(String(format: "%.2f", payment.amount))
                    .apply(font: .body, color: .dark, weight: .bold)
            }
        }
    }

    private func list(of expenses: [SplitDetailViewModel.Expense]) -> some View {
        ForEach(expenses) { expense in
            Button(action: {
                self.viewModel.send(event: .onSelectExpense(expense))
            }) {
                HStack {
                    Text(expense.name)
                        .apply(font: .body, color: .dark)
                    Spacer()
                    Text(String(expense.amount))
                        .apply(font: .body, color: .dark, weight: .bold)
                }
            }.foregroundColor(.primary)
        }.onDelete(perform: removeExpense)
    }

    private func containedSheet(_ sheet: SplitDetailViewModel.Sheet) -> some View {
        switch sheet.style {
        case .newExpense:
            return EmptyView()
//            return NewExpenseView(
//                split: self.split,
//                isPresented: self.$showingModal
//            ).environmentObject(self.controller).eraseToAnyView()
        case let .expense(expense):
            return EmptyView()
//            return ExpenseView(
//                isPresented: self.$showingModal,
//                split: self.split,
//                viewModel: expense.viewModel(with: self.split)
//            ).environmentObject(self.controller).eraseToAnyView()
        }
    }

    // MARK: - Actions

    private func removeExpense(at offsets: IndexSet) {
        viewModel.send(event: .onRemoveExpenses(offsets: offsets))
    }
}

private extension Expense {

    func viewModel(with split: Split) -> ExpenseViewModel {
        guard let payerIndex = split.participants.firstIndex(of: payer) else {
            fatalError("payer index not found")
        }

        let viewModel = ExpenseViewModel(participants: split.participants)
        viewModel.id = id
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
            SplitDetailView(viewModel: SplitDetailViewModel(splitId: 0))
        }
    }
}
