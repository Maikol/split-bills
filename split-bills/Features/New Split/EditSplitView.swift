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
            return Color.background.eraseToAnyView()
        case .loading:
            return Color.background.eraseToAnyView()
        case let .loaded(item):
            return form(for: item).eraseToAnyView()
        case .saving:
            return Color.clear.eraseToAnyView()
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
            ForEach(0 ..< item.existingParticipants.count, id: \.self) { index in
                self.requiredParticipantTextField(withIndex: index)
            }
            ForEach(0 ..< item.activeNewParticipants.count, id: \.self) { index in
                self.dynamicParticipantView(withIndex: index + item.existingParticipants.count, participant: item.activeNewParticipants[index])
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
            text: self.viewModel.binding(for: \.existingParticipants[index].name) { value in
                EditSplitViewModel.Event.onExistingParticipantNameChange(value, index)
        })
    }

    private func dynamicParticipantView(withIndex index: Int, participant: EditSplitViewModel.Participant) -> some View {
        SplitParticipantRow(
            label: "Participant \(index + 1)",
            name: self.viewModel.binding(for: \.newParticipants[participant.index].name) { value in
                EditSplitViewModel.Event.onNewParticipantNameChange(value, participant.index)
            })
        {
            self.viewModel.send(event: .onRemoveParticipant(participant.index))
        }
    }

    func saveSplit() {
        viewModel.send(event: .onSaveSplit)
        self.presentationMode.wrappedValue.dismiss()
    }
}

private extension EditSplitViewModel.Item {

    var activeNewParticipants: [EditSplitViewModel.Participant] {
        newParticipants.filter { !$0.removed }
    }
}

struct SplitEditView_Previews: PreviewProvider {
    static var previews: some View {
        EditSplitView(viewModel: EditSplitViewModel(splitId: 0))
    }
}
