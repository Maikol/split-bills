//
//  Text.swift
//  split-bills
//
//  Created by Carlos Miguel de Elias on 13/8/18.
//  Copyright © 2018 Carlos Miguel de Elias. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

enum TextStyle {
    case headingWhite
    case headingWhiteBold
    case heading2DarkBold
    case heading3WhiteBold

    enum BodyLarge {
        case dark
        case darkBold
        case whiteBold
    }
    case bodyLarge(BodyLarge)

    enum Body {
        case brandBold
        case dark
        case darkBold
        case fade
        case link
        case white
    }
    case body(Body)

    enum BodySmall {
        case darkBold
    }
    case bodySmall(BodySmall)
}

enum ColorStyle {
    case brand
    case dark
    case white
    case fade
    case light
    case link
}

extension TextStyle {

    // Legacy
    var uiFont: UIFont {
        switch self {
        case .headingWhite, .bodyLarge(.dark), .body(.dark), .body(.fade), .body(.link), .body(.white):
            return UIFont(name: "HelveticaNeue-Light", size: size)!
        case .headingWhiteBold, .heading2DarkBold, .heading3WhiteBold, .bodyLarge(.darkBold),
             .bodyLarge(.whiteBold), .body(.brandBold), .body(.darkBold), .bodySmall(.darkBold):
            return UIFont(name: "HelveticaNeue-Bold", size: size)!
        }
    }

    var font: Font {
        switch self {
        case .headingWhite, .bodyLarge(.dark), .body(.dark), .body(.fade), .body(.link), .body(.white):
            return .custom("HelveticaNeue-Light", size: size)
        case .headingWhiteBold, .heading2DarkBold, .heading3WhiteBold, .bodyLarge(.darkBold),
             .bodyLarge(.whiteBold), .body(.brandBold), .body(.darkBold), .bodySmall(.darkBold):
            return .custom("HelveticaNeue-Bold", size: size)
        }
    }

    var size: CGFloat {
        switch self {
        case .headingWhite, .headingWhiteBold: return 36.0
        case .heading2DarkBold: return 24.0
        case .heading3WhiteBold: return 20.0
        case .bodyLarge: return 18.0
        case .body: return 16.0
        case .bodySmall: return 14.0
        }
    }

    // Legacy
    var uiColor: ColorStyle {
        switch self {
        case .headingWhite, .headingWhiteBold, .bodyLarge(.whiteBold), .heading3WhiteBold, .body(.white):
            return .white
        case .body(.brandBold):
            return .brand
        case .heading2DarkBold, .body(.dark), .body(.darkBold), .bodyLarge(.dark),
             .bodyLarge(.darkBold), .bodySmall(.darkBold):
            return .dark
        case .body(.fade):
            return .fade
        case .body(.link):
            return .link
        }
    }

    var color: Color {
        switch self {
        case .headingWhite, .headingWhiteBold, .bodyLarge(.whiteBold), .heading3WhiteBold, .body(.white):
            return .white
        case .body(.brandBold):
            return .brand
        case .heading2DarkBold, .body(.dark), .body(.darkBold), .bodyLarge(.dark),
             .bodyLarge(.darkBold), .bodySmall(.darkBold):
            return .dark
        case .body(.fade):
            return .fade
        case .body(.link):
            return .link
        }
    }
}

extension ColorStyle {

    // Legacy
    var value: UIColor {
        switch self {
        case .brand: return UIColor(red: 0, green: 105/255.0, blue: 137/255.0, alpha: 1.0)
        case .dark: return UIColor(red: 60/255.0, green: 68/255.0, blue: 71/255.0, alpha: 1.0)
        case .white: return UIColor(red: 255/255.0, green: 255/255.0, blue: 255/255.0, alpha: 1.0)
        case .fade: return UIColor(red: 151/255.0, green: 151/255.0, blue: 151/255.0, alpha: 1.0)
        case .light: return UIColor(red: 234/255.0, green: 235/255.0, blue: 237/255.0, alpha: 1.0)
        case .link: return .systemBlue
        }
    }
}

extension Color {

    static let brand = Color("brand")
    static let dark = Color("dark")
    static let white = Color("white")
    static let fade = Color("fade")
    static let light = Color("light")
    static let link = Color("link")
}

extension UILabel {

    convenience init(style: TextStyle) {
        self.init()

        font = style.uiFont
        textColor = style.uiColor.value
    }
}
