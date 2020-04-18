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
        .navigationBarTitle(Text(viewModel.state.title), displayMode: .inline)
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
        case let .reloading(item):
            return content(for: item).eraseToAnyView()
        }
    }

    private var splitEmptyView: some View {
        SplitEmptyView() {
            self.viewModel.presentSheet(with: .newExpense)
        }
    }

    private func content(for item: SplitDetailViewModel.ListItem) -> some View {
        ZStack(alignment: .bottomTrailing) {
            contentLists(for: item)
            PlusButton {
                self.viewModel.presentSheet(with: .newExpense)
            }.offset(x: -24, y: -44)
        }
        .listStyle(GroupedListStyle())
    }

    private func contentLists(for item: SplitDetailViewModel.ListItem) -> some View {
        List {
            Section(header: FormSectionHeader(key: "split.view.settle-header")) {
                list(of: item.payments)
            }

            Section(header: FormSectionHeader(key: "split.view.overview-header")) {
                list(of: item.expenses)
            }
        }
    }

    private func list(of payments: [PaymentDisplayModel]) -> some View {
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

    private func list(of expenses: [ExpenseDisplayModel]) -> some View {
        ForEach(expenses) { expense in
            Button(action: {
                self.viewModel.presentSheet(with: .expense(expense.id))
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
            return NewExpenseView(viewModel: NewExpenseViewModel(splitId: viewModel.state.splitId)).eraseToAnyView()
        case let .expense(expenseId):
            return EditExpenseView(viewModel: EditExpenseViewModel(splitId: viewModel.state.splitId, expenseId: expenseId)).eraseToAnyView()
        }
    }

    // MARK: - Actions

    private func removeExpense(at offsets: IndexSet) {
        viewModel.send(event: .onRemoveExpenses(offsets: offsets))
    }
}

struct SplitView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SplitDetailView(viewModel: SplitDetailViewModel(splitId: 0, title: "Dinner"))
        }
    }
}
