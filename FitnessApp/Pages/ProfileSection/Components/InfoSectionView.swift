//
//  InfoSectionView.swift
//  FitnessApp
//
//  Created by Almaz Beisenov on 17.12.2024.
//

import Foundation
import SwiftUI
struct InfoSectionView: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
                .foregroundColor(.gray)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.2))
        .cornerRadius(12)
    }
}
