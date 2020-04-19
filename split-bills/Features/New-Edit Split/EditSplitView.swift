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
            ZStack {
                Color.background
                    .edgesIgnoringSafeArea(.bottom)
                contentView
                    .keyboardAdaptive()
            }
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
            return Color.background.eraseToAnyView()
        case .loading:
            return Color.background.eraseToAnyView()
        case let .loaded(_, split):
            return form(for: split).eraseToAnyView()
        case .saving:
            return Color.background.eraseToAnyView()
        }
    }

    private func form(for split: SplitEditModel) -> some View {
        Form {
            eventInfoView
            participantsList(for: split)

            Section {
                Button(action: saveSplit) {
                    Text("new-split-controller.save")
                        .font(.headline)
                        .accentColor(.link)
                        .alignment(.center)
                }
            }.disabled(!split.isValid)
        }
    }

    private var eventInfoView: some View {
        Section(header: FormSectionHeader(key: "new-split-controller.event-info")) {
            TextField("new-split-controller.event-name", text: viewModel.binding(for: \.name, event: EditSplitViewModel.Event.onNameChange))
        }
    }

    private func participantsList(for split: SplitEditModel) -> some View {
        Section(header: FormSectionHeader(key: "new-split-controller.participants")) {
            existingListOfParticipants(for: split.existingParticipants)
            dynamicListOfParticipants(for: split.activeNewParticipants)

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

    private func existingListOfParticipants(for existingParticipants: [ParticipantEditModel]) -> some View {
        ForEach(0 ..< existingParticipants.count, id: \.self) { index in
            TextField(
                "Participant \(index + 1)",
                text: self.viewModel.binding(for: \.existingParticipants[index].name) { value in
                    EditSplitViewModel.Event.onExistingParticipantNameChange(value, index)
            })
        }
    }

    private func dynamicListOfParticipants(for activeNewParticipants: [ParticipantEditModel]) -> some View {
        ForEach(activeNewParticipants) { participant in
            SplitParticipantRow(
                localizedKey: "new-split-controller.participant-placeholder.new-participant",
                name: self.viewModel.binding(for: \.newParticipants[participant.index].name) { value in
                    EditSplitViewModel.Event.onNewParticipantNameChange(value, participant.index)
                }
            ) {
                self.viewModel.send(event: .onRemoveParticipant(participant.index))
            }
        }
    }

    func saveSplit() {
        viewModel.send(event: .onSaveSplit)
        self.presentationMode.wrappedValue.dismiss()
    }
}

struct SplitEditView_Previews: PreviewProvider {
    static var previews: some View {
        EditSplitView(viewModel: EditSplitViewModel(splitId: 0))
    }
}
