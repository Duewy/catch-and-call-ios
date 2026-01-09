import SwiftUI

// Persisted keys (compatible with your earlier names)
fileprivate enum SetupKeys {
    static let gpsEnabled         = "gpsEnabled"
    static let voiceEnabled       = "voiceEnabled"
    static let tournamentLimit    = "tournamentLimit"   // 4 or 5
    static let tournamentSpecies  = "tournamentSpecies" // normalized name
    static let weightMode         = "weightMode"        // "lbs_oz" | "decimal_lbs" | "kgs"
    static let lengthMode         = "lengthMode"        // "inches" | "centimeters"
    static let measureMode        = "measureMode"   // "", "lbs_oz","decimal_lbs","kgs","inches","centimeters"
    static let dayType            = "dayType"       // "", "fun","tournament"
    }

struct SetUpView: View {
    // Shared store (already created in Utils/SettingsStore.swift)
    @EnvironmentObject var settings: SettingsStore

    // Local UI state (persist via AppStorage so it survives restarts)
    @AppStorage(SetupKeys.gpsEnabled)
    private var gpsEnabled = false
    @AppStorage(SetupKeys.voiceEnabled)
    private var voiceEnabled = false
    @AppStorage(SetupKeys.tournamentLimit)
    private var tournamentLimit = 5
    @AppStorage(SetupKeys.tournamentSpecies) 
    private var tournamentSpecies: String = ""
    
    // --- Active species list (from SpeciesUtils / UserDefaults) ---
    @State private var speciesList: [String] = []

    @AppStorage("hasResetStartup")
    private var hasResetStartup = false
    
    @State private var measureMode: String = ""
    // "", "lbs_oz","decimal_lbs","kgs","inches","centimeters"
    @State private var dayType: String = ""
    // "", "fun", "tournament"


    // Day type -- Tournament default
    @State private var isTournamentSelected = true
    @State private var isFunDaySelected = false
        
    // TOAST PopUp
    @State private var toastText: String = ""
    @State private var showToast: Bool = false
    
    @State private var suppressVoiceToggle = false

    
    private func pushToast(_ msg: String, hideAfter seconds: Double = 2.0) {
        toastText = msg
        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
             showToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            withAnimation(.easeInOut(duration: 0.25)) { showToast = false }
        }
    }
    
    // MARK: - Edition Detection
    private var appEdition: String {
        Bundle.main.object(forInfoDictionaryKey: "APP_EDITION") as? String ?? "tracker"
    }

    private var ImageName: String {
        switch appEdition {
        case "free":
            return "Image_Catch_And_Call_Free"
        case "tracker":
            return "Image_Catch_And_Call_Tracker"
        case "pro_vcc":
            return "Image_Catch_And_Call_Pro_VCC"
        default:
            return "Image_Catch_And_Call_Tracker"
        }
    }


