//  UserSortingSpeciesListView.swift
//  CatchAndCall
//
//  Lets the user reorder their selected
//  to match their fishing priorities.
//
//  Reads from:  SpeciesStorage.loadSelectedSpecies()
//  Writes to:   SpeciesStorage.saveSelectedSpecies(_:)


import Foundation
import SwiftUI

struct UserSortingSpeciesListView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    // The active "quick list" species, in order
    @State private var species: [String] = []

    @State private var draggingSpecies: String? = nil

    // Toast state
    @State private var toastText: String = ""
    @State private var showToast: Bool = false
    
    // Save Order Change
    @State private var originalSpecies: [String] = []
    @State private var showDiscardAlert = false

    
    var body: some View {
        VStack(spacing: 0) {
            header
            
            // Reorderable list
            List {
                ForEach(species, id: \.self) { name in
                    row(for: name, isDragging: draggingSpecies == name)
                        .listRowBackground(
                            draggingSpecies == name
                            ? Color.yellow.opacity(0.95)
                            : Color.ltBrown.opacity(0.55)
                        )
                }
                
                .onMove { source, destination in
                    if draggingSpecies == nil,
                       let first = source.first {
                        draggingSpecies = species[first]
                    }
                    
                    species.move(fromOffsets: source, toOffset: destination)
                    
                    // Clear highlight shortly after drop settles
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        draggingSpecies = nil
                    }
                }
            }
            .environment(\.editMode, .constant(.active))
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.softlockSand)
            
            footerButtons
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
        }
        .background(Color.softlockSand.ignoresSafeArea())
        .preferredColorScheme(.light)
        .onAppear(perform: load)
        .overlay(alignment: .bottom) {
            if showToast {
                ToastBanner(text: toastText)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 20)
            }
        }
        .animation(.default, value: showToast)
        .confirmationDialog(
            "Unsaved Changes",
            isPresented: $showDiscardAlert,
            titleVisibility: .visible
        ) {
            Button("Save Changes") {
                saveAndDismiss()
            }
            
            Button("Discard Changes", role: .destructive) {
                dismiss()
            }
            
            Button("Keep Editing", role: .cancel) {
                // Do nothing
            }
        } message: {
            Text("You’ve changed the order of your species list. What would you like to do?")
        }
        .interactiveDismissDisabled(hasUnsavedChanges)
        
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    if hasUnsavedChanges {
                        showDiscardAlert = true
                    } else {
                        dismiss()
                    }
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }
            }
        }
        
    }
    
    
    // MARK: - Header
    
    private var header: some View {
        VStack(spacing: 4) {
            Text("Organize the Species List")
                .font(.system(size: 26, weight: .bold))
            Text("Drag to set your priority order")
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(.black)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
    }
    
    // MARK: - Row
    
    private func row(for name: String, isDragging: Bool) -> some View {

        HStack(spacing: 12) {
            // Drag handle icon (visual cue)
            Image(systemName: "arrow.up.arrow.down")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.brown)
            
            SpeciesIcon(species: name, size: 50)
            
            Text(name.lowercased())
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.black)
            
            Spacer()
        }
        .padding(.vertical, 2)
        .background(Color.veryLiteGrey.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(name.lowercased()) species"))
        .accessibilityHint(Text("drag to reorder priority"))
    }
    
    
    // MARK: - Footer Buttons
    
    private var footerButtons: some View {
        VStack(spacing: 8) {
            
            // Row 1: Cancel + Save Order
            HStack(spacing: 12) {
                Button {
                    if hasUnsavedChanges {
                        showDiscardAlert = true
                    } else {
                        dismiss()
                    }
                } label: {
                    Text("Cancel")
                        .font(.system(size: 18, weight: .bold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Color.gray.opacity(0.25))
                        .foregroundColor(.black)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black, lineWidth: 2)
                        )
                        .buttonStyle(.plain)
                }
                
                Button {
                    saveAndDismiss()
                } label: {
                    Text("Save Order")
                        .font(.system(size: 18, weight: .bold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Color.clipBrightGreen)
                        .foregroundColor(.black)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black, lineWidth: 2)
                        )
                        .buttonStyle(.plain)
                }
            }
            
            // Row 2: Alter Species List + Reset Species List
            HStack(spacing: 12) {
                // Go to full list to change which 8 are selected
                NavigationLink {
                    UserSpeciesCatalogView()
                } label: {
                    Text("Add/Edit Species")
                        .font(.system(size: 18, weight: .bold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.black, lineWidth: 2)
                        )
                        .buttonStyle(.plain)
                }
            }
        }
    }
    
    
    // MARK: - Logic
    
    private func load() {
        let loaded = SpeciesStorage.loadOrderedSpeciesList()
        species = loaded
        originalSpecies = loaded
    }

    private var hasUnsavedChanges: Bool {
        species != originalSpecies
    }


    private func saveAndDismiss() {
        draggingSpecies = nil
        SpeciesStorage.saveOrderedSpeciesList(species)
        dismiss()
    }


    private func move(from source: IndexSet, to destination: Int) {
        species.move(fromOffsets: source, toOffset: destination)
    }
    
  
    private func pushToast(_ msg: String, hideAfter seconds: Double = 2.0) {
        toastText = msg
        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
            showToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            withAnimation(.easeInOut(duration: 0.25)) {
                showToast = false
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        UserSortingSpeciesListView()
    }
}
