//
//  VoicePhraseList.swift
//  CatchAndCall
//
//  Created by Dwayne Brame on 2026-01-02.
//

import Foundation
enum VoicePhraseList {

    static var practicePhrases: [PracticePhrase] = [

        // 🎣 Core Catch Commands
        PracticePhrase(text: "Add a catch"),
        PracticePhrase(text: "Save the catch"),
        PracticePhrase(text: "Record catch"),
        PracticePhrase(text: "Log catch"),
        PracticePhrase(text: "Delete last catch"),
        PracticePhrase(text: "Edit last catch"),

        // 🧠 Question Mode
        PracticePhrase(text: "Question"),
        PracticePhrase(text: "What is the total weight"),
        PracticePhrase(text: "What is the total length"),
        PracticePhrase(text: "Smallest catch"),
        PracticePhrase(text: "Largest catch"),
        PracticePhrase(text: "Time since last catch"),
        PracticePhrase(text: "Time remaining"),

        // 🐟 Species Examples
        PracticePhrase(text: "Largemouth"),
        PracticePhrase(text: "Smallmouth"),
        PracticePhrase(text: "Crappie"),
        PracticePhrase(text: "Walleye"),
        PracticePhrase(text: "Perch"),
        PracticePhrase(text: "Catfish"),
        PracticePhrase(text: "Pike"),
        PracticePhrase(text: "Sunfish"),
        PracticePhrase(text: "Rock Bass"),
        PracticePhrase(text: "White Bass"),
        PracticePhrase(text: "Spotted Bass"),
        PracticePhrase(text: "Gar Pike"),
        PracticePhrase(text: "Bowfin"),
        PracticePhrase(text: "Bullhead"),
        PracticePhrase(text: "Red Drum"),
        PracticePhrase(text: "Muskie"),
        PracticePhrase(text: "Carp")
    ]
    

    static let supportedCommands: Set<String> = [
        "add a catch",
        "save the catch",
        "record catch",
        "log catch",
        "edit last catch",
        "delete last catch",
        "question",
        "smallest catch",
        "largest catch",
        "time remaining"
    ]

    
}
