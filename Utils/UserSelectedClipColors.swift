//  UserSelectedClipColors.swift
//  CatchAndCall
//
//  Central place for clip color mapping + (later) user-selected clip orders.

import SwiftUI

enum ClipColorUtils {

    // --- Default clip order (for tournaments, Fun Day, etc.) ---
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
        // Later: read from UserDefaults or SharedPreferences equivalent.
        // For now, always return the default order.
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

    // MARK: - (Later) saving user-selected clip order

    // static func saveActiveClipOrder(_ order: [String]) { ... }
    // When you build the Clip Color Setup page, you can implement this
    // to persist the user’s chosen order (max 6 colors).
}
