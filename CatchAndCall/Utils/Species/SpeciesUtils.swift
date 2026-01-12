//  SpeciesUtils.swift
//  CatchAndCall
//
//  Shared helpers for
//      defaults + user-selected species lists
//      Clip Colors 

import Foundation

enum SpeciesUtils {
    
    
    // --- Key for user-selected active species list ---
    private static let activeSpeciesKey = "activeSpeciesList"
      
    
    // =============================================================
    // MARK: - Tournament Clip Colors & Species Codes
    // =============================================================
    
    enum TournamentClipColors {
        /// Default clip color order used in Tournament views
        static let defaultOrder: [String] = [
            "BLUE",
            "YELLOW",
            "GREEN",
            "ORANGE",
            "WHITE",
            "RED"
        ]
    }
    
    enum TournamentSpeciesCode {
        
        // Vowels for consonant logic
        private static let vowels: Set<Character> = ["A", "E", "I", "O", "U"]
        
        /// Universal 2-letter SPECIES code used for:
        /// - Lane Labels
        /// - markerType stored in DB
        /// - Sorting tournaments
        
        static func code(from raw: String) -> String {
            let trimmed = raw
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard !trimmed.isEmpty else { return "--" }
            
            let upper = trimmed.uppercased()
            let words = upper.split(whereSeparator: { $0.isWhitespace })
            
            // CASE 1 — Two+ words → First letter of first two words
            if words.count >= 2 {
                let w1 = words[0].first ?? "X"
                let w2 = words[1].first ?? "X"
                return String([w1, w2])
            }
            
            // CASE 2 — Single word → First two consonants
            let chars = Array(words[0])
            let consonants = chars.filter { !vowels.contains($0) }
            
            if consonants.count >= 2 {
                return String(consonants[0...1])
            }
            
            if consonants.count == 1 {
                let c1 = consonants[0]
                let c2 = chars.first(where: { $0 != c1 }) ?? c1
                return String([c1, c2])
            }
            
            // Fallback: first two letters
            return String(chars.prefix(2))
        }
        
        /// ---  MarkerType  ALWAYS matches the SPECIES 2-letter code ---
        static func markerType(for species: String) -> String {
            return code(from: species)
        }
    }
}
