//
//  AllSpeciesSelectionView.swift
//  CatchAndCall
//
//  Species Catalog Manager
//  - Displays all built-in + user-added species
//  - Allows adding new species
//  - Allows edit/delete of USER-ADDED species only
//

import SwiftUI
import Foundation

// MARK: - Simple Alert

private struct SimpleAlert: Identifiable {
    let id = UUID()
    let message: String
}

// MARK: - Row Model

private struct SpeciesRow: Identifiable, Hashable {
    let id = UUID()
    var name: String
}

// MARK: - View

struct UserSpeciesCatalogView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var rows: [SpeciesRow] = []

    // Add Species
    @State private var isShowingAddSheet = false
    @State private var newSpeciesName = ""
    
    // Image Upload
    @State private var selectedImage: UIImage? = nil
    @State private var isShowingImagePicker = false
    
    // Delete User Entry
    @State private var speciesPendingDelete: SpeciesRow? = nil
    @State private var showDeleteConfirm = false
         
    // Edit Species
    @State private var editingRow: SpeciesRow? = nil

    // Alerts
    @State private var alertMessage: SimpleAlert? = nil

    // MARK: - Body

    var body: some View {
            
            VStack(spacing: 0) {
                header
                subheader
                
                List {
                    ForEach($rows) { $row in
                        speciesRow(row)
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.ltBrown)
                
                footerButtons
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
            }
            .background(Color.softlockSand.ignoresSafeArea())
            .preferredColorScheme(.light)
            .onAppear(perform: loadFromStorage)
        
            .alert("Delete Species?",
                   isPresented: $showDeleteConfirm,
                   presenting: speciesPendingDelete) { row in

                Button("Delete", role: .destructive) {
                    deleteSpecies(row)
                    speciesPendingDelete = nil
                }

                Button("Cancel", role: .cancel) {
                    speciesPendingDelete = nil
                }

            } message: { row in
                Text("Are you sure you want to delete “\(row.name)”? This will also remove its icon.")
            }

        
            .alert(item: $alertMessage) { msg in
                Alert(
                    title: Text("Notice"),
                    message: Text(msg.message),
                    dismissButton: .default(Text("OK"))
                )
            }
            .sheet(isPresented: $isShowingAddSheet) {
                addSpeciesSheet
            }
            .sheet(item: $editingRow) { row in
                EditSpeciesSheet(
                    initialName: row.name,
                    onSave: { newName in
                        applyEdit(row: row, newName: newName)
                        editingRow = nil
                    },
                    onDelete: {
                        deleteSpecies(row)
                        editingRow = nil
                    },
                    onCancel: {
                        editingRow = nil
                    }
                )
                .padding(.top, 24)
                .padding(.horizontal, 16)
            }
    }

    // MARK: - Header

    private var header: some View {
        Text("Species Catalog")
            .font(.system(size: 30, weight: .bold))
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
    }
    // MARK: - Sub-Header

    private var subheader: some View {
        Text("Add or Delete the User_Added Species")
            .font(.system(size: 20, weight: .light))
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
    }
    // MARK: - Row View

    private func speciesRow(_ row: SpeciesRow) -> some View {
        let norm = SpeciesStorage.normalizeSpeciesName(row.name)
        let isUserAdded = !SpeciesStorage.builtInSpecies.contains(norm)

        return HStack(spacing: 12) {
            SpeciesIcon(species: row.name, size: 50)
                .padding(.trailing, 12)
            Text(row.name.lowercased())
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.black)

            if isUserAdded {

                Button {
                    speciesPendingDelete = row
                    showDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("delete species"))
                .accessibilityHint(Text("removes species and its image"))
            }
        }
        .padding(.vertical, 3)
        .padding(.trailing, 40)
        .background(Color.veryLiteGrey.opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Footer Buttons

    private var footerButtons: some View {
        VStack(spacing: 10) {
            
            Button {
                newSpeciesName = ""
                isShowingAddSheet = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Species To List")
                }
                .font(.system(size: 22, weight: .bold))
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.black, lineWidth: 2)
                )
            }
            
            Button {
                dismiss()
            } label: {
                Text("Cancel")
                    .font(.system(size: 22, weight: .bold))
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(Color.gray.opacity(0.55))
                    .foregroundColor(.black)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black, lineWidth: 2)
                    )
            }

        }
    }

    // MARK: - Load

    private func loadFromStorage() {
        let all = SpeciesStorage.loadAllSpecies()
        rows = all.map { SpeciesRow(name: $0) }
    }

    // MARK: - Add Species

    private var addSpeciesSheet: some View {
        
        ZStack {
            Color.green
                .ignoresSafeArea()
            
            NavigationStack {
                VStack(spacing: 16) {
                    Text("Add Custom Species")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.black)
                    
                    // IMAGE PREVIEW
                    ZStack {
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.black, lineWidth: 2)
                                )
                        } else {
                            Image("fish_default")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .opacity(0.6)
                        }
                    }

                    Button("Select Image") {
                        isShowingImagePicker = true
                    }
                    .font(.system(size: 22, weight: .bold))
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(Color.golden.opacity(0.90))
                    .foregroundColor(.black)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black, lineWidth: 2)
                    )

                    .sheet(isPresented: $isShowingImagePicker) {
                        ImagePicker(image: $selectedImage)
                    }

                    TextField("Enter species name", text: $newSpeciesName)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.black)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .padding(.horizontal, 16)
                    
                    HStack(spacing: 12) {
                        Button("Cancel") {
                            isShowingAddSheet = false
                        }
                        .font(.system(size: 22, weight: .bold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Color.gray.opacity(0.75))
                        .foregroundColor(.black)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black, lineWidth: 2)
                        )
                        
                        Button("Add") {
                            handleAddSpecies()
                        }
                        .font(.system(size: 22, weight: .bold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black, lineWidth: 2)
                        )
                    }
                    .padding(.horizontal, 16)
                    
                    Text("Not all species are on the list so this is where you can add that missing species to the list.📝 \nIf you need to change the entry just select the Delete Icon and then re-add the species and the image.")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.top, 24)
                        .padding(.horizontal, 16)
                }
                .padding(.top, 24)
                .padding(.horizontal, 16)
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(Color.green, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
            }
        }
    }

    
    // MARK: --- Loading All Species Images  ---
    
    private func handleAddSpecies() {
        let norm = SpeciesStorage.normalizeSpeciesName(newSpeciesName)

        guard !norm.isEmpty else {
            alertMessage = SimpleAlert(message: "Please enter a species name.")
            return
        }

        if rows.contains(where: { SpeciesStorage.normalizeSpeciesName($0.name) == norm }) {
            alertMessage = SimpleAlert(message: "Species already exists.")
            return
        }

        SpeciesStorage.addUserSpecies(norm)

        if let image = selectedImage,
           let resized = resizedSquareImage(image),
           let filename = saveSpeciesImage(resized, for: norm) {

            UserDefaults.standard.set(filename, forKey: "userIcon_\(norm)")
        }

        selectedImage = nil
        newSpeciesName = ""

        loadFromStorage()
        isShowingAddSheet = false
    }


    // MARK: --- Saving Image from User ---
    
    private func saveSpeciesImage(_ image: UIImage, for species: String) -> String? {
        let filename = "species_\(SpeciesStorage.normalizeSpeciesName(species)).png"

        guard let data = image.pngData() else { return nil }

        let url = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("SpeciesIcons", isDirectory: true)

        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)

        let fileURL = url.appendingPathComponent(filename)

        do {
            try data.write(to: fileURL)
            return filename
        } catch {
            print("Failed to save image:", error)
            return nil
        }
    }

    // MARK: --- Edit / Delete ---

    //------------- Apply Edit -----------------------
    private func applyEdit(row: SpeciesRow, newName: String) {
        let oldNorm = SpeciesStorage.normalizeSpeciesName(row.name)
        let newNorm = SpeciesStorage.normalizeSpeciesName(newName)

        guard !newNorm.isEmpty else {
            alertMessage = SimpleAlert(message: "Species name cannot be empty.")
            return
        }

        if rows.contains(where: {
            $0.id != row.id &&
            SpeciesStorage.normalizeSpeciesName($0.name) == newNorm
        }) {
            alertMessage = SimpleAlert(message: "Species already exists.")
            return
        }

        // 🔁 Migrate image BEFORE changing storage
        migrateUserSpeciesImage(from: oldNorm, to: newNorm)

        // Update user-added species list
        var userAdded = SpeciesStorage.loadUserAddedSpecies()
        userAdded.removeAll { SpeciesStorage.normalizeSpeciesName($0) == oldNorm }
        userAdded.append(newNorm)
        SpeciesStorage.saveUserAddedSpecies(userAdded)

        loadFromStorage()
    }

    //------- Delete Species ---------------------
    private func deleteSpecies(_ row: SpeciesRow) {
        let norm = SpeciesStorage.normalizeSpeciesName(row.name)

        guard !SpeciesStorage.builtInSpecies.contains(norm) else {
            alertMessage = SimpleAlert(message: "Built-in species can’t be deleted.")
            return
        }

        // 🔴 Delete the user image file
        deleteUserSpeciesImage(for: row.name)

        // 🟢 Delete species from storage (user-added + ordered list)
        SpeciesStorage.deleteUserSpecies(row.name)

        loadFromStorage()
    }


}//=== END === AllSpeciesSelectionView ===

