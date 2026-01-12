//
//  PracticeProgress.swift
//  CatchAndCall_VCC
//
//  Created by Dwayne Brame on 2026-01-06.
//

import Foundation
import SwiftUI

enum PracticeProgressState {
    case new
    case learning
    case mastered
}

extension PracticePhrase {

    static let masteredThreshold = 4

    var progressState: PracticeProgressState {
        if isMastered || successCount >= Self.masteredThreshold {
            return .mastered
        } else if successCount > 0 {
            return .learning
        } else {
            return .new
        }
    }

    var progressColor: Color {
        switch progressState {
        case .new:
            return .practiceNew
        case .learning:
            return .practiceLearning
        case .mastered:
            return .practiceMastered
        }
    }
}

extension Color {
    static let practiceNew = Color.clipYellow       // 0
    static let practiceLearning = Color.darkYellow  // 1 to 3 successes
    static let practiceMastered = Color.brightGreen // 4 + successes
}

