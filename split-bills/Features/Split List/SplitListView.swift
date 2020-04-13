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
            content
                .sheet(item: $viewModel.sheet) { sheet in
                    self.present(with: sheet)
                }
                .background(Color.background)
                .edgesIgnoringSafeArea(.bottom)
                .navigationBarTitle("root-controller.title")
        }
        .onAppear { self.viewModel.send(event: .onAppear) }
    }

    private var content: some View {
        switch viewModel.state {
        case .idle:
            return Color.clear.eraseToAnyView()
        case .loading:
            return EmptyView().eraseToAnyView()
        case let .loaded(items) where items.isEmpty:
            return SplitListEmptyView {
                self.viewModel.sheet = .init(style: .new)
            }.eraseToAnyView()
        case let .loaded(items):
            return ZStack(alignment: .bottomTrailing) {
                List {
                    Section(header: FormSectionHeader(key: "root-controller.groups")) {
                        self.list(of: items).eraseToAnyView()
                    }
                }.listStyle(GroupedListStyle())

                PlusButton {
                    self.viewModel.sheet = .init(style: .new)
                }.offset(x: -24, y: -44)
            }.eraseToAnyView()
        }
    }

    private func list(of items: [SplitListViewModel.ListItem]) -> some View {
        ForEach(items) { item in
            NavigationLink(destination: SplitView(split: Split(id: item.id, eventName: item.name, participants: []))) {
                SplitListItemView(
                    item: item,
                    editAction: {
                        self.viewModel.sheet = .init(style: .edit(item))
                }) {
                    self.viewModel.send(event: .onRemoveSplit(item))
                }
            }
        }.onDelete(perform: removeSplit)
    }

    private func present(with sheet: SplitListViewModel.Sheet) -> some View {
        switch sheet.style {
        case .new:
            return NewSplitView(viewModel: NewSplitViewModel()).eraseToAnyView()
        case let .edit(split):
            return EditSplitView(
                split: .example, // FIXME
                exisintgParticipansCount: 5 // FIXME
            ).eraseToAnyView()
        }
    }

    private func removeSplit(at offsets: IndexSet) {
        viewModel.send(event: .onRemoveSplits(offsets: offsets))
    }
}

struct SplitListView_Previews: PreviewProvider {
    static let dataSource = DatabaseController()

    static var previews: some View {
        SplitListView(viewModel: .init()).environmentObject(dataSource)
    }
}
