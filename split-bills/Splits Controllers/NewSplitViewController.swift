//
//  NewSplitViewController.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 6/8/18.
//  Copyright © 2018 Carlos Miguel de Elias. All rights reserved.
//

import UIKit
import Eureka

protocol NewSplitViewControllerDelegate: class {
    func didCreateNewSplit(_ split: Split)
}

final class NewSplitViewController: FormViewController {

    weak var delegate: NewSplitViewControllerDelegate?

    private let split: Split?

    init(split: Split? = nil) {
        self.split = split

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
        title = "Bill"

        tableView.backgroundColor = Color.light.value
    }

    private func buildForm() {

        let eventSection = Section {
            var header = HeaderLabel.defaultHeader
            header.onSetupView = { view, _ in
                view.update(title: "Event info")
            }
            $0.header = header
        }
            <<< TextRow() {
                $0.tag = "event-name"
                $0.add(rule: RuleRequired())
                $0.validationOptions = .validatesOnChange
                $0.value = self.split?.eventName
                $0.cellUpdate { cell, _ in
                    cell.textField.apply(style: .body(.dark), placeholder: .init(text: "Event name", style: .body(.fade)))
                    cell.titleLabel?.apply(style: .body(.dark))
                }
            }

        let partnersSection = MultivaluedSection(
                multivaluedOptions: [.Insert, .Delete])
            {
                var header = HeaderLabel.defaultHeader
                header.onSetupView = { view, _ in
                    view.update(title: "Participants")
                }
                $0.header = header
                $0.tag = "participants"
                $0.addButtonProvider = { section in
                    return ButtonRow() {
                        $0.title = "Add participant"
                    }.cellUpdate { cell, row in
                        cell.textLabel?.textAlignment = .left
                        cell.textLabel?.font = Text.body(.dark).font
                    }
                }
                $0.multivaluedRowToInsertAt = { index in
                    return NameRow() {
                        $0.cellUpdate { cell, _ in
                            cell.textField.apply(style: .body(.dark), placeholder: .init(text: "Participant \(index + 1)", style: .body(.fade)))
                            cell.titleLabel?.apply(style: .body(.dark))
                        }
                    }
                }
                $0 <<< NameRow() {
                    $0.add(rule: RuleRequired())
                    $0.cellUpdate { cell, _ in
                        cell.textField.apply(style: .body(.dark), placeholder: .init(text: "You", style: .body(.fade)))
                        cell.titleLabel?.apply(style: .body(.dark))
                    }
                }
                $0 <<< NameRow() {
                    $0.add(rule: RuleRequired())
                    $0.cellUpdate { cell, _ in
                        cell.textField.apply(style: .body(.dark), placeholder: .init(text: "Participant 1", style: .body(.fade)))
                        cell.titleLabel?.apply(style: .body(.dark))
                    }
                }
            }

        let submitSection = Section()
            <<< ButtonRow() {
                $0.title = "Save"
                $0.cellUpdate { cell, _ in
                    cell.textLabel?.font = Text.body(.dark).font
                }
            }.onCellSelection { [weak self] _, _ in
                self?.saveSplit()
            }

        form += [eventSection, partnersSection, submitSection]
    }

    private func saveSplit() {
        guard form.validate().isEmpty else { return }

        guard let split = Split(form: form) else { return }

        self.delegate?.didCreateNewSplit(split)
    }

    func addDismissButton() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonTapped))
    }

    // MARK: Actions

    @objc private func cancelButtonTapped() {
        self.dismiss(animated: true, completion: nil)
    }
}

private extension Split {

    init?(form: Eureka.Form) {
        let dic = form.values()
        guard let eventName = dic["event-name"] as? String else {
            return nil
        }

        guard let participantsSection = form.sectionBy(tag: "participants") as? MultivaluedSection, participantsSection.values().count > 1 else {
            return nil
        }

        self.eventName = eventName
        self.participants = participantsSection.values()
            .compactMap { $0 as? String }
            .map { Participant(name: $0, email: nil) }
    }
}
