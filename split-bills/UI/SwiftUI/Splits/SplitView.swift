//
//  SplitView.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 4/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import SwiftUI

struct SplitView: View {

    @EnvironmentObject var appController: ApplicationController
    @ObservedObject var split: Split

    @State private var showingNewExpense = false

    var body: some View {
        Group {
            if split.expenses.isEmpty {
                SplitEmptyView() { self.showingNewExpense.toggle() }
                    .sheet(isPresented: $showingNewExpense) {
                        NewExpenseView(split: self.split)
                }
            } else {
                List {
                    Text("Test")
                }
            }
        }
        .navigationBarTitle(Text(split.eventName), displayMode: .inline)
        .listStyle(GroupedListStyle())
    }
}

struct SplitView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SplitView(split: .init(id: 0, eventName: "Asado", participants: []))
        }
    }
}
