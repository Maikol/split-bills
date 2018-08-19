//
//  Text.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 13/8/18.
//  Copyright © 2018 Carlos Miguel de Elias. All rights reserved.
//

import Foundation
import UIKit

enum Text {
    case headingWhite
    case heading3Brand

    enum Body {
        case brandBold
        case dark
        case darkBold
    }
    case body(Body)
}

enum Color {
    case brand
    case dark
    case white
    case fade
    case light
}

extension Text {

    var font: UIFont {
        switch self {
        case .headingWhite, .body(.dark):
            return UIFont(name: "HelveticaNeue-Light", size: size)!
        case .heading3Brand, .body(.brandBold), .body(.darkBold):
            return UIFont(name: "HelveticaNeue-Bold", size: size)!
        }
    }

    var size: CGFloat {
        switch self {
        case .headingWhite: return 36.0
        case .heading3Brand: return 20.0
        case .body: return 16.0
        }
    }

    var color: Color {
        switch self {
        case .headingWhite:
            return .white
        case .heading3Brand, .body(.brandBold):
            return .brand
        case .body(.dark), .body(.darkBold):
            return .dark
        }
    }
}

extension Color {

    var value: UIColor {
        switch self {
        case .brand: return UIColor(red: 0, green: 105/255.0, blue: 137/255.0, alpha: 1.0)
        case .dark: return UIColor(red: 60/255.0, green: 68/255.0, blue: 71/255.0, alpha: 1.0)
        case .white: return UIColor(red: 255/255.0, green: 255/255.0, blue: 255/255.0, alpha: 1.0)
        case .fade: return UIColor(red: 151/255.0, green: 151/255.0, blue: 151/255.0, alpha: 1.0)
        case .light: return UIColor(red: 234/255.0, green: 235/255.0, blue: 237/255.0, alpha: 1.0)
        }
    }
}

extension UILabel {

    convenience init(style: Text) {
        self.init()

        font = style.font
        textColor = style.color.value
    }
}
