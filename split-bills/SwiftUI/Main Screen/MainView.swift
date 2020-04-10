//
//  MainView.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 4/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import Combine
import SwiftUI

struct MainView: View {

    private enum SplitSheet {
        case new
        case edit(Split)
    }

    @EnvironmentObject var controller: ApplicationController

    @State private var selectedSheet = SplitSheet.new
    @State private var showingSplitSheet = false

    init() {
        // TODO: There should be a better way
        let style = UINavigationController.Style.default
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = UIColor.brand
        appearance.titleTextAttributes = [.foregroundColor: style.textColor.value, .font: style.font]
        appearance.largeTitleTextAttributes = [.foregroundColor: style.textColor.value, .font: style.largeFont]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().tintColor = style.textColor.value

        UITableView.appearance().backgroundColor = .clear
    }

    var body: some View {
        NavigationView {
            Group {
                if controller.splits.isEmpty {
                    MainEmptyView {
                        self.selectedSheet = .new
                        self.showingSplitSheet.toggle()
                    }
                } else {
                    ZStack(alignment: .bottomTrailing) {
                        List {
                            Section(header: FormSectionHeader(key: "root-controller.groups")) {
                                ForEach(controller.splits) { split in
                                    SplitRow(
                                        split: split,
                                        editAction: {
                                            self.selectedSheet = .edit(split)
                                            self.showingSplitSheet.toggle()
                                    }) {
                                        self.remove(split: split)
                                    }
                                }.onDelete(perform: removeSplit)
                            }
                        }.listStyle(GroupedListStyle())

                        PlusButton {
                            self.selectedSheet = .new
                            self.showingSplitSheet.toggle()
                        }.offset(x: -24, y: -44)
                    }
                }
            }
            .sheet(isPresented: $showingSplitSheet) {
                self.containedSheet()
            }
            .background(Color.background)
            .edgesIgnoringSafeArea(.bottom)
            .navigationBarTitle("root-controller.title")
        }
    }

    private func containedSheet() -> AnyView {
        switch selectedSheet {
        case .new:
            return AnyView(NewSplitView(isPresented: self.$showingSplitSheet).environmentObject(self.controller))
        case let .edit(split):
            return AnyView(
                EditSplitView(
                    split: split,
                    isPresented: self.$showingSplitSheet,
                    exisintgParticipansCount: split.participants.count
                ).environmentObject(self.controller)
            )
        }
    }

    private func removeSplit(at offsets: IndexSet) {
        for index in offsets {
            let split = controller.splits[index]
            remove(split: split)
        }
    }

    private func remove(split: Split) {
        controller.remove(split: split)
    }
}

struct MainView_Previews: PreviewProvider {
    static let dataSource = ApplicationController()

    static var previews: some View {
        MainView().environmentObject(dataSource)
    }
}
