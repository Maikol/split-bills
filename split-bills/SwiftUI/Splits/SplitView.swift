//
//  SplitView.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 4/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import SwiftUI

struct SplitView: View {

    @EnvironmentObject var controller: ApplicationController

    @ObservedObject var split: Split

    @State private var showingNewExpense = false

    var body: some View {
        Group {
            if split.expenses.isEmpty {
                SplitEmptyView() { self.showingNewExpense.toggle() }
                    .sheet(isPresented: $showingNewExpense) {
                        NewExpenseView(split: self.split, isPresented: self.$showingNewExpense).environmentObject(self.controller)
                }
            } else {
                List {
                    ForEach(split.expenses) {
                        Text($0.description)
                    }
                }
            }
        }
        .background(Color.light)
        .edgesIgnoringSafeArea(.bottom)
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
