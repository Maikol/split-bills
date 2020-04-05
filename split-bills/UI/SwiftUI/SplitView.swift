//
//  SplitView.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 4/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import SwiftUI

struct NewSplitView: View {
    var body: some View {
        Text("New split")
        .navigationBarTitle(Text("Bill"), displayMode: .inline)
    }
}

struct SplitView: View {
    @EnvironmentObject var splitController: SplitController
    var split: Split

    var body: some View {
        VStack {
            List {
                Section(header: Text("Settle")) {
                    Text("Text")
                }
                Section(header: Text("Overview")) {
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
