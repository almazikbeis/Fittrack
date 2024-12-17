//
//  FriendsSectionView.swift
//  FitnessApp
//
//  Created by Almaz Beisenov on 17.12.2024.
//

import Foundation
import SwiftUI
struct FriendsSectionView: View {
    let friends: [Friend]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Друзья")
                .font(.title3)
                .fontWeight(.bold)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(friends) { friend in
                        VStack {
                            Image(systemName: friend.isOnline ? "person.circle.fill" : "person.circle")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(friend.isOnline ? .green : .gray)
                            Text(friend.name)
                                .font(.caption)
                        }
                        .frame(width: 70, height: 100)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}
