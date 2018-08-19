//
//  NavigationControllerExtensions.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 19/8/18.
//  Copyright © 2018 Carlos Miguel de Elias. All rights reserved.
//

import Foundation
import UIKit

extension UINavigationController {

    enum Style {
        case `default`
    }

    func apply(style: Style) {
        navigationBar.barTintColor = style.backgroundColor.value
        navigationBar.tintColor = style.textColor.value
        navigationBar.titleTextAttributes = [.foregroundColor: style.textColor.value]
    }
}

private extension UINavigationController.Style {

    var backgroundColor: Color {
        switch self {
        case .default: return .brand
        }
    }

    var textColor: Color {
        switch self {
        case .default: return .white
        }
    }
}
