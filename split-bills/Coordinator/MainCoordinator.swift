//
//  MainCoordinator.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 3/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import UIKit

final class MainCoordinator: Coordinator {

    var childCoordinators = [Coordinator]()
    var navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        navigationController.apply(style: .default)

        let viewController = RootViewController(coordinator: self) // TODO: create view model
        navigationController.viewControllers = [viewController]
    }

    // Split

    func newSplit() {
        let viewModel = NewSplitViewModel(split: nil, coordinator: self)
        let viewController = NewSplitViewController(viewModel: viewModel)
        self.navigationController.pushViewController(viewController, animated: true)
    }

    func open(split: Split) {
        let viewModel = SplitViewModel(split: split, coordinator: self)
        let viewController = SplitViewController(viewModel: viewModel)
        navigationController.setViewControllers([rootViewController, viewController], animated: true)
    }

    func editSplit(split: Split) {
        let viewModel = NewSplitViewModel(split: split, coordinator: self)
        let viewController = NewSplitViewController(viewModel: viewModel)
        let newNavigationController = UINavigationController(rootViewController: viewController, style: .default)
        viewController.addDismissButton()
        navigationController.present(newNavigationController, animated: true, completion: nil)
    }

    func splitDeleted() {
        navigationController.popViewController(animated: true)
    }

    // Expense

    func open(split: Split, expense: Expense?) {
        let viewModel = NewExpenseViewModel(split: split, expense: expense, coordinator: self)
        let viewController = NewExpenseViewController(viewModel: viewModel)

        var navigationViewControllers = navigationController.viewControllers.filter { !($0 is NewExpenseViewController) }
        navigationViewControllers.append(viewController)
        navigationController.setViewControllers(navigationViewControllers, animated: true)
    }

    func dismissExpense() {
        guard topViewController is NewExpenseViewController else { return }
        navigationController.popViewController(animated: true)
    }
}

private extension MainCoordinator {

    var rootViewController: UIViewController {
        // Intentionally crash since we can't recover from not having a root view controller
        return navigationController.viewControllers.first!
    }

    var topViewController: UIViewController {
        // Intentionally crash since we can't recover from not having a top view controller
        return navigationController.topViewController!
    }
}
