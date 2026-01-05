//
//  VCCPracticeSelectView.swift
//  CatchAndCall
//
//  Phrase selector used by VCCPracticeSessionView
//

import SwiftUI

struct VCCPracticeSelectView: View {

    // MARK: - Input
    let onSelect: (PracticePhrase) -> Void

    // MARK: - Local State
    @State private var phrases: [PracticePhrase] = VoicePhraseList.practicePhrases

    var body: some View {

        List {
            ForEach(phrases) { phrase in
                Button {
                    print("🟢 Practice phrase selected:", phrase.text)
                    onSelect(phrase)
                } label: {
                    HStack {
                        Text(phrase.text)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)

                        Spacer()

                        if phrase.isMastered {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("Select Practice Word / Phrase")
        .listStyle(.plain)
        .background(Color.softlockSand)
        .onAppear {
            print("📺 VCCPracticeSelectView appeared")
        }
    }
}

#Preview {
    NavigationStack {
        VCCPracticeSelectView { _ in }
    }
}
