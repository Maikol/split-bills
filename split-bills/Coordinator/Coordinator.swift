//
//  Coordinator.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 3/4/20.
//  Copyright © 2020 Carlos Miguel de Elias. All rights reserved.
//

import UIKit

protocol Coordinator {
    var childCoordinators: [Coordinator] { get set }
    var navigationController: UINavigationController { get set }

    func start()
}
