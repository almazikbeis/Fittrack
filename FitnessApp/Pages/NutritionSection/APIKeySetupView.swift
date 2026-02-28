//
//  APIKeySetupView.swift
//  FitnessApp
//
//  Lets the user save their Anthropic API key for food recognition.
//

import SwiftUI

struct APIKeySetupView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var apiKey = UserDefaults.standard.string(forKey: "anthropic_api_key") ?? ""
    @State private var showKey = false
    @State private var saved   = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 28) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(LinearGradient.nutritionGradient)
                            .frame(width: 80, height: 80)
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 36))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 24)
                    .shadow(color: Color.nutritionPurple.opacity(0.4), radius: 16, x: 0, y: 6)

                    // Title
                    VStack(spacing: 8) {
                        Text("ИИ-сканирование еды")
                            .font(.title2).fontWeight(.bold)
                        Text("Введите Anthropic API ключ для распознавания блюд по фото. Ключ хранится только на вашем устройстве.")
                            .font(.subheadline).foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }

                    // Key field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("API ключ Anthropic")
                            .font(.caption).fontWeight(.medium).foregroundColor(.secondary)

                        HStack {
                            Group {
                                if showKey {
                                    TextField("sk-ant-api03-...", text: $apiKey)
                                } else {
                                    SecureField("sk-ant-api03-...", text: $apiKey)
                                }
                            }
                            .font(.system(.body, design: .monospaced))
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)

                            Button(action: { showKey.toggle() }) {
                                Image(systemName: showKey ? "eye.slash" : "eye")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(14)
                        .background(Color(.systemBackground))
                        .cornerRadius(14)
                        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
                    }
                    .padding(.horizontal, 24)

                    // How to get key
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Как получить API ключ", systemImage: "questionmark.circle")
                            .font(.subheadline).fontWeight(.semibold)
                        VStack(alignment: .leading, spacing: 6) {
                            instructionRow("1", "Зайдите на console.anthropic.com")
                            instructionRow("2", "Создайте аккаунт или войдите")
                            instructionRow("3", "Перейдите в «API Keys»")
                            instructionRow("4", "Нажмите «Create Key» и скопируйте")
                        }
                    }
                    .padding(16)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .padding(.horizontal, 24)

                    // Features list
                    VStack(alignment: .leading, spacing: 10) {
                        featureRow("camera.viewfinder", "Фото → автоматический КБЖУ")
                        featureRow("scalemass.fill",    "Точная оценка размера порции")
                        featureRow("photo.on.rectangle","Сохранение фото в дневнике")
                        featureRow("sparkles",          "Claude claude-sonnet-4-6 Vision")
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 20)
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") { dismiss() }.foregroundColor(.secondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveKey) {
                        Text(saved ? "Сохранено ✓" : "Сохранить")
                            .fontWeight(.semibold)
                            .foregroundColor(apiKey.isEmpty ? Color(.systemGray3) : .primaryGreen)
                    }
                    .disabled(apiKey.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func saveKey() {
        let trimmed = apiKey.trimmingCharacters(in: .whitespaces)
        UserDefaults.standard.set(trimmed, forKey: "anthropic_api_key")
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation { saved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { dismiss() }
    }

    private func instructionRow(_ num: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(num)
                .font(.caption2).fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 18, height: 18)
                .background(Color.nutritionPurple)
                .clipShape(Circle())
            Text(text).font(.caption).foregroundColor(.secondary)
        }
    }

    private func featureRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(.nutritionPurple)
                .frame(width: 22)
            Text(text).font(.subheadline)
        }
    }
}
