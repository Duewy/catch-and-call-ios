/*
//  SpeciesImages.swift
//  CatchAndCall
//
//  Created by Dwayne Brame on 2025-10-27.
//
// Matches the Species Names with Images from the Assest.xcassets file...
 
    UPDATES Must be marked on line above as Last Updated....
    To ensure the Release has the Latest Updated Species Image Listing...
    all UPDATES SpeciesStorage.swift at the same time to ensure Species = Image
 
>>>>>>>  Last UpDated On 19 Nov 2025 DMB ✍🏻  <<<<<<<<<<
 
 */

import SwiftUI
import UIKit

func speciesImageName(for raw: String) -> String {
    // normalize like Android
    let key = SpeciesStorage.normalizeSpeciesName(raw)   // ✅
             // e.g., "Large Mouth" -> "large mouth"
    let slug = key.replacingOccurrences(of: " ", with: "_")
                     .replacingOccurrences(of: "-", with: "_")

    // try dynamic name first (lets you add more species without code changes)
    let candidate = "fish_\(slug)"                    // e.g., "fish_large_mouth"
    if UIImage(named: candidate) != nil { return candidate }

    // explicit aliases/synonyms
    switch key {

        // === Bass (freshwater) ===
        case "largemouth",
             "large mouth",
             "largemouth bass",
             "large mouth bass",
             "lm bass":
            return "fish_large_mouth"

        case "smallmouth",
             "small mouth",
             "smallmouth bass",
             "small mouth bass",
             "sm bass":
            return "fish_small_mouth"

        case "spotted bass",
             "spot bass":
            return "fish_spotted_bass"

        case "striped bass",
             "striper":
            return "fish_striped_bass"

        case "white bass":
            return "fish_white_bass"

        // === Panfish / sunfish / crappie / bluegill / rock bass ===
        case "bluegill":
            return "fish_bluegill"

        case "crappie":
            return "fish_crappie"

        case "perch",
             "yellow perch":
            return "fish_perch"

        case "sunfish":
            return "fish_sunfish"

        case "rock bass":
            return "fish_rock_bass"

        case "panfish":
            return "fish_panfish"

        // === Trout & salmon family ===
        case "rainbow trout":
            return "fish_rainbow_trout"

        case "brown trout":
            return "fish_brown_trout"

        case "speckled trout":
            return "fish_speckled_trout"

        case "lake trout":
            return "fish_lake_trout"

        case "salmon":
            return "fish_salmon"

        // === Pike / muskie / bowfin / gar ===
        case "northern pike",
             "pike":
            return "fish_northern_pike"

        case "muskie",
             "muskellunge":
            return "fish_muskie"

        case "bowfin",
             "bow fin":
            return "fish_bow_fin"

        case "gar":
            return "fish_gar"

        // === Catfish / bullhead / sucker / carp / drum / ling ===
        case "catfish":
            return "fish_catfish"

        case "bullhead",
             "bull head":
            return "fish_bull_head"

        case "sucker":
            return "fish_sucker"

        case "carp":
            return "fish_carp"

        case "drum",
             "freshwater drum":
            return "fish_drum"

        case "ling",
             "burbot":
            return "fish_ling"

        // === Walleye / saucy ===
        case "walleye":
            return "fish_walleye"

        case "saugeye":      // using your exact name; asset: fish_saucy
            return "fish_saugeye"
        
        
        // === SALT WATER FISH 🐠 =========
        case "grouper":
            return "fish_grouper"
        case "red snapper":
            return "fish_red_snapper"
        case "tarpon":
            return "fish_tarpon"

        // === Generic / fallback ===
        // if no image for a species use fish_default
        // User Added Species will have the fish_default as the image

        default:
            return "fish_default"
        
    }

}

func loadUserSpeciesImage(for raw: String) -> UIImage? {
    let key = SpeciesStorage.normalizeSpeciesName(raw)
    let defaultsKey = "userIcon_\(key)"

    guard let filename = UserDefaults.standard.string(forKey: defaultsKey) else {
        return nil
    }

    let baseURL = FileManager.default
        .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("SpeciesIcons", isDirectory: true)

    let fileURL = baseURL.appendingPathComponent(filename)

    return UIImage(contentsOfFile: fileURL.path)
}

//MARK: --- Ensure Images are Sized Properly ----
func resizedSquareImage(_ image: UIImage, size: CGFloat = 96) -> UIImage? {
    let shortestSide = min(image.size.width, image.size.height)

    let cropRect = CGRect(
        x: (image.size.width - shortestSide) / 2,
        y: (image.size.height - shortestSide) / 2,
        width: shortestSide,
        height: shortestSide
    )

    guard let cgImage = image.cgImage?.cropping(to: cropRect) else { return nil }

    let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
    return renderer.image { _ in
        UIImage(cgImage: cgImage)
            .draw(in: CGRect(x: 0, y: 0, width: size, height: size))
    }
}

//MARK: --- Remove the Image File when Deleted ---
func deleteUserSpeciesImage(for raw: String) {
    let key = SpeciesStorage.normalizeSpeciesName(raw)   // ✅
    let defaultsKey = "userIcon_\(key)"

    guard let filename = UserDefaults.standard.string(forKey: defaultsKey) else {
        return
    }

    let baseURL = FileManager.default
        .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("SpeciesIcons", isDirectory: true)

    let fileURL = baseURL.appendingPathComponent(filename)

    try? FileManager.default.removeItem(at: fileURL)
    UserDefaults.standard.removeObject(forKey: defaultsKey)
}

func migrateUserSpeciesImage(from oldRaw: String, to newRaw: String) {
    let oldKey = SpeciesStorage.normalizeSpeciesName(oldRaw)
    let newKey = SpeciesStorage.normalizeSpeciesName(newRaw)

    guard oldKey != newKey else { return }

    let defaults = UserDefaults.standard

    let oldDefaultsKey = "userIcon_\(oldKey)"
    let newDefaultsKey = "userIcon_\(newKey)"

    guard let filename = defaults.string(forKey: oldDefaultsKey) else {
        return // no image to migrate
    }

    let baseURL = FileManager.default
        .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("SpeciesIcons", isDirectory: true)

    let oldURL = baseURL.appendingPathComponent(filename)
    let newFilename = "species_\(newKey).png"
    let newURL = baseURL.appendingPathComponent(newFilename)

    do {
        // Move file if it exists
        if FileManager.default.fileExists(atPath: oldURL.path) {
            try FileManager.default.moveItem(at: oldURL, to: newURL)
        }

        // Update defaults
        defaults.removeObject(forKey: oldDefaultsKey)
        defaults.set(newFilename, forKey: newDefaultsKey)

    } catch {
        print("⚠️ Failed to migrate species image:", error)
    }
}



struct SpeciesIcon: View {
    let species: String
    var size: CGFloat = 26

    var body: some View {
        Group {
            if let userImage = loadUserSpeciesImage(for: species) {
                Image(uiImage: userImage)
                    .resizable()
            } else {
                Image(speciesImageName(for: species))
                    .resizable()
            }
        }
        .scaledToFit()
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .accessibilityLabel(Text(species.lowercased()))
        .accessibilityHint(Text("species icon"))
    }
}



