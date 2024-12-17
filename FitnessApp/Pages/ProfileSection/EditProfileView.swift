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
        NavigationView {
            VStack(spacing: 20) {
                // Заголовок
                Text("Редактирование профиля")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                    .padding(.top, 20)

                // Карточка с полями редактирования
                VStack(spacing: 15) {
                    // Имя пользователя
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Имя")
                            .font(.headline)
                            .foregroundColor(.gray)
                        TextField("Введите имя", text: $userName)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
                    }

                    // Возраст
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Возраст")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Stepper(value: $userAge, in: 10...100) {
                            Text("\(userAge) лет")
                                .font(.body)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
                    }

                    // Вес
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Вес")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Stepper(value: $userWeight, in: 30...200, step: 0.5) {
                            Text("\(userWeight, specifier: "%.1f") кг")
                                .font(.body)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
                    }

                    // Рост
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Рост")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Stepper(value: $userHeight, in: 100...250, step: 0.5) {
                            Text("\(userHeight, specifier: "%.1f") см")
                                .font(.body)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)

                Spacer()

                // Кнопка "Сохранить"
                Button(action: {
                    presentationMode.wrappedValue.dismiss() // Закрыть окно
                }) {
                    Text("Сохранить")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 5)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.white, Color.green.opacity(0.1)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
            )
        }
    }
}
