//
//  NewSplitView.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 5/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import SwiftUI

struct NewSplitView: View {

    @EnvironmentObject var controller: DatabaseController

    @Binding var isPresented: Bool

    @ObservedObject private var split = Split(
        id: 0,
        eventName: "",
        participants: [Participant(name: ""), Participant(name: "")]
    )

    var body: some View {
        NavigationView {
            KeyboardHost {
                Form {
                    Section(header: FormSectionHeader(key: "new-split-controller.event-info")) {
                        TextField("new-split-controller.event-name", text: $split.eventName)
                    }

                    Section(header: FormSectionHeader(key: "new-split-controller.participants")) {
                        TextField("new-split-controller.participant-placeholder.you", text: $split.participants[0].name)
                        TextField("new-split-controller.participant-placeholder.participant-1", text: $split.participants[1].name)
                        ForEach(2 ..< split.participants.count, id: \.self) { index in
                            SplitParticipantRow(
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
                                    .apply(font: .body, color: .link)
                            }
                        }
                    }

                    Section {
                        Button(action: createSplit) {
                            Text("new-split-controller.save")
                                .font(.headline)
                                .accentColor(.link)
                                .alignment(.center)
                        }
                    }.disabled(!split.isValid)
                }
            }
            .background(Color.background)
            .edgesIgnoringSafeArea(.bottom)
            .navigationBarTitle(Text("new-split-controller.title"), displayMode: .inline)
            .navigationBarItems(trailing:
                Button(action: {
                    self.isPresented.toggle()
                }) {
                    Text("split-controller.cancel")
                        .apply(font: .body, color: .white)
                }
            )
        }
    }

    private func deleteParticipant(at offsets: IndexSet) {
        split.participants.remove(atOffsets: offsets)
    }

    func createSplit() {
        split.participants.removeAll { $0.name.isEmpty }
        controller.createEvent(name: split.eventName, participants: split.participants)
        isPresented.toggle()
    }
}

struct NewSplitView_Previews: PreviewProvider {
    static var previews: some View {
        NewSplitView(isPresented: .constant(true))
    }
}
