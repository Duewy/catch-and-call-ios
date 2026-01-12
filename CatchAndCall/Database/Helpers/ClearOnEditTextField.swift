//
//  ClearOnEditTextField.swift
//  CatchAndCall
//
//  Created by Dwayne Brame on 2025-10-30.
//

import Foundation
import SwiftUI
import UIKit

struct ClearOnEditTextField: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let keyboard: UIKeyboardType
    let alignRight: Bool
    let clearsOnBeginEditing: Bool
    let digitsOnly: Bool
    let clampOunces015: Bool
    var font: UIFont? = nil

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: ClearOnEditTextField

        init(_ parent: ClearOnEditTextField) {
            self.parent = parent
        }

        // Filter input as you type
        func textField(_ textField: UITextField,
                       shouldChangeCharactersIn range: NSRange,
                       replacementString string: String) -> Bool {
            // Build prospective string
            let current = textField.text ?? ""
            guard let swiftRange = Range(range, in: current) else { return false }
            var next = current.replacingCharacters(in: swiftRange, with: string)

            if parent.digitsOnly {
                next = next.filter { $0.isNumber }
            }

            if parent.clampOunces015, let val = Int(next), val > 15 {
                next = "15"
            }

            textField.text = next
            parent.text = next
            // We already set text; returning false prevents default insert (avoids cursor oddities)
            return false
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            if parent.clearsOnBeginEditing {
                textField.text = ""
                parent.text = ""
            }
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            // no-op
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UITextField {
        let tf = UITextField(frame: .zero)
        tf.delegate = context.coordinator
        tf.placeholder = placeholder
        tf.keyboardType = keyboard
        tf.clearButtonMode = .never
        tf.borderStyle = .roundedRect
        tf.clearsOnBeginEditing = clearsOnBeginEditing
        tf.textAlignment = alignRight ? .right : .left
        tf.backgroundColor = UIColor (Color.veryLiteGrey)
        tf.font = font ?? UIFont.systemFont(ofSize: 25)
        tf.setContentHuggingPriority(.defaultLow, for: .horizontal)
        tf.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return tf
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        // Keep UIKit view in sync with SwiftUI state only if needed (avoids cursor jumps)
        if uiView.text != text { uiView.text = text }
        uiView.textAlignment = alignRight ? .right : .left
        uiView.clearsOnBeginEditing = clearsOnBeginEditing
        uiView.keyboardType = keyboard
    }
}

