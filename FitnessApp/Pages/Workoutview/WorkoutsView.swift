//
//  WorkoutsView.swift
//  FitnessApp
//
//  Created by Almaz Beisenov on 15.12.2024.
//
import SwiftUI
import CoreData

struct WorkoutsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: Workout.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Workout.date, ascending: true)]
    ) private var workouts: FetchedResults<Workout>


    @State private var selectedDate = Date()
    @State private var showAddWorkout = false
    @State private var editingWorkout: Workout?

    var body: some View {
        NavigationView {
            VStack(alignment: .center, spacing: 10) {
                // Календарь недели
                WeekCalendarView(selectedDate: $selectedDate)
                    .padding(.top, 10)

                // Список тренировок
                if workoutsForSelectedDate.isEmpty {
                    Spacer(minLength: 30) // Добавляем отступ сверху
                    Text("Нет упражнений на этот день")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Spacer() // Это не даст контенту центрироваться
                } else {
                    List {
                        ForEach(workoutsForSelectedDate, id: \.self) { workout in
                            WorkoutCardView(workout: workout, toggleCompletion: {
                                withAnimation {
                                    workout.completed.toggle()
                                    saveContext()
                                }
                            })
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteWorkout(workout)
                                } label: {
                                    Label("Удалить", systemImage: "trash")
                                }
                                Button {
                                    editingWorkout = workout
                                } label: {
                                    Label("Редактировать", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }

                Spacer() // Пустое пространство, чтобы кнопка была снизу

                // Плавающая кнопка добавления
                Button(action: {
                    showAddWorkout.toggle()
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 24))
                        .frame(width: 60, height: 60)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 5)
                }
                .padding(.bottom, 20)
            }
            .frame(maxWidth: .infinity, alignment: .top) // Выравниваем элементы вверх
            

            .sheet(isPresented: $showAddWorkout) {
                AddWorkoutView(selectedDate: selectedDate)
                    .environment(\.managedObjectContext, viewContext)
            }
            .sheet(item: $editingWorkout) { workout in
                EditWorkoutView(workout: workout)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }

    private var workoutsForSelectedDate: [Workout] {
        workouts.filter { Calendar.current.isDate($0.date ?? Date(), inSameDayAs: selectedDate) }
    }

    private func deleteWorkout(_ workout: Workout) {
        withAnimation {
            viewContext.delete(workout)
            saveContext()
        }
    }

    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Ошибка сохранения: \(error)")
        }
    }
}

