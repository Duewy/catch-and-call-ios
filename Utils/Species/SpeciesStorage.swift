//  SpeciesStorage.swift
//  CatchAndCall
//
//  iOS equivalent of Android's SharedPreferencesManager
//  for species lists (master + selected 8).
/*
 // Matches the Species Names with Images from the Assest.xcassets file...
  
     UPDATES Must be marked on line above as Last Updated....
     To ensure the Release has the Latest Updated Species Image Listing...
     Must UPDATE SpeciesStorage.swift at the same time to ensure Species = Image
 // =============================================================
 // MARK: - CANONICAL SPECIES LIST
 // =============================================================
 //
 // activeSpeciesList is the SINGLE source of truth for:
 // - Species spinners
 // - Tournament entry
 // - Map filtering
 // - Sorting / priority order
 //
 // Do NOT introduce parallel species lists.
 // Android & iOS depend on this unified list.
 
 >>>>>>>  Last UpDated On 02Jan2026 DMB ✍🏻  <<<<<<<<<<
  
  */
import Foundation

struct SpeciesStorage {
    
    // MARK: - UserDefaults keys
    
    private static let keyOrderedSpeciesList = "orderedSpeciesList"// LEGACY — use activeSpeciesList naming going forward
    private static let keyActiveSpeciesList = "activeSpeciesList"
    static func loadActiveSpeciesList() -> [String] {loadOrderedSpeciesList()}
    private static let keyUserAddedSpecies   = "userAddedSpecies"
    
    // MARK: - ONE normalizer (use everywhere)
    nonisolated static func normalizeSpeciesName(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }
    
    // MARK: - FULL MASTER LIST (built-in, non-editable)
    private static let fullDefaultSpeciesList: [String] = [
        "bluegill",
        "bow fin",
        "brown trout",
        "bull head",
        "carp",
        "catfish",
        "crappie",
        "drum",
        "gar",
        "lake trout",
        "large mouth",
        "ling",
        "muskie",
        "northern pike",
        "panfish",
        "perch",
        "rainbow trout",
        "rock bass",
        "salmon",
        "saugeye",
        "small mouth",
        "speckled trout",
        "spotted bass",
        "striped bass",
        "sucker",
        "sunfish",
        "walleye",
        "white bass",
        "grouper",
        "red snapper",
        "tarpon"
    ]
    
    // Built-in set (for delete rules, etc.)
    static let builtInSpecies: Set<String> = Set(fullDefaultSpeciesList.map(normalizeSpeciesName))
    
    // MARK: - User-added species (persistent)
    static func loadUserAddedSpecies() -> [String] {
        (UserDefaults.standard.stringArray(forKey: keyUserAddedSpecies) ?? [])
            .map(normalizeSpeciesName)
            .filter { !$0.isEmpty }
    }
    
    static func saveUserAddedSpecies(_ list: [String]) {
        let cleaned = list
            .map(normalizeSpeciesName)
            .filter { !$0.isEmpty && !builtInSpecies.contains($0) }
        UserDefaults.standard.set(cleaned, forKey: keyUserAddedSpecies)
    }
    
    static func addUserSpecies(_ rawName: String) {
        let norm = normalizeSpeciesName(rawName)
        guard !norm.isEmpty, !builtInSpecies.contains(norm) else { return }
        
        var user = loadUserAddedSpecies()
        guard !user.contains(norm) else { return }
        user.append(norm)
        saveUserAddedSpecies(user)
        
        // Also ensure it appears in ordered list (append to end if missing)
        var ordered = loadOrderedSpeciesList()
        if !ordered.contains(norm) {
            ordered.append(norm)
            saveOrderedSpeciesList(ordered)
        }
    }
    
    static func deleteUserSpecies(_ rawName: String) {
        let norm = normalizeSpeciesName(rawName)
        guard !builtInSpecies.contains(norm) else { return }
        
        var user = loadUserAddedSpecies()
        user.removeAll { $0 == norm }
        saveUserAddedSpecies(user)
        
        var ordered = loadOrderedSpeciesList()
        ordered.removeAll { $0 == norm }
        saveOrderedSpeciesList(ordered)
    }
    
    // MARK: - Combined list (built-in + user-added, deduped)
    static func loadAllSpecies() -> [String] {
        let combined = fullDefaultSpeciesList + loadUserAddedSpecies()
        
        var seen = Set<String>()
        return combined
            .map(normalizeSpeciesName)
            .filter { !$0.isEmpty && seen.insert($0).inserted }
    }
    
    // MARK: - Ordered list used by ALL spinners/popups/map query
    static func loadOrderedSpeciesList() -> [String] {
        let all = loadAllSpecies()
        
        let saved = (UserDefaults.standard.stringArray(forKey: keyOrderedSpeciesList) ?? [])
            .map(normalizeSpeciesName)
            .filter { !$0.isEmpty }
        
        var ordered: [String] = []
        
        // 1) saved order, but only if species still exists
        for s in saved where all.contains(s) {
            ordered.append(s)
        }
        
        // 2) append any new species not yet in saved order
        for s in all where !ordered.contains(s) {
            ordered.append(s)
        }
        
        // 3) persist the reconciled list so everything stays consistent
        UserDefaults.standard.set(ordered, forKey: keyOrderedSpeciesList)
        
        return ordered
    }
    
    static func saveOrderedSpeciesList(_ list: [String]) {
        let all = loadAllSpecies()
        let cleaned = list
            .map(normalizeSpeciesName)
            .filter { !$0.isEmpty && all.contains($0) }
        
        // Dedup while preserving order
        var seen = Set<String>()
        let unique = cleaned.filter { seen.insert($0).inserted }
        
        UserDefaults.standard.set(unique, forKey: keyOrderedSpeciesList)
    }
    
    
}
