//
//  NewExpenseView.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 6/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import SwiftUI

struct NewExpenseView: View {

    static private let splitTypes = ["Equally", "Amount", "Weight"]

    var split: Split

    @Binding var isPresented: Bool

    @ObservedObject private(set) var participants: Participants

    @State private var payerIndex = 0
    @State private var description = ""
    @State private var amount = ""
    @State private var splitEqually = true
    @State private var splitTypeIndex = 0

    init(split: Split, isPresented: Binding<Bool>) {
        self.split = split
        self._isPresented = isPresented
        self.participants = Participants(names: split.participants.map { $0.name })
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: FormSectionHeader(key: "expenses.new.info-header")) {
                    TextField("expenses.new.info-placeholder", text: $description)

                    Picker(selection: $payerIndex, label: Text("expenses.new.payer-header").apply(style: .body(.darkBold))) {
                        ForEach(0 ..< split.participants.count, id: \.self) {
                            Text(self.split.participants[$0].name)
                        }
                    }

                    HStack {
                        Text("expenses.new.amount-header")
                        Spacer()
                        TextField("0", text: $amount)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                            .frame(width: 150)
                    }
                }

                Section(header: FormSectionHeader(key: "expenses.new.split-header")) {
                    Toggle(isOn: $splitEqually) {
                        Text("expenses.new.split-equally-header")
                    }
                }

                if !splitEqually {
                    Section(header: FormSectionHeader(key: "expenses.new.split-differently")) {
                        Picker(selection: $splitTypeIndex, label: Text("")) {
                            ForEach(0 ..< NewExpenseView.splitTypes.count) {
                                Text(NewExpenseView.splitTypes[$0]).tag($0)
                            }
                        }.pickerStyle(SegmentedPickerStyle())
                    }

                    if splitTypeIndex == 0 {
                        Section {
                            ParticipantSelectionView(participants: participants)
                        }
                    } else if splitTypeIndex == 1 {
                        Section {
                            ParticipantAmountView(participants: participants)
                        }
                    }
                }
            }
            .background(Color.light)
            .edgesIgnoringSafeArea(.bottom)
            .navigationBarTitle(Text("expenses.new.title"), displayMode: .inline)
            .navigationBarItems(trailing:
                Button(action: {
                    self.isPresented.toggle()
                }) {
                    Text("split-controller.cancel")
                        .apply(style: .body(.white))
                }
            )
        }
    }
}

struct NewExpenseView_Previews: PreviewProvider {
    static var previews: some View {
        NewExpenseView(split: .example, isPresented: .constant(true))
    }
}
