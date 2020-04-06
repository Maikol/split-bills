//
//  NewExpenseView.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 6/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import SwiftUI

struct ParticipantSelectionModel: Identifiable, Hashable {

    let id = UUID()
    let name: String
    var isSelected = true

    init(name: String) {
        self.name = name
    }
}

final class Participants: ObservableObject {

    @Published var participants: [ParticipantSelectionModel]

    init(names: [String]) {
        participants = names.map { ParticipantSelectionModel(name: $0) }
    }
}

struct ParticipantSelectRow: View {

    var name: String
    @Binding var isSelected: Bool

    var body: some View {
        Button(action: {
            self.isSelected.toggle()
        }) {
            HStack {
                Text(name)
                    .apply(style: .body(.darkBold))
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(ColorStyle.brand.color)
                }
            }
        }

    }
}

struct ParticipantSelection: View {

    @ObservedObject var participants: Participants

    var body: some View {
        List {
            ForEach(0 ..< participants.participants.count, id: \.self) { index in
                ParticipantSelectRow(
                    name: self.participants.participants[index].name,
                    isSelected: self.$participants.participants[index].isSelected)
            }
        }
    }
}

struct NewExpenseView: View {

    static private let splitTypes = ["Equally", "Amount", "Weight"]

    var split: Split

    @ObservedObject private(set) var participants: Participants
    @State var payerIndex = 0
    @State var description = ""
    @State var amount = ""
    @State var splitEqually = true
    @State var splitTypeIndex = 0

    init(split: Split) {
        self.split = split
        self.participants = Participants(names: split.participants.map { $0.name })
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: FormSectionHeader(key: "expenses.new.info-header")) {
                    TextField("expenses.new.info-placeholder", text: $description)

                    Picker(selection: $payerIndex, label: Text("expenses.new.payer-header")) {
                        ForEach(0 ..< split.participants.count) {
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
                                Text(NewExpenseView.splitTypes[$0])
                            }
                        }.pickerStyle(SegmentedPickerStyle())
                    }

                    if splitTypeIndex == 0 {
                        ParticipantSelection(participants: participants)
                    }
                }
            }
            .navigationBarTitle(Text("expenses.new.title"), displayMode: .inline)
        }
    }
}

struct NewExpenseView_Previews: PreviewProvider {
    static var previews: some View {
        NewExpenseView(split: .example)
    }
}
