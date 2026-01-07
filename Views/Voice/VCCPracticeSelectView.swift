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
    private var phrases: [PracticePhrase] {
        VoicePhraseList.practicePhrases
    }


    var body: some View {
        VStack(spacing: 0) {

            // MARK: - Header
            VStack(spacing: 6) {

                // Centered title block
                VStack(spacing: 2) {
                    Text("Select Practice")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Word / Phrase")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity, alignment: .center)

                // Left-aligned helper text
                Text("  indicator changes from yellow to green\n  upon mastery of speech recognition")
                    .font(.footnote)
                    .fontWeight(.light)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 12)


            // MARK: - Phrase List
            List {
                ForEach(phrases) { phrase in
                    Button {
                        print("🟢 Practice phrase selected:", phrase.text)
                        onSelect(phrase)
                    } label: {
                        HStack {

                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(phrase.progressColor)

                            Text(" ")   // little spacer
                            Text(phrase.text)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 6)
                    }
                    .listRowBackground(Color.softlockSand)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)   // ← VERY IMPORTANT for Lists
        }
        .background(Color.ltBrown.edgesIgnoringSafeArea(.all))         // ← PAGE BACKGROUND
    }//==== END == Body =====
      
}// === END ==== VCC Practice Select =========

#Preview {
    NavigationStack {
        VCCPracticeSelectView { _ in }
    }
}
