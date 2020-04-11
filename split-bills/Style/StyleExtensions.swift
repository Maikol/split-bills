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

extension Color {

    static let brand = Color("brand")
    static let dark = Color("dark")
    static let white = Color("white")
    static let fade = Color("fade")
    static let background = Color("background")
    static let link = Color("link")
    static let error = Color("error")
}

extension UIColor {

    static let brand = UIColor(named: "brand")!
    static let dark = UIColor(named: "dark")!
    static let fade = UIColor(named: "fade")!
    static let background = UIColor(named: "background")!
    static let link = UIColor(named: "link")!
    static let error = UIColor(named: "error")!
}

extension UIFont {

    func withTraits(traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        let descriptor = fontDescriptor.withSymbolicTraits(traits)
        return UIFont(descriptor: descriptor!, size: 0) //size 0 means keep the size as it is
    }

    func bold() -> UIFont {
        return withTraits(traits: .traitBold)
    }

    func italic() -> UIFont {
        return withTraits(traits: .traitItalic)
    }
}