// MARK: - Edit Sheet

private struct EditSpeciesSheet: View {
    @State var text: String
    let onSave: (String) -> Void
    let onDelete: () -> Void
    let onCancel: () -> Void

    init(
        initialName: String,
        onSave: @escaping (String) -> Void,
        onDelete: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        _text = State(initialValue: initialName)
        self.onSave = onSave
        self.onDelete = onDelete
        self.onCancel = onCancel
    }

    var body: some View {
        ZStack {
            Color.golden
                .ignoresSafeArea()
            
            NavigationStack {
                VStack(spacing: 16) {
                    Text("Edit Species")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.black)

                    TextField("Species name", text: $text)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                    
                    HStack(spacing: 12) {
                        Button("Cancel", action: onCancel)
                            .font(.system(size: 22, weight: .bold))
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(Color.gray.opacity(0.75))
                            .foregroundColor(.black)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.black, lineWidth: 2)
                            )
                        
                        Button("Delete", action: onDelete)
                            .font(.system(size: 22, weight: .bold))
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.black, lineWidth: 2)
                            )
                        
                        Button("Save") {
                            onSave(text)
                        }
                        .font(.system(size: 22, weight: .bold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Color.green)
                        .foregroundColor(.black)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black, lineWidth: 2)
                        )
                    }
                    Text("The Species Name can be Change/Edited but the Icon-Image can not be changed. \nTo have a different Icon-Image for your Species, Delete the Entry and re-Add the Species and the Icon-Image.\nThis avoids loading up your cellphone memory.")
                        .font(.system(size: 18))
                        .foregroundColor(.black)
                }
                .padding(.top, 24)
                .padding(.horizontal, 16)
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(Color.golden, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        UserSpeciesCatalogView()
    }
}
