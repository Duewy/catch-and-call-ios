//
//  TournamentVoiceHandler.swift
//  CatchAndCall
//
//  Created by Dwayne Brame on 2026-01-07.
//

import Foundation

@MainActor
final class TournamentVoiceHandler {

    // MARK: - Dependencies

    private unowned let coordinator: VoiceSessionCoordinator
    private let voiceManager: VoiceManager
    private let tts: SpeechOutputService
    private var failSafeWorkItem: DispatchWorkItem?
    private let listenFailSafeSeconds: Double = 12.0
    
    // MARK: - State

    private var retryCount = 0
    private let maxRetries = 3

    private var inQuestionMode = false

    // MARK: - Parsed State

    private var lastParsedCatch: ParsedCatch?

    
    // MARK: - Init

    init(
        coordinator: VoiceSessionCoordinator,
        voiceManager: VoiceManager,
        tts: SpeechOutputService = SpeechOutputService()
    ) {
        self.coordinator = coordinator
        self.voiceManager = voiceManager
        self.tts = tts
    }


    // MARK: - Entry Point

    func start() {
        print("🏆 TournamentVoiceHandler.start()")

        coordinator.transition(to: .prompting)

        speak("Please say the weight, species, and clip color of your catch. Over.") { [weak self] in
            guard let self else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                self.listenForCatch()
            }
        }
    }

    // MARK: - Listening

    private func listenForCatch() {
        
        coordinator.transition(to: .listening)
        
        armFailSafe(reason: "catch listen")
        
        voiceManager.startTrainingListen { [weak self] transcript in
            guard let self else { return }
            self.cancelFailSafe()

            let cleaned = transcript.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            print("🎧 Heard: \(cleaned)")

            // Exit / cancel
            if cleaned.contains("cancel") || cleaned.contains("stop") {
                self.speak("Cancelled. Over and out.") {
                    self.coordinator.endSession(reason: "user cancel")
                }
                return
            }

            // Question mode
            if cleaned.contains("question") {
                self.enterQuestionMode()
                return
            }

            // Otherwise → treat as catch entry
            self.handleCatchTranscript(cleaned)
        }
    }

    // MARK: - Catch Handling (stub for now)

    private func handleCatchTranscript(_ transcript: String) {
        coordinator.transition(to: .confirming)

        // These will later come from settings / setup
        //TODO: working on intergreating Set Up to Tournament page
        let measurementMode: MeasurementMode = .lbsOz
        let speciesList = ["Largemouth", "Smallmouth", "Crappie", "Walleye"]
        let clipColors  = ["BLUE", "YELLOW", "GREEN", "ORANGE", "WHITE", "RED"]

        let parsed = VoiceParser.parseTournamentCatch(
            transcript: transcript,
            measurementMode: measurementMode,
            speciesList: speciesList,
            clipColors: clipColors
        )

        lastParsedCatch = parsed
        
        print("🟧 ParsedCatch:",
              "species =", parsed.species,
              "lbs =", parsed.weightLbs,
              "oz =", parsed.weightOz,
              "clip =", parsed.clipColor)

        // Basic validation (same idea as Android missingInfo)
        let missingInfo =
            parsed.species == "Unknown" ||
            parsed.clipColor.isEmpty ||
            (measurementMode == .lbsOz && parsed.weightLbs == 0 && parsed.weightOz == 0)

        if missingInfo {
            retryCatch()
            return
        }

        let confirmPrompt =
            "To confirm, your \(parsed.species) is " +
            "\(parsed.weightLbs) pounds and \(parsed.weightOz) ounces " +
            "on the \(parsed.clipColor) clip. Is that correct? Say yes, no, or cancel. Over."

        speak(confirmPrompt) { [weak self] in
            self?.listenForConfirmation()
        }
    }


    // MARK: - Confirmation

    private func listenForConfirmation() {
        coordinator.transition(to: .listening)
        armFailSafe(reason: "confirm listen")
        voiceManager.startTrainingListen { [weak self] response in
            guard let self else { return }

            let answer = response.lowercased()

            if answer.contains("yes") {
                self.saveCatch()
            } else if answer.contains("no") {
                self.retryCatch()
            } else if answer.contains("cancel") {
                self.speak("Cancelled. Over and out.") {
                    self.coordinator.endSession(reason: "cancel during confirm")
                }
            } else {
                self.retryConfirmation()
            }
        }
    }

    // MARK: - Save Catch (stub)
            //TODO: still need to wire into handsfree
    
    private func saveCatch() {
        print("🟩 saveCatch() called")

        guard let parsed = lastParsedCatch else {
            coordinator.endSession(reason: "no parsed catch")
            return
        }

        let nowSec = Int64(Date().timeIntervalSince1970)

        // ---- Measurement conversion (mirrors Android logic) ----
        let totalWeightOz: Int?
        let totalWeightHundredthLb: Int?
        let totalWeightHundredthKg: Int?
        let totalLengthQuarters: Int?
        let totalLengthCm: Int?

        switch currentMeasurementMode() {
        case .lbsOz:
            totalWeightOz = DatabaseManager.totalOz(
                lbs: parsed.weightLbs,
                oz: parsed.weightOz
            )
            totalWeightHundredthLb = nil
            totalWeightHundredthKg = nil
            totalLengthQuarters = nil
            totalLengthCm = nil

        case .pounds:
            totalWeightOz = nil
            totalWeightHundredthLb = DatabaseManager.poundsHundredth(
                whole: parsed.weightPounds,
                hundredths: parsed.weightDec
            )
            totalWeightHundredthKg = nil
            totalLengthQuarters = nil
            totalLengthCm = nil

        case .kilograms:
            totalWeightOz = nil
            totalWeightHundredthLb = nil
            totalWeightHundredthKg = DatabaseManager.kgsHundredth(
                whole: parsed.weightKgWhole,
                hundredths: parsed.weightGrams
            )
            totalLengthQuarters = nil
            totalLengthCm = nil

        case .inches:
            totalWeightOz = nil
            totalWeightHundredthLb = nil
            totalWeightHundredthKg = nil
            totalLengthQuarters = DatabaseManager.quartersFromInches(
                whole: parsed.lengthInches,
                quarter: parsed.lengthQuarters
            )
            totalLengthCm = nil

        case .centimeters:
            totalWeightOz = nil
            totalWeightHundredthLb = nil
            totalWeightHundredthKg = nil
            totalLengthQuarters = nil
            totalLengthCm = DatabaseManager.tenthsCm(
                whole: parsed.lengthCm,
                tenth: parsed.lengthTenths
            )
        }

        let item = CatchItem(
            id: 0,
            dateTimeSec: nowSec,
            species: parsed.species,

            totalWeightOz: totalWeightOz,
            totalWeightPoundsHundredth: totalWeightHundredthLb,
            totalWeightHundredthKg: totalWeightHundredthKg,

            totalLengthQuarters: totalLengthQuarters,
            totalLengthCm: totalLengthCm,

            catchType: "Tournament",
            markerType: nil,          // TODO: derive L / S / P later with Initials
            clipColor: parsed.clipColor,

            latitudeE7: nil,
            longitudeE7: nil,

            primaryPhotoId: nil,
            createdAtSec: nowSec
        )
        print("🟩 Inserting CatchItem into DB")
        do {
            try DatabaseManager.shared.insertCatch(item)
            print("✅ Tournament VCC catch saved:", item)
            print("🟩 DB insert SUCCESS")

            speak("Catch saved. Over and out.") {
                self.coordinator.endSession(reason: "catch saved")
            }
        } catch {
            print("❌ DB insert failed:", error.localizedDescription)
            speak("Sorry, I could not save that catch. Over and out.") {
                self.coordinator.endSession(reason: "db error")
            }
        }
    }


    // MARK: - DEBUG🪲 / TESTING ONLY

    func debugInjectTranscript(_ text: String) {
        print("🧪 DEBUG inject transcript:", text)
        handleCatchTranscript(text)
    }

    // MARK: - Current Measurement Mode
    
    private func currentMeasurementMode() -> MeasurementMode {
        // TODO: replace with tournament setup / settings
        return .lbsOz
    }

    
    // MARK: - Retry Logic

    private func retryCatch() {
        retryCount += 1

        guard retryCount <= maxRetries else {
            speak("Too many attempts. Please try again later.") {
                self.coordinator.endSession(reason: "max retries")
            }
            return
        }

        speak("Okay, please say your catch again. Over.") {
            self.listenForCatch()
        }
    }

    private func retryConfirmation() {
        speak("Please say yes, no, or cancel. Over.") {
            self.listenForConfirmation()
        }
    }


    // MARK: - Question Mode (stub)

    private func enterQuestionMode() {
        inQuestionMode = true
        coordinator.transition(to: .questionMode)

        speak("Question mode activated. What would you like to know? Over.") {
            // 🔧 NEXT STEP:
            // Listen and route tournament questions
            self.coordinator.endSession(reason: "question mode stub")
        }
    }

    // MARK: - Speech Helper

    private func speak(_ text: String, completion: @escaping () -> Void) {
        print("🗣️ Speaking: \(text)")
        tts.speak(text) {
            completion()
        }
    }

    private func armFailSafe(reason: String) {
        failSafeWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            guard let self else { return }
            print("⏱️ FAILSAFE fired:", reason)
            self.voiceManager.stopListening()
            self.speak("Sorry, I did not hear over. Please try again. Over and out.") {
                self.coordinator.endSession(reason: "failsafe timeout")
            }
        }
        failSafeWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + listenFailSafeSeconds, execute: item)
    }

    private func cancelFailSafe() {
        failSafeWorkItem?.cancel()
        failSafeWorkItem = nil
    }

    // MARK: - Cleanup

    func shutdown() {
        print("🔻 TournamentVoiceHandler.shutdown()")
        cancelFailSafe()
        retryCount = 0
        inQuestionMode = false
    }
}
