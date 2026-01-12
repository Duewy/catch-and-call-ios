//
//  HelpPdfView.swift
//  CatchAndCall
//
//  Created by Dwayne Brame on 2025-11-19.
//
//-->> Tells Apple iOS how to open PDF documents

import Foundation
import SwiftUI
import SafariServices

struct HelpPdfView: View {
    let title: String
    let url: URL

    var body: some View {
        SafariView(url: url)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
    }
}

// UIKit wrapper for SFSafariViewController
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // nothing to update
    }
}
