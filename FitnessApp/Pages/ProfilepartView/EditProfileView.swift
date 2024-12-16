//
//  EditProfileView.swift
//  FitnessApp
//
//  Created by Almaz Beisenov on 15.12.2024.
//


import SwiftUI

struct EditProfileView: View {
    @AppStorage("userName") private var userName: String = "Имя пользователя"
    @AppStorage("userAge") private var userAge: Int = 25
    @AppStorage("userWeight") private var userWeight: Double = 70.0
    @AppStorage("userHeight") private var userHeight: Double = 175.0

    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        Form {
            Section(header: Text("Основная информация")) {
                TextField("Имя", text: $userName)
                
                Stepper(value: $userAge, in: 10...100) {
                    Text("Возраст: \(userAge) лет")
                }
                
                Stepper(value: $userWeight, in: 30...200, step: 0.5) {
                    Text("Вес: \(userWeight, specifier: "%.1f") кг")
                }
                
                Stepper(value: $userHeight, in: 100...250, step: 0.5) {
                    Text("Рост: \(userHeight, specifier: "%.1f") см")
                }
            }

            Button("Сохранить") {
                presentationMode.wrappedValue.dismiss()
            }
        }
        .navigationTitle("Редактировать профиль")
    }
}
