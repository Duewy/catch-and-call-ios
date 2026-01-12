//
//  FilledButtonStyles.swift
//  CatchAndCall
//
//  Created by Dwayne Brame on 2025-11-17.
//

import Foundation
import SwiftUI

// MARK: - Filled Button Style (solid background)

struct FilledButtonStyle: ButtonStyle {
    let background: Color
    let foreground: Color
    let cornerRadius: CGFloat

    init(
        background: Color,
        foreground: Color = .black,
        cornerRadius: CGFloat = 10
    ) {
        self.background = background
        self.foreground = foreground
        self.cornerRadius = cornerRadius
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .foregroundColor(foreground)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(background.opacity(configuration.isPressed ? 0.7 : 1.0))
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Outline Button Style (just a colored border)

struct OutlineButtonStyle: ButtonStyle {
    let color: Color
    let cornerRadius: CGFloat

    init(
        color: Color,
        cornerRadius: CGFloat = 10
    ) {
        self.color = color
        self.cornerRadius = cornerRadius
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .foregroundColor(color)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(color, lineWidth: 2)
                    .opacity(configuration.isPressed ? 0.7 : 1.0)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preset Styles (blue / green / yellow / red / halo etc.)

enum AppButtonStyles {
    // 🔵 solid blue
    static let blueFilled =
        FilledButtonStyle(background: .blue)

    // 🟢 solid green (your old GreenButtonStyle)
    static let greenFilled =
        FilledButtonStyle(background: .green)

    // 🟡 solid yellow with dark text
    static let yellowFilled =
        FilledButtonStyle(background: .yellow, foreground: .black)

    // 🔴 solid red
    static let redFilled =
        FilledButtonStyle(background: .red)

    // 🔵 outlined blue (like Android outline buttons)
    static let blueOutline =
        OutlineButtonStyle(color: .blue)

    // 🟢 outlined green
    static let greenOutline =
        OutlineButtonStyle(color: .green)

    // 🟡 outlined yellow
    static let yellowOutline =
        OutlineButtonStyle(color: .yellow)

    // Example “halo” (white fill, colored border)
    static let haloGreen =
        OutlineButtonStyle(color: .green)
}

