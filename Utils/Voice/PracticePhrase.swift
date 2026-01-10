//
//  PracticePhrase.swift
//  CatchAndCall
//
//  Created by Dwayne Brame on 2026-01-02.
//

import Foundation

struct PracticePhrase: Identifiable, Codable {
    var id = UUID()
    let text: String

    var isMastered: Bool = false
    var successCount: Int = 0
    var failureCount: Int = 0
    var recentFailures: Int = 0
    var lastMisheardInput: String? = nil
    var skipSuggestionsFor: Set<String> = []
}

extension PracticePhrase {
    static let previewSample = PracticePhrase(
        text: "add a catch",
        isMastered: false,
        successCount: 0,
        failureCount: 0,
        recentFailures: 0,
        lastMisheardInput: nil,
        skipSuggestionsFor: []
    )
}

