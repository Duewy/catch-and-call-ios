//
//  VCCPracticeSessionView.swift
//  CatchAndCall_VCC
//
//  Voice Training Session Screen
//

import SwiftUI

struct VCCPracticeSessionView: View {

    // MARK: - Voice Engine
    @StateObject private var voiceManager = VoiceManager()

    // MARK: - Training State
    @State private var selectedPhrase: PracticePhrase? = nil
    @State private var isEvaluated: Bool = false
    @State private var didPass: Bool = false

    // MARK: - UI State
    @State private var showPhrasePicker: Bool = false

    var body: some View {

        VStack(spacing: 20) {

            // =========================
            // Title
            // =========================
            Text("Voice Training")
                .font(.title)
                .underline()
                .fontWeight(.bold)
            Text("Practice Voice Commands")
                .font(.title)
                .fontWeight(.medium)
            // =========================
            // Select Phrase Button
            // =========================
            Button {
                showPhrasePicker = true
            } label: {
                Text(selectedPhrase == nil
                     ? "Select Practice Word / Phrase"
                     : "Change Practice Word / Phrase")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Color.blue.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)

            // =========================
            // Phrase Display
            // =========================
            if let phrase = selectedPhrase {

                VStack(spacing: 6) {
                    Text("say this phrase:")
                        .font(.headline)

                    HStack(spacing: 6) {
                        Text(phrase.text)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.blue)

                        Text(", over")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.orange)
                    }
                    .multilineTextAlignment(.center)

                    Text("Say “over” when finished so the app knows you are done.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
            } else {
                Text("Select a word or phrase to begin training")
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            // =========================
            // Listening Indicator
            // =========================
            if voiceManager.isListening {
                Text("listening…")
                    .font(.headline)
                    .foregroundColor(.blue)
            }

            // =========================
            // Live Transcription
            // =========================
            if !voiceManager.liveTranscription.isEmpty {
                VStack(spacing: 4) {
                    Text("hearing:")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    Text(voiceManager.liveTranscription)
                        .font(.body)
                        .foregroundColor(.blue)
                        .multilineTextAlignment(.center)
                }
            }

            // =========================
            // Final Result
            // =========================
            if let heard = voiceManager.lastRecognizedText {
                VStack(spacing: 4) {
                    Text("we heard:")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    Text("“\(heard)”")
                        .font(.body)
                        .multilineTextAlignment(.center)
                }
            }

            if isEvaluated {
                Text(didPass ? "✓ GOOD" : "✕ try again")
                    .font(.title2)
                    .foregroundColor(didPass ? .green : .red)
            }

            Spacer()

            // =========================
            // Start Training Button
            // =========================
            Button {
                startTraining()
            } label: {
                Text("Say the Word / Phrase 🎙️")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(
                        selectedPhrase == nil
                        ? Color.gray
                        : Color.green.opacity(0.8)
                    )
                    .foregroundColor(.black)
                    .cornerRadius(12)
            }
            .disabled(selectedPhrase == nil || voiceManager.isListening)
            .padding(.horizontal)

            // =========================
            // Bluetooth Hint
            // =========================
            Text("For best results, practice using your Bluetooth device 🎧")
                .font(.footnote)
                .foregroundColor(.blue)
                .multilineTextAlignment(.center)
                .padding(.bottom, 10)
        }
        .padding()
        .background(Color.softlockSand.ignoresSafeArea())
        .navigationTitle("Practice")
                
        .task {
            await voiceManager.requestPermissions()
        }
        .onAppear {
            print("📺 VCCPracticeSessionView appeared")
        }

        // =========================
        // Phrase Picker Sheet
        // =========================
        .sheet(isPresented: $showPhrasePicker) {
            NavigationStack {
                VCCPracticeSelectView { phrase in
                    print("🟢 Phrase selected:", phrase.text)
                    selectedPhrase = phrase
                    isEvaluated = false
                    didPass = false
                    showPhrasePicker = false
                }
            }
        }
    }

    // MARK: - Training Logic

    private func startTraining() {
        guard let phrase = selectedPhrase else { return }

        isEvaluated = false
        didPass = false

        voiceManager.startTrainingListen { recognizedText in
            evaluate(recognizedText, phrase: phrase)
        }

        print("🟢 Start Training button tapped")
    }

    private func evaluate(_ recognizedText: String, phrase: PracticePhrase) {

        let requiredKeywords = phrase.text
            .lowercased()
            .split(separator: " ")
            .map(String.init)

        let spokenWords = recognizedText
            .lowercased()
            .split(separator: " ")
            .map(String.init)

        let passed = requiredKeywords.allSatisfy { spokenWords.contains($0) }

        didPass = passed
        isEvaluated = true
    }
}

#Preview {
    NavigationStack {
        VCCPracticeSessionView()
    }
}
