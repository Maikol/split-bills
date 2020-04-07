//
//  NewSplitView.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 5/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import SwiftUI

struct NewSplitView: View {

    @EnvironmentObject var splitController: ApplicationController

    @Binding var isPresented: Bool

    @ObservedObject private var split = Split(
        id: 0,
        eventName: "",
        participants: [Participant(name: ""), Participant(name: "")]
    )

    var body: some View {
        NavigationView {
            Form {
                Section(header: FormSectionHeader(key: "new-split-controller.event-info")) {
                    TextField("new-split-controller.event-name", text: $split.eventName)
                }

                Section(header: FormSectionHeader(key: "new-split-controller.participants")) {
                    TextField("new-split-controller.participant-placeholder.you", text: $split.participants[0].name)
                    TextField("new-split-controller.participant-placeholder.participant-1", text: $split.participants[1].name)
                    ForEach(2 ..< split.participants.count, id: \.self) { index in
                        ParticipantRow(
                            label: "Participant \(index)",
                            participant: self.split.participants[index])
                        {
                            self.split.participants.remove(at: index)
                        }
                    }
                    Button(action: {
                        self.split.participants.append(Participant(name: ""))
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .accentColor(.green)
                            Text("new-split-controller.add-participant")
                                .apply(style: .body(.link))
                        }
                    }
                }

                Section {
                    Button(action: createSplit) {
                        Text("new-split-controller.save")
                            .apply(style: .body(.link))
                            .alignment(.center)
                    }
                }.disabled(!split.isValid)
            }
            .background(Color.light)
            .edgesIgnoringSafeArea(.bottom)
            .navigationBarTitle(Text("new-split-controller.title"), displayMode: .inline)
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

    private func deleteParticipant(at offsets: IndexSet) {
        split.participants.remove(atOffsets: offsets)
    }

    func createSplit() {
        split.participants.removeAll { $0.name.isEmpty }
        splitController.createEvent(name: split.eventName, participants: split.participants)
        isPresented.toggle()
    }
}

private struct ParticipantRow: View {

    var label: String
    @ObservedObject var participant: Participant
    var deleteAction: () -> Void

    var body: some View {
        HStack {
            Button(action: deleteAction) {
                Image(systemName: "minus.circle.fill")
                    .accentColor(.red)
            }
            TextField(label, text: $participant.name)
        }
    }
}

private extension Split {

    var isValid: Bool {
        guard !eventName.isEmpty,
            let firstParticipant = participants.first, !firstParticipant.name.isEmpty,
            let secondParticipant = participants[safe: 1], !secondParticipant.name.isEmpty else {
                return false
        }

        return true
    }
}

struct NewSplitView_Previews: PreviewProvider {
    static var previews: some View {
        NewSplitView(isPresented: .constant(true))
    }
}
