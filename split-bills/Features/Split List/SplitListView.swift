//
//  SplitListView.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 4/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import Combine
import SwiftUI

struct SplitListView: View {

    @ObservedObject var viewModel: SplitListViewModel

    init(viewModel: SplitListViewModel) {
        self.viewModel = viewModel

        // TODO: There should be a better way
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = UIColor.brand
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().tintColor = .white

        UITableView.appearance().backgroundColor = .clear
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.background
                    .edgesIgnoringSafeArea(.bottom)
                content
            }
            .sheet(item: $viewModel.activeSheet, onDismiss: {
                self.viewModel.send(event: .onReload)
            }) { sheet in
                self.present(with: sheet)
            }
            .navigationBarTitle("root-controller.title")
        }
        .onAppear { self.viewModel.send(event: .onAppear) }
    }

    private var content: some View {
        switch viewModel.state {
        case .idle:
            return Color.background.eraseToAnyView()
        case .loading:
            return Color.background.eraseToAnyView()
        case let .loaded(items) where items.isEmpty:
            return SplitListEmptyView {
                self.viewModel.presentSheet(with: .new)
            }.eraseToAnyView()
        case let .loaded(items):
            return splitContentView(for: items).eraseToAnyView()
        }
    }

    private func splitContentView(for splits: [SplitDisplayModel]) -> some View {
        ZStack(alignment: .bottomTrailing) {
            List {
                Section(header: FormSectionHeader(key: "root-controller.groups")) {
                    self.list(of: splits).eraseToAnyView()
                }
            }.listStyle(GroupedListStyle())

            PlusButton {
                self.viewModel.presentSheet(with: .new)
            }.offset(x: -24, y: -44)
        }
    }

    private func list(of splits: [SplitDisplayModel]) -> some View {
        ForEach(splits) { split in
            NavigationLink(destination: SplitDetailView(viewModel: SplitDetailViewModel(splitId: split.id, title: split.name))) {
                SplitListItemView(
                    split: split,
                    editAction: {
                        self.viewModel.presentSheet(with: .edit(split))
                }) {
                    self.viewModel.send(event: .onRemoveSplit(split))
                }
            }
        }.onDelete(perform: removeSplit)
    }

    private func present(with sheet: SplitListViewModel.Sheet) -> some View {
        switch sheet.style {
        case .new:
            return NewSplitView(viewModel: NewSplitViewModel()).eraseToAnyView()
        case let .edit(split):
            return EditSplitView(viewModel: EditSplitViewModel(splitId: split.id)).eraseToAnyView()
        }
    }

    private func removeSplit(at offsets: IndexSet) {
        viewModel.send(event: .onRemoveSplits(offsets: offsets))
    }
}

struct SplitListView_Previews: PreviewProvider {
    static var previews: some View {
        SplitListView(viewModel: .init())
    }
}
