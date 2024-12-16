//
//  TrackingView.swift
//  FitnessApp
//
//  Created by Almaz Beisenov on 16.12.2024.
//
import SwiftUI
import MapKit

struct TrackingView: View {
    @StateObject private var locationManager = LocationManager()
    @Environment(\.managedObjectContext) private var viewContext

    @State private var region: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var isTracking = false
    @State private var distance: Double = 0.0 // Км
    @State private var timeElapsed: Int = 0   // Секунды
    @State private var showAlert = false
    @State private var timer: Timer? = nil

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Карта с маршрутом
                    Map(
                        coordinateRegion: $region,
                        interactionModes: .all,
                        showsUserLocation: true
                    )
                    .frame(height: 300)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    .onAppear {
                        requestLocationAccess()
                    }
                    .onChange(of: locationManager.lastLocation) { newLocation in
                        updateRegion(with: newLocation)
                    }

                    // Информация о текущей тренировке
                    VStack(spacing: 10) {
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Дистанция")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                Text("\(String(format: "%.2f", distance)) км")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                            }

                            Spacer()

                            VStack(alignment: .leading, spacing: 5) {
                                Text("Время")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                Text(formattedTime())
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                            }
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)

                    // Управление
                    VStack(spacing: 20) {
                        // Кнопка "Начать/Остановить"
                        Button(action: {
                            withAnimation(.spring()) {
                                if isTracking {
                                    stopTracking()
                                } else {
                                    startTracking()
                                }
                            }
                        }) {
                            Text(isTracking ? "Остановить" : "Начать тренировку")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isTracking ? Color.red : Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .shadow(radius: 5)
                        }

                        // Кнопка "Завершить"
                        if !isTracking && distance > 0 {
                            Button(action: saveRun) {
                                Text("Завершить тренировку")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                    .shadow(radius: 5)
                            }
                            .alert(isPresented: $showAlert) {
                                Alert(
                                    title: Text("Успех!"),
                                    message: Text("Тренировка успешно сохранена."),
                                    dismissButton: .default(Text("Ок"))
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.top)
            .navigationTitle("Трекинг")
            .onDisappear {
                stopTracking() // Останавливаем трекинг при уходе с экрана
            }
        }
    }

    // MARK: - Логика трекинга

    private func startTracking() {
        // Запускаем трекинг и сбрасываем данные
        locationManager.startTracking()
        distance = 0.0
        timeElapsed = 0
        isTracking = true

        // Запускаем таймер
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            timeElapsed += 1
            calculateDistance()
        }
    }

    private func stopTracking() {
        locationManager.stopTracking()
        timer?.invalidate()
        timer = nil
        isTracking = false // Останавливаем трекинг
    }

    private func saveRun() {
        // Сохраняем тренировку в Core Data
        let newWorkout = Workout(context: viewContext)
        newWorkout.name = "Бег"
        newWorkout.type = "Кардио"
        newWorkout.distance = distance
        newWorkout.time = Int16(timeElapsed)
        newWorkout.date = Date()

        do {
            try viewContext.save()
            showAlert = true
            resetTracking() // Сбрасываем данные после сохранения
        } catch {
            print("Ошибка сохранения: \(error)")
        }
    }

    private func resetTracking() {
        // Полный сброс данных
        distance = 0.0
        timeElapsed = 0
        isTracking = false
    }

    // MARK: - Обновление карты

    private func updateRegion(with location: CLLocation?) {
        guard let location = location else { return }
        region.center = location.coordinate
    }

    // MARK: - Расчёт дистанции

    private func calculateDistance() {
        guard locationManager.route.count > 1 else { return }
        distance = 0.0
        for index in 1..<locationManager.route.count {
            let previousLocation = locationManager.route[index - 1]
            let currentLocation = locationManager.route[index]
            distance += currentLocation.distance(from: previousLocation)
        }
        distance /= 1000.0 // Преобразование в километры
    }

    // MARK: - Формат времени

    private func formattedTime() -> String {
        let minutes = timeElapsed / 60
        let seconds = timeElapsed % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Запрос доступа к локации

    private func requestLocationAccess() {
        locationManager.requestAuthorization()
    }
}
