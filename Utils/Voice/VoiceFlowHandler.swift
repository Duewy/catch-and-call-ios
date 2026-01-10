//
//  VoiceFlowHandler.swift
//  CatchAndCall
//
//  Created by Dwayne Brame on 2026-01-09.
//

import Foundation

protocol VoiceFlowHandler {
    var kind: String { get } // "tournament" / "fun"
    func startPrompt() -> String
    func parse(transcript: String) -> ParsedCatch?
    func confirmPrompt(for parsed: ParsedCatch) -> String
    func save(parsed: ParsedCatch) async throws
    func postSaveFeedback(for parsed: ParsedCatch) async -> String? // optional
}

