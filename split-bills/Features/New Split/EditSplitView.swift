//
//  EditSplitView.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 11/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import SwiftUI

struct EditSplitView: View {

    @Environment(\.presentationMode) var presentationMode

    @ObservedObject var viewModel: EditSplitViewModel

    var body: some View {
        NavigationView {
            KeyboardHost {
                contentView
            }
            .background(Color.background)
            .edgesIgnoringSafeArea(.bottom)
            .navigationBarTitle(Text("new-split-controller.title"), displayMode: .inline)
            .navigationBarItems(trailing:
                Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    Text("split-controller.cancel")
                        .apply(font: .body, color: .white)
                }
            )
        }.onAppear { self.viewModel.send(event: .onAppear) }
    }

    private var contentView: some View {
        switch viewModel.state {
        case .idle:
            return Color.clear.eraseToAnyView()
        case .loading:
            return Color.clear.eraseToAnyView()
        case let .loaded(item):
            return form(for: item).eraseToAnyView()
        }
    }

    private func form(for item: EditSplitViewModel.Item) -> some View {
        Form {
            eventInfoView
            participantsList(for: item)

            Section {
                Button(action: saveSplit) {
                    Text("new-split-controller.save")
                        .font(.headline)
                        .accentColor(.link)
                        .alignment(.center)
                }
            }.disabled(!item.isValid)
        }
    }

    private var eventInfoView: some View {
        Section(header: FormSectionHeader(key: "new-split-controller.event-info")) {
            TextField("new-split-controller.event-name", text: viewModel.binding(for: \.name, event: EditSplitViewModel.Event.onNameChange))
        }
    }

    private func participantsList(for item: EditSplitViewModel.Item) -> some View {
        Section(header: FormSectionHeader(key: "new-split-controller.participants")) {
            ForEach(0 ..< item.originalParticipantsTotal, id: \.self) { index in
                self.requiredParticipantTextField(withIndex: index)
            }
            ForEach(item.participants.filter { $0.index >= item.originalParticipantsTotal && !$0.removed }.enumeratedArray(), id: \.element) { index, participant in
                self.dynamicParticipantView(withIndex: index + item.originalParticipantsTotal + 1, participant: participant)
            }
            Button(action: {
                self.viewModel.send(event: .onAddParticipant)
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .accentColor(.green)
                    Text("new-split-controller.add-participant")
                        .apply(font: .body, color: .link)
                }
            }
        }
    }

    private func requiredParticipantTextField(withIndex index: Int) -> some View {
        TextField(
            "Participant \(index + 1)",
            text: self.viewModel.binding(for: \.participants[index].name) { value in
                EditSplitViewModel.Event.onParticipantNameChange(value, index)
        })
    }

    private func dynamicParticipantView(withIndex index: Int, participant: EditSplitViewModel.Participant) -> some View {
        SplitParticipantRow(
            label: "Participant \(index)",
            name: self.viewModel.binding(for: \.participants[participant.index].name) { value in
                EditSplitViewModel.Event.onParticipantNameChange(value, participant.index)
            })
        {
            self.viewModel.send(event: .onRemoveParticipant(participant.index))
        }
    }

    func saveSplit() {
//        split.participants.removeAll { $0.name.isEmpty }
//        controller.update(split: split)
        self.presentationMode.wrappedValue.dismiss()
    }
}

struct SplitEditView_Previews: PreviewProvider {
    static var previews: some View {
        EditSplitView(viewModel: EditSplitViewModel(splitId: 0))
    }
}
