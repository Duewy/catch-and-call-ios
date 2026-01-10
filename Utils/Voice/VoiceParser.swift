//
//  VoiceParser.swift
//  CatchAndCall
//
//  Created by Dwayne Brame on 2026-01-07.
//

import Foundation

enum MeasurementMode {
    case lbsOz
    case pounds
    case kilograms
    case inches
    case centimeters
}

//MARK:  - Measurement Modes for Touranment Case Select --

extension MeasurementMode {
    static func from(settingsMode: String) -> MeasurementMode {
        switch settingsMode {
        case "lbs_oz":       return .lbsOz
        case "decimal_lbs":  return .pounds
        case "kgs":          return .kilograms
        case "inches":       return .inches
        case "centimeters":  return .centimeters
        default:             return .lbsOz
        }
    }
}

//MARK: - Parsing Catch --

struct ParsedCatch {
    let species: String
    let clipColor: String

    // Weight
    let weightLbs: Int
    let weightOz: Int
    let weightPounds: Int
    let weightDec: Int
    let weightKgWhole: Int
    let weightGrams: Int

    // Length
    let lengthInches: Int
    let lengthQuarters: Int
    let lengthCm: Int
    let lengthTenths: Int
}

// MARK: - Parsed State

private var lastParsedCatch: ParsedCatch?


enum VoiceParser {

    
    // MARK: - Entry Point (Tournament)

    static func parseTournamentCatch(
        transcript: String,
        measurementMode: MeasurementMode,
        speciesList: [String],
        clipColors: [String]
    ) -> ParsedCatch {

        let cleanText = replaceNumberWords(normalize(transcript))

        let clipColor = extractClipColor(from: cleanText, allowed: clipColors)  //TODO: user may just say on White Clip.... not clipColor is ... I think this just removes the color from that... but what if it is a RedSnapper ???? 
        let withoutClip = removeWord(clipColor, from: cleanText)

        let species = extractSpecies(from: withoutClip, speciesList: speciesList)

        switch measurementMode {

        case .lbsOz:
            let lbs = matchInt(pattern: #"(\d{1,2})\s*(pounds?|lbs?)"#, in: cleanText)
            let oz  = matchInt(pattern: #"(\d{1,2})\s*(ounces?|ozs?)"#, in: cleanText)

            return ParsedCatch(
                species: species,
                clipColor: clipColor,
                weightLbs: lbs,
                weightOz: oz,
                weightPounds: 0,
                weightDec: 0,
                weightKgWhole: 0,
                weightGrams: 0,
                lengthInches: 0,
                lengthQuarters: 0,
                lengthCm: 0,
                lengthTenths: 0
            )

        case .pounds:
            let match = matchDecimal(
                pattern: #"(\d+)(?:[.]| point )(\d{1,2})"#,
                in: cleanText
            )

            return ParsedCatch(
                species: species,
                clipColor: clipColor,
                weightLbs: 0,
                weightOz: 0,
                weightPounds: match.whole,
                weightDec: match.dec,
                weightKgWhole: 0,
                weightGrams: 0,
                lengthInches: 0,
                lengthQuarters: 0,
                lengthCm: 0,
                lengthTenths: 0
            )

        case .kilograms:
            let match = matchDecimal(
                pattern: #"(\d+)(?:[.]| point )(\d{1,2})"#,
                in: cleanText
            )

            return ParsedCatch(
                species: species,
                clipColor: clipColor,
                weightLbs: 0,
                weightOz: 0,
                weightPounds: 0,
                weightDec: 0,
                weightKgWhole: match.whole,
                weightGrams: match.dec,
                lengthInches: 0,
                lengthQuarters: 0,
                lengthCm: 0,
                lengthTenths: 0
            )

        case .inches:
            let inches = matchInt(pattern: #"(\d+)\s*(inches?|in)"#, in: cleanText)
            let quarters = extractQuarters(from: cleanText)

            return ParsedCatch(
                species: species,
                clipColor: clipColor,
                weightLbs: 0,
                weightOz: 0,
                weightPounds: 0,
                weightDec: 0,
                weightKgWhole: 0,
                weightGrams: 0,
                lengthInches: inches,
                lengthQuarters: quarters,
                lengthCm: 0,
                lengthTenths: 0
            )

        case .centimeters:
            let match = matchDecimal(
                pattern: #"(\d+)(?:[.]| point )(\d{1})"#,
                in: cleanText
            )

            return ParsedCatch(
                species: species,
                clipColor: clipColor,
                weightLbs: 0,
                weightOz: 0,
                weightPounds: 0,
                weightDec: 0,
                weightKgWhole: 0,
                weightGrams: 0,
                lengthInches: 0,
                lengthQuarters: 0,
                lengthCm: match.whole,
                lengthTenths: match.dec
            )
        }
    }

    // MARK: - Setting Up Number Values...
    
    private static func replaceNumberWords(_ text: String) -> String {
        let map: [String: String] = [
            "zero": "0",
            "one": "1",
            "two": "2",
            "three": "3",
            "four": "4",
            "five": "5",
            "six": "6",
            "seven": "7",
            "eight": "8",
            "nine": "9",
            "ten": "10",
            "eleven": "11",
            "twelve": "12",
            "thirteen": "13",
            "fourteen": "14",
            "fifteen": "15"
        ]

        var result = text
        for (word, digit) in map {
            result = result.replacingOccurrences(
                of: "\\b\(word)\\b",
                with: digit,
                options: .regularExpression
            )
        }
        return result
    }

    
    // MARK: - Helpers

    private static func normalize(_ text: String) -> String {
        text
            .lowercased()
            .replacingOccurrences(of: #"[^a-z0-9\s]"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func extractSpecies(
        from text: String,
        speciesList: [String]
    ) -> String {
        for species in speciesList {
            let normalizedText = text.replacingOccurrences(of: " ", with: "")
            let normalizedSpecies = species.lowercased().replacingOccurrences(of: " ", with: "")

            if normalizedText.contains(normalizedSpecies) {

                return species
            }
        }
        return "Unknown"
    }

    private static func extractClipColor(
        from text: String,
        allowed: [String]
    ) -> String {
        for color in allowed {
            if text.contains(color.lowercased()) {
                return color
            }
        }
        return ""
    }

    private static func removeWord(_ word: String, from text: String) -> String {
        guard !word.isEmpty else { return text }
        return text.replacingOccurrences(
            of: "\\b\(word.lowercased())\\b",
            with: "",
            options: .regularExpression
        )
    }

    private static func matchInt(pattern: String, in text: String) -> Int {
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(text.startIndex..., in: text)
        guard
            let match = regex?.firstMatch(in: text, range: range),
            let r = Range(match.range(at: 1), in: text)
        else { return 0 }

        return Int(text[r]) ?? 0
    }

    private static func matchDecimal(
        pattern: String,
        in text: String
    ) -> (whole: Int, dec: Int) {
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(text.startIndex..., in: text)

        guard
            let match = regex?.firstMatch(in: text, range: range),
            let wholeRange = Range(match.range(at: 1), in: text),
            let decRange = Range(match.range(at: 2), in: text)
        else { return (0, 0) }

        let whole = Int(text[wholeRange]) ?? 0
        let dec   = Int(text[decRange].padding(toLength: 2, withPad: "0", startingAt: 0)) ?? 0

        return (whole, dec)
    }

    private static func extractQuarters(from text: String) -> Int {
        if text.contains("one quarter") { return 1 }
        if text.contains("two quarters") { return 2 }
        if text.contains("three quarters") { return 3 }
        return 0
    }
}

