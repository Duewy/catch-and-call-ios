//  UserSelectedClipColors.swift
//  CatchAndCall
//
//  Central place for clip color mapping order and color value

import SwiftUI

enum ClipColorUtils {

    // --- Default clip order ---
    // Color Order is arranged to best assist Visually/Color Impared
    static let defaultOrder: [String] = [
        "BLUE",
        "YELLOW",
        "GREEN",
        "ORANGE",
        "WHITE",
        "RED"
    ]

    // MARK: - Active clip order (future: load from user prefs)
    static func activeClipOrder() -> [String] {
        return defaultOrder
    }

    // MARK: - Color mapping

    /// Background color for a given clip color name (BLUE, YELLOW, etc.)
    static func bg(_ name: String) -> Color {
        switch name.uppercased() {
        case "BLUE":   return Color.clipBlue
        case "YELLOW": return Color.clipYellow
        case "GREEN":  return Color.clipGreen
        case "ORANGE": return Color.clipOrange
        case "WHITE":  return Color.clipWhite
        case "RED":    return Color.clipRed
        default:       return Color.veryLiteGrey.opacity(0.85)
        }
    }

    /// Foreground text color that will be readable on the background.
    static func fg(_ name: String) -> Color {
        name.uppercased() == "BLUE" ? .white : .black
    }

}
