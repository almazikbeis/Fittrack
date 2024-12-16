//
//  InfoCardView.swift
//  FitnessApp
//
//  Created by Almaz Beisenov on 16.12.2024.
//

import Foundation
import SwiftUI
struct InfoCardView: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.title2)
                    .bold()
            }
            Spacer()
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(10)
        .shadow(color: color.opacity(0.3), radius: 5, x: 0, y: 5)
    }
}
