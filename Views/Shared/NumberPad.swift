//
//  NumberPad.swift
//  CatchAndCall
//
//  Created by Dwayne Brame on 2025-10-31.
//

import Foundation
import SwiftUI

public struct NumberPad: View {
    public enum Target { case pounds, ounces, generic }

    @Binding var text: String
    let target: Target
    let onDone: () -> Void
    var maxLen: Int? = nil
    var clampRange: ClosedRange<Int>? = nil

    public init(
        text: Binding<String>,
        target: Target = .generic,
        maxLen: Int? = nil,
        clampRange: ClosedRange<Int>? = nil,
        onDone: @escaping () -> Void
    ) {
        self._text = text
        self.target = target
        self.maxLen = maxLen
        self.clampRange = clampRange
        self.onDone = onDone
    }

    private func append(_ d: String) {
        var next = (text + d).filter { $0.isNumber }
        if let maxLen, next.count > maxLen { next = String(next.prefix(maxLen)) }
        if let clampRange, let v = Int(next) {
            if v < clampRange.lowerBound { next = String(clampRange.lowerBound) }
            if v > clampRange.upperBound { next = String(clampRange.upperBound) }
        }
        text = next
    }

    private func backspace() {
        if !text.isEmpty { text.removeLast() }
    }

    private var rows: [[String]] { [["1","2","3"], ["4","5","6"], ["7","8","9"], ["0"]] }

    public var body: some View {
        VStack(spacing: 8) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { key in
                        Button {
                            switch key {
                            case "⌫": backspace()
                            case "Done": onDone()
                            default: append(key)
                            }
                        } label: {
                            Text(key)
                                .font(.system(size: 22, weight: .semibold))
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.veryLiteGrey, lineWidth: 1))
                        }
                    }
                }
            }
        }
        .padding(10)
        .background(Color.liteGrey.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .contain)
    }
}

