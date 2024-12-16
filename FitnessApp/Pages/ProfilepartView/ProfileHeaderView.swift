//
//  ProfileHeaderView.swift
//  FitnessApp
//
//  Created by Almaz Beisenov on 16.12.2024.
//
import SwiftUI

struct ProfileHeaderView: View {
    let userName: String
    let userAge: Int

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(.green)
                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 5)

            Text(userName)
                .font(.title)
                .bold()

            Text("\(userAge) лет")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal)
    }
}
