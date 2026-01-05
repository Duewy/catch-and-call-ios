//
//  AppColors.swift
//  CatchAndCall
//
//  Created by Dwayne Brame on 2025-10-30.
//

import Foundation
// AppColors.swift
// Shared color definitions mirroring Android colors.xml
// Supports #RRGGBB and Android-style #AARRGGBB (ARGB) hex.

import SwiftUI
import UIKit

// MARK: - HEX HELPERS (supports #RRGGBB and #AARRGGBB / ARGB)
private func parseHexRGBA(_ hexString: String) -> (r: Double, g: Double, b: Double, a: Double) {
    let cleaned = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: cleaned).scanHexInt64(&int)

    switch cleaned.count {
    case 6: // RRGGBB
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8)  & 0xFF) / 255.0
        let b = Double(int & 0xFF)        / 255.0
        return (r, g, b, 1.0)
    case 8: // AARRGGBB (Android ARGB)
        let a = Double((int >> 24) & 0xFF) / 255.0
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8)  & 0xFF) / 255.0
        let b = Double(int & 0xFF)        / 255.0
        return (r, g, b, a)
    default:
        return (1, 1, 1, 1) // fallback white
    }
}

extension Color {           // NOTE ASK about Moving these into the extensions below...
    init(androidHex hex: String) {
        let c = parseHexRGBA(hex)
        self.init(.sRGB, red: c.r, green: c.g, blue: c.b, opacity: c.a)
    }
}

extension UIColor {
    convenience init(androidHex hex: String) {
        let c = parseHexRGBA(hex)
        self.init(red: c.r, green: c.g, blue: c.b, alpha: c.a)
    }
}

// MARK: - Named palette (mirrors Android colors.xml)

extension Color {
    // Base
    static let nothing            = Color(androidHex: "#00FFFFFF") // transparent

    // Greys (solid)
    static let liteGrey           = Color(androidHex: "#FFAFAFAF")
    static let veryLiteGrey       = Color(androidHex: "#FFE5E5E5")

    // Clips / Highlights
    static let clipVeryGreen      = Color(androidHex: "#C0F448")
    static let clipBrightGreen    = Color(androidHex: "#66CC33")
    static let brightGreen        = Color(androidHex: "#EB24A108") // ARGB (semi-transparent)
    static let purple500          = Color(androidHex: "#FF6200EE")
    static let ltBrown            = Color(androidHex: "#C19268")
    static let darkYellow         = Color(androidHex: "#CCAA00")
    static let golden             = Color(androidHex: "#FFB700")

    // Theming
    static let mainBackground     = Color(androidHex: "#5196DB")
    static let secondary          = Color(androidHex: "#4169E1")
    static let secondaryVariant   = Color(androidHex: "#41B4E1")

    // Material dynamics (as-is)
    static let materialPrimary70  = Color(androidHex: "#72B0D1")
    static let materialNeutral90  = Color(androidHex: "#9CA1EC")

    // UI Accents
    static let highlightYellow    = Color(androidHex: "#F6DF0E")
    static let selectionList      = Color(androidHex: "#EAB383")

    // SoftLock clip colors
    static let clipBlue           = Color(androidHex: "#00007F")
    static let clipYellow         = Color(androidHex: "#FEFE20")
    static let clipGreen          = Color(androidHex: "#00800D")
    static let clipOrange         = Color(androidHex: "#FE671E")
    static let clipWhite          = Color(androidHex: "#FDFDFD")
    static let clipRed            = Color(androidHex: "#D50019")

    // Brand
    static let softlockBlue       = Color(androidHex: "#212199")
    static let softlockGreen      = Color(androidHex: "#21CF33")
    static let softlockSand       = Color(androidHex: "#FAE8B4")
    static let softlockOrange     = Color(androidHex: "#FFA500")
    static let softlockTeal       = Color(androidHex: "#0EAEAE")

    // Logging page (these remain semi-transparent by design)
    static let logRed             = Color(androidHex: "#C3D50011")
    static let logRedSecondary    = Color(androidHex: "#F41631")
    static let logYellowSecondary = Color(androidHex: "#80DACF05")
    static let logGreenSecondary  = Color(androidHex: "#806EA603")
    static let logWhite           = Color(androidHex: "#85FDFDFD")
    static let logOrange          = Color(androidHex: "#80FE671E")
    static let logBrown           = Color(androidHex: "#805E3A29")
    static let halo_light_blue    = Color(androidHex: "#33B5E5")
    static let add_button_teal    = Color(androidHex: "#049A89")
    
    // Tournament View Pages (space fillers on no entry rows)
    static let softRow: Color = Color(white: 0.97)
    static let softYellow: Color = Color(red: 1.0, green: 0.98, blue: 0.85)

}

// Optional: UIKit mirrors where needed
extension UIColor {
    static let clipVeryGreen  = UIColor(androidHex: "#C0F448")
    static let mainBackground = UIColor(androidHex: "#5196DB")
    
    // add more if a UIKit view needs them
}
