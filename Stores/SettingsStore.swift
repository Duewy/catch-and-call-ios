import SwiftUI
import Combine

// Persisted keys (match SetUpView)
fileprivate enum SetupKeys {
    static let gpsEnabled         = "gpsEnabled"
    static let voiceEnabled       = "voiceEnabled"
    static let tournamentLimit    = "tournamentLimit"   // 4 or 5
    static let tournamentSpecies  = "tournamentSpecies" // normalized name
    static let weightMode         = "weightMode"        // "lbs_oz" | "decimal_lbs" | "kgs"
    static let lengthMode         = "lengthMode"        // "inches" | "centimeters"
    static let measureMode        = "measureMode"       // "", "lbs_oz","decimal_lbs","kgs","inches","centimeters"
    static let dayType            = "dayType"           // "", "fun","tournament"
}

final class SettingsStore: ObservableObject {
    // Global flags
    
    // --- GPS and VCC Set Up -----
    @Published var gpsEnabled: Bool
    @Published var voiceControlEnabled: Bool

    // --  Modes — strings to stay 1:1 with Android names you already use
    @Published var weightMode: String        // "lbs_oz","decimal_lbs","kgs"
    @Published var lengthMode: String        // "inches","centimeters"
    @Published var measureMode: String       // "",..., as above (empty = nothing selected)
    @Published var dayType: String           // "","fun","tournament"

    // ---  Tournament Settings -------
    @Published var tournamentLimit: Int         // 4 or 5
    @Published var tournamentSpecies: String    // normalized (default "largemouth")

    private let d = UserDefaults.standard
    private var bag = Set<AnyCancellable>()

    init() {
        //---- Load from Defaults with Sensible Fallbacks --------
        gpsEnabled          = d.object(forKey: SetupKeys.gpsEnabled)        as? Bool ?? false
        voiceControlEnabled = d.object(forKey: SetupKeys.voiceEnabled)      as? Bool ?? false
        tournamentLimit     = d.object(forKey: SetupKeys.tournamentLimit)   as? Int  ?? 5
        tournamentSpecies   = d.string(forKey: SetupKeys.tournamentSpecies) ?? "largemouth"
        weightMode          = d.string(forKey: SetupKeys.weightMode)        ?? "decimal_lbs"
        lengthMode          = d.string(forKey: SetupKeys.lengthMode)        ?? "inches"
        measureMode         = d.string(forKey: SetupKeys.measureMode)       ?? ""   // <- empty = white pills
        dayType             = d.string(forKey: SetupKeys.dayType)           ?? ""   // <- empty = white pills


       // ----- Persist on change -----
       $gpsEnabled.dropFirst().sink { [weak self] v in self?.d.set(v, forKey: SetupKeys.gpsEnabled) }.store(in: &bag)
       $voiceControlEnabled.dropFirst().sink { [weak self] v in self?.d.set(v, forKey: SetupKeys.voiceEnabled) }.store(in: &bag)
       $tournamentLimit.dropFirst().sink { [weak self] v in self?.d.set(v, forKey: SetupKeys.tournamentLimit) }.store(in: &bag)
       $tournamentSpecies.dropFirst().sink { [weak self] v in self?.d.set(v, forKey: SetupKeys.tournamentSpecies) }.store(in: &bag)
       $weightMode.dropFirst().sink { [weak self] v in self?.d.set(v, forKey: SetupKeys.weightMode) }.store(in: &bag)
       $lengthMode.dropFirst().sink { [weak self] v in self?.d.set(v, forKey: SetupKeys.lengthMode) }.store(in: &bag)
       $measureMode.dropFirst().sink { [weak self] v in self?.d.set(v, forKey: SetupKeys.measureMode) }.store(in: &bag)
       $dayType.dropFirst().sink { [weak self] v in self?.d.set(v, forKey: SetupKeys.dayType) }.store(in: &bag)
   }

   func clearSelectionForNewSession() {
       measureMode = ""
       dayType = ""
   }
}
