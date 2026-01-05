//
//  ToastBanner.swift
//  CatchAndCall
//
//  Created by Dwayne Brame on 2025-11-12.
//

import Foundation
import SwiftUI

struct ToastBanner: View {
    let text: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill")
            Text(text)
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.leading)
                .lineLimit(3)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .foregroundStyle(.white)
        .background(.black.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.35), radius: 8, y: 4)
        .padding(.horizontal, 16)
    }
}

