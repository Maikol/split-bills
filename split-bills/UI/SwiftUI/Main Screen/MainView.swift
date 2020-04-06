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

    @EnvironmentObject var splitController: SplitController

    @State private var showingNewSplit = false

    init() {
        // TODO: There should be a better way
        let style = UINavigationController.Style.default
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = style.backgroundColor.value
        appearance.titleTextAttributes = [.foregroundColor: style.textColor.value, .font: style.font]
        appearance.largeTitleTextAttributes = [.foregroundColor: style.textColor.value, .font: style.largeFont]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().tintColor = style.textColor.value
    }

    var body: some View {
        NavigationView {
            Group {
                if splitController.splits.isEmpty {
                    MainEmptyView { self.showingNewSplit.toggle() }
                        .sheet(isPresented: $showingNewSplit) {
                            NewSplitView(isPresented: self.$showingNewSplit).environmentObject(self.splitController)
                    }
                    .offset(x: -24, y: -44)
                    .background(ColorStyle.light.color)
                    .edgesIgnoringSafeArea(.bottom)
                } else {
                    List(splitController.splits, rowContent: SplitRow.init)
                        .listStyle(GroupedListStyle())
                }
            }
            .navigationBarTitle("root-controller.title")
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static let dataSource = SplitController()

    static var previews: some View {
        MainView().environmentObject(dataSource)
    }
}
