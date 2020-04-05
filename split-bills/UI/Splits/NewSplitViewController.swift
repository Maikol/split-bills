//
//  NewSplitViewController.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 6/8/18.
//  Copyright © 2018 Carlos Miguel de Elias. All rights reserved.
//

import UIKit
import Eureka

final class NewSplitViewController: FormViewController {

    private let viewModel: NewSplitViewModel

    init(viewModel: NewSplitViewModel) {
        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.largeTitleDisplayMode = .never

        buildView()
        buildForm()
    }

    private func buildView() {
        title = NSLocalizedString("new-split-controller.title", comment: "")

        tableView.backgroundColor = ColorStyle.light.value
    }

    private func buildForm() {
        let eventSection = Section {
            var header = HeaderLabel.defaultHeader
            header.onSetupView = { view, _ in
                view.update(title: NSLocalizedString("new-split-controller.event-info", comment: ""))
            }
            $0.header = header
        }
            <<< TextRow() {
                $0.tag = "event-name"
                $0.add(rule: RuleRequired())
                $0.validationOptions = .validatesOnChange
                $0.value = viewModel.split?.eventName
                $0.cellUpdate { cell, _ in
                    cell.textField.apply(
                        style: .body(.dark),
                        placeholder: .init(text: NSLocalizedString("new-split-controller.event-name", comment: ""),
                                           style: .body(.fade)))
                    cell.titleLabel?.apply(style: .body(.dark))
                }
            }

        let participantsSection = MultivaluedSection(multivaluedOptions: [.Insert, .Delete]) {
                var header = HeaderLabel.defaultHeader
                header.onSetupView = { view, _ in
                    view.update(title: NSLocalizedString("new-split-controller.participants", comment: ""))
                }
                $0.header = header
                $0.tag = "participants"
                $0.addButtonProvider = { section in
                    return ButtonRow() {
                        $0.title = NSLocalizedString("new-split-controller.add-participant", comment: "")
                    }.cellUpdate { cell, row in
                        cell.textLabel?.textAlignment = .left
                        cell.textLabel?.font = TextStyle.body(.dark).uiFont
                    }
                }
                $0.multivaluedRowToInsertAt = { index in
                    return NameRow() {
                        $0.cellUpdate { cell, _ in
                            let text = String(
                                format: NSLocalizedString("new-split-controller.participant-number.format", comment: ""),
                                index + 1)
                            cell.textField.apply(style: .body(.dark), placeholder: .init(text: text, style: .body(.fade)))
                            cell.titleLabel?.apply(style: .body(.dark))
                        }
                    }
                }
                $0 <<< NameRow() {
                    $0.add(rule: RuleRequired())
                    $0.cellUpdate { cell, _ in
                        cell.textField.apply(
                            style: .body(.dark),
                            placeholder: .init(
                                text: NSLocalizedString("new-split-controller.participant-placeholder.you", comment: ""),
                                style: .body(.fade)
                            ))
                        cell.titleLabel?.apply(style: .body(.dark))
                    }
                }
                $0 <<< NameRow() {
                    $0.add(rule: RuleRequired())
                    $0.cellUpdate { cell, _ in
                        cell.textField.apply(
                            style: .body(.dark),
                            placeholder: .init(
                                text: NSLocalizedString(
                                    "new-split-controller.participant-placeholder.participant-1", comment: ""),
                                style: .body(.fade)
                            ))
                        cell.titleLabel?.apply(style: .body(.dark))
                    }
                }
            }

        let submitSection = Section()
            <<< ButtonRow() {
                $0.title = NSLocalizedString("new-split-controller.save", comment: "")
                $0.cellUpdate { cell, _ in
                    cell.textLabel?.font = TextStyle.body(.dark).uiFont
                }
            }.onCellSelection { [weak self] _, _ in
                self?.saveSplit()
            }

        form += [eventSection, participantsSection, submitSection]
    }

    private func saveSplit() {
        guard form.validate().isEmpty else { return }

        guard let eventName = form.values()["event-name"] as? String else { return }

        guard let participantsSection = form.sectionBy(tag: "participants") as? MultivaluedSection, participantsSection.values().count > 1 else { return }

        let participants = participantsSection.values()
            .compactMap { $0 as? String }
            .map { Participant(name: $0, email: nil) }

        self.viewModel.createdNewSplit(name: eventName, participants: participants)
    }

    func addDismissButton() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonTapped))
    }

    // MARK: Actions

    @objc private func cancelButtonTapped() {
        self.dismiss(animated: true, completion: nil)
    }
}