//-------------------------------------------------------------------------
    
    var body: some View {
        
        
        ScrollView {
            VStack(spacing: 8) {
                
                // Header
                VStack(spacing: 6) {
                    Image(ImageName).resizable().scaledToFit().padding(.horizontal,50)
                    Text("Set Up").font(.title.bold())//TODO: make the text larger.. Scale with page.
                }
                .padding(.top, 1)
                
                // Measurements header
                Text("Measurements")
                    .font(.title2.bold())
                    .underline()
                
                // Row 1: 3 weight choices
                HStack(spacing: 8) {
                    Button {
                        measureMode = "lbs_oz"
                        settings.measureMode = "lbs_oz"
                        settings.weightMode  = "lbs_oz"
                    } label: {
                        Text("Lbs/Ozs").font(.headline).foregroundStyle(.black)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(measureBG("lbs_oz"))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 2))
                            .cornerRadius(12)
                    }
                    
                    Button {
                        measureMode = "decimal_lbs"
                        settings.measureMode = "decimal_lbs"
                        settings.weightMode  = "decimal_lbs"
                    } label: {
                        Text("Pounds").font(.headline).foregroundStyle(.black)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(measureBG("decimal_lbs"))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 2))
                            .cornerRadius(12)
                    }
                    
                    Button {
                        measureMode = "kgs"
                        settings.measureMode = "kgs"
                        settings.weightMode  = "kgs"
                    } label: {
                        Text("Kgs").font(.headline).foregroundStyle(.black)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(measureBG("kgs"))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 2))
                            .cornerRadius(12)
                    }
                }
                
                // Row 2: 2 length choices
                HStack(spacing: 8) {
                    Button {
                        measureMode = "inches"
                        settings.measureMode = "inches"
                        settings.lengthMode  = "inches"
                    } label: {
                        Text("Inches").font(.headline).foregroundStyle(.black)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(measureBG("inches"))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 2))
                            .cornerRadius(12)
                    }
                    
                    Button {
                        measureMode = "centimeters"
                        settings.measureMode = "centimeters"
                        settings.lengthMode  = "centimeters"
                    } label: {
                        Text("Centimeters").font(.headline).foregroundStyle(.black)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(measureBG("centimeters"))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 2))
                            .cornerRadius(12)
                    }
                }
                
                Text("Type of Fishing Day")
                    .font(.title2.bold())
                    .underline()
                
                HStack(spacing: 8) {
                    Button {
                        dayType = "fun"
                        settings.dayType = "fun"
                        isFunDaySelected = true
                        isTournamentSelected = false
                    } label: {
                        Text("Fun Day").font(.headline).foregroundStyle(.black)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(dayTypeBG("fun"))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 2))
                            .cornerRadius(12)
                    }
                    
                    Button {
                        dayType = "tournament"
                        settings.dayType = "tournament"
                        isFunDaySelected = false
                        isTournamentSelected = true
                    } label: {
                        Text("Tournament").font(.headline).foregroundStyle(.black)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(dayTypeBG("tournament"))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 2))
                            .cornerRadius(12)
                    }
                }
                
                Divider().padding(.vertical, 1)
                
                // Culling Limit + Tournament Species (enabled whenever Tournament is selected)
               // let tourActive = (dayType == "tournament")
                
                
                
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Culling Limit").font(.subheadline.bold())
                        Button {
                            guard tourActive else { return }
                            tournamentLimit = (tournamentLimit == 5 ? 4 : 5)
                        } label: {
                            Text("\(tournamentLimit)")
                                .font(.title2.bold())
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(dayType == "tournament" ? Color.white : Color.gray.opacity(0.25))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(.black, lineWidth: 2))
                                .cornerRadius(10)
                        }
                        .disabled(!tourActive)
                        
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Tournament Species").font(.subheadline.bold())
                        //--- Tournament Species Spinner ----
                        if !speciesList.isEmpty {
                            Picker("Tournament Species", selection: $tournamentSpecies) {
                                ForEach(speciesList, id: \.self) { sp in
                                    Text(sp.capitalized).tag(sp)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .padding(.horizontal, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(tourActive ? Color.white : Color.gray.opacity(0.25))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.black.opacity(0.6), lineWidth: 2)
                                    )
                            )
                            .disabled(!tourActive)
                        } else {
                            Text("Loading species…")
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .foregroundColor(.gray)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.gray.opacity(0.15))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.black.opacity(0.3), lineWidth: 1)
                                        )
                                )
                        }

                    }
                }
                
                Divider().padding(.vertical, 1)
                
                // GPS / Voice (disabled for now—visible but off)
                HStack(spacing: 30) {
                    Text("Log Catch Location").font(.subheadline.bold())
                    Text("Voice Control").font(.subheadline.bold())
                }
                HStack(spacing: 30) {
                    //--- GPS Button  -----
                    pillToggle(title: gpsEnabled ? "GPS Enabled" : "GPS Disabled",
                               isOn: $gpsEnabled, enabled: true)
                    .onChange(of: gpsEnabled) { newValue in
                        settings.gpsEnabled = newValue            // <-- keep store in sync
                        if newValue {
                            LocationService.shared.ensurePermission()
                            pushToast("  GPS Enabled 🛰️ \n Catches will record your location.")
                        } else {
                            pushToast("  GPS Disabled🚫 \n Catches will not record location.")
                        }
                    }
                    
                    // --- VC Button -------
                    pillToggle(title: voiceEnabled ? "VC Enabled" : "VC Disabled",
                               isOn: $voiceEnabled, enabled: true)
                    .onChange(of: voiceEnabled) { newValue in
                        // 🚫 Ignore programmatic resets
                        if suppressVoiceToggle {
                            suppressVoiceToggle = false
                            return
                        }

                        if newValue {
                            BluetoothValidation.hasValidBluetoothMic { hasMic in
                                if hasMic {
                                    settings.voiceControlEnabled = true
                                    pushToast("Voice Control Enabled 🎤\nBluetooth device ready.")
                                } else {
                                    suppressVoiceToggle = true
                                    voiceEnabled = false
                                    settings.voiceControlEnabled = false
                                    pushToast("No Bluetooth Device detected 🚫\nPlease connect a headset.")
                                }
                            }

                        } else {
                            settings.voiceControlEnabled = false
                            pushToast("Voice Control Disabled 🚫\nManual Mode only.")
                        }
                    }

                }
                
                Divider().padding(.vertical, 1)
                
                               
                // ==== Start Fishing Event Button (goes to correct screen based on choices) ====
                NavigationLink {
                    catchEntryDestination()
                } label: {
                    Text("Start Fishing Event")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(Color.blue.opacity(0.85))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 2))
                        .cornerRadius(12)
                }
                .disabled(!canStart)
                .opacity(canStart ? 1 : 0.5)
                .simultaneousGesture(TapGesture().onEnded {
                    settings.tournamentLimit   = tournamentLimit
                    settings.tournamentSpecies = tournamentSpecies
                    // keep store in sync (UI pills still reset to white via your onAppear)
                    settings.measureMode = measureMode.isEmpty ? settings.measureMode : measureMode
                    settings.dayType     = dayType.isEmpty     ? settings.dayType     : dayType
                    armVoiceControlIfNeeded()   // Starts the Voice Control Code
                })
                
                
                // ==== MAIN MENU + SPECIES BUTTONS (centered) ====
                HStack(spacing: 12) {
                    // --- Main Page Button ---
                    NavigationLink {
                        MainMenuView()
                    } label: {
                        Text("Main Page")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.black)
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.clipBrightGreen)
                            )
                            .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                    
                    // --- Customize Species List Button ---
                    NavigationLink {
                        UserSortingSpeciesListView()
                    } label: {
                        Text("Customize Species List")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.black)
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.ltBrown)
                            )
                            .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Spacer(minLength: 12)
            
                .padding(.horizontal, 12)
                .padding(.bottom, 24)
            
                .onAppear { // --- REFRESH Data Everytime Opened ----
                    print("🔄 Setting Up View - onAppear")
                    resetSelectionsForFreshOpen()
                    speciesList = SpeciesStorage.loadOrderedSpeciesList()
                    // 🔒 Ensure tournamentSpecies is valid
                    if !speciesList.contains(tournamentSpecies) {
                        tournamentSpecies = speciesList.first ?? ""
                    }            }
        }
        .background(Color.halo_light_blue.opacity(0.55)) // whole page
        
        .overlay(alignment: .bottom) {
            if showToast {
                ToastBanner(text: toastText)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 20)
            }
        }
        .animation(.default, value: showToast)
    
    }//===== End === SetUp View =========

    // MARK: - Small helpers

    private var tourActive: Bool {
        dayType == "tournament"
    }
    
    private var canStart: Bool {
        guard !measureMode.isEmpty, !dayType.isEmpty else { return false }
        if dayType == "tournament" {
            return !tournamentSpecies.isEmpty
        }
        return true
    }

    
    private func resetSelectionsForFreshOpen() {
        // Measurement pills
        measureMode = ""               // -> all five measurement buttons white
        // Day-type pills
        dayType = ""                   // -> both Fun Day / Tournament white
        isFunDaySelected = false
        isTournamentSelected = false
    }

    
    private func selectPill(_ title: String,
                            isOn: Bool,
                            selectedBg: Color,
                            unselectedBg: Color,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(isOn ? selectedBg : unselectedBg)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 2))
                .cornerRadius(12)
        }
    }

    // === Toggle for GPS and VCC Buttons ======
    private func pillToggle(title: String,
                            isOn: Binding<Bool>,
                            enabled: Bool) -> some View {
        Button {
            if enabled {
                isOn.wrappedValue.toggle()
            }
        } label: {
            Text(title)
                .font(.headline)
                .foregroundStyle(.black)
                .frame(minWidth: 120, minHeight: 44)
                .background(
                    enabled
                    ? (isOn.wrappedValue ? Color.red : Color.logBrown)
                    : Color.gray.opacity(0.35)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.black, lineWidth: 2)
                )
                .cornerRadius(10)
        }
        .disabled(!enabled)
    }

    //=== Changes the Backgound of Measurement Buttons with Selection =======
    private func measureBG(_ tag: String) -> Color {
        // If nothing selected yet, keep them clipVeryGreen; else selected -> clipOrange, others -> veryLiteGrey
        if measureMode.isEmpty { return .clipVeryGreen }
        return measureMode == tag ? Color.clipOrange : Color.veryLiteGrey
    }

    private func dayTypeBG(_ tag: String) -> Color {
    // start with softlockSand, selected is golden other veryLiteGrey
        if dayType.isEmpty { return .softlockSand }
        return dayType == tag ? Color.golden : Color.veryLiteGrey
    }
    
    // Picks the correct Catch Entry screen based on measureMode + dayType
    @ViewBuilder
    private func catchEntryDestination() -> some View {
        if dayType == "fun" {
            switch measureMode {
            case "lbs_oz":
                CatchEntryLbsOzView()
            case "decimal_lbs":
                CatchEntryPoundsView()
            case "kgs":
                CatchEntryKgsView()
            case "inches":
                CatchEntryInchesView()
            case "centimeters":
                CatchEntryCentimetersView()
            default:
                CatchEntryLbsOzView()
            }
        } else {  // Tournament Catch Entry Pages
            switch measureMode {
            case "lbs_oz":
                CatchEntryTournamentLbsView()
            case "decimal_lbs":
                CatchEntryTournamentPoundsView()
            case "kgs":
                CatchEntryTournamentKgsView()
            case "inches":
                CatchEntryTournamentInchesView()
            case "centimeters":
                CatchEntryTournamentCentimetersView()
            default:
                CatchEntryTournamentLbsView()
            }
        }
    }
    
    private func armVoiceControlIfNeeded() {

        // VC only arms if the user explicitly enabled it
        guard settings.voiceControlEnabled else { return }

        // VC only arms for active CatchEntry flows
        if settings.dayType == "tournament",
           settings.measureMode == "lbs_oz" {
            print("VC: Arming for Tournament lbs_oz")
            VoiceSessionManager.shared.armVoiceControl()
            VoiceControlManager.shared.start(
                mode: .tournament,
                measurement: .lbsOzs
            )
        }

        if settings.dayType == "fun",
           settings.measureMode == "lbs_oz" {

            VoiceControlManager.shared.start(
                mode: .funDay,
                measurement: .lbsOzs
            )
        }

        // You’ll expand this later for other measurement modes
    }




}//==== END === SetUpView  ===========

#Preview {
    NavigationStack {
        SetUpView()
    }
    .environmentObject(SettingsStore())
}
