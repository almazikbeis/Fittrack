//
//  AddFoodView.swift
//  FitnessApp
//

import SwiftUI
import CoreData

// MARK: - Food Database Item

struct FoodDatabaseItem: Identifiable {
    let id = UUID()
    let name:             String
    let emoji:            String
    let caloriesPer100g:  Double
    let proteinPer100g:   Double
    let fatPer100g:       Double
    let carbsPer100g:     Double
}

let foodDatabase: [FoodDatabaseItem] = [
    FoodDatabaseItem(name: "Куриная грудка",  emoji: "🍗",  caloriesPer100g: 165, proteinPer100g: 31.0, fatPer100g: 3.6,  carbsPer100g: 0.0),
    FoodDatabaseItem(name: "Яйцо",            emoji: "🥚",  caloriesPer100g: 155, proteinPer100g: 13.0, fatPer100g: 11.0, carbsPer100g: 1.1),
    FoodDatabaseItem(name: "Овсянка",         emoji: "🥣",  caloriesPer100g: 389, proteinPer100g: 17.0, fatPer100g: 7.0,  carbsPer100g: 66.0),
    FoodDatabaseItem(name: "Рис варёный",     emoji: "🍚",  caloriesPer100g: 130, proteinPer100g: 2.7,  fatPer100g: 0.3,  carbsPer100g: 28.0),
    FoodDatabaseItem(name: "Гречка варёная",  emoji: "🌾",  caloriesPer100g: 92,  proteinPer100g: 3.4,  fatPer100g: 0.6,  carbsPer100g: 20.0),
    FoodDatabaseItem(name: "Творог 5%",       emoji: "🧀",  caloriesPer100g: 121, proteinPer100g: 17.0, fatPer100g: 5.0,  carbsPer100g: 1.8),
    FoodDatabaseItem(name: "Молоко 2.5%",     emoji: "🥛",  caloriesPer100g: 54,  proteinPer100g: 2.8,  fatPer100g: 2.5,  carbsPer100g: 4.7),
    FoodDatabaseItem(name: "Банан",           emoji: "🍌",  caloriesPer100g: 89,  proteinPer100g: 1.1,  fatPer100g: 0.3,  carbsPer100g: 23.0),
    FoodDatabaseItem(name: "Яблоко",          emoji: "🍎",  caloriesPer100g: 52,  proteinPer100g: 0.3,  fatPer100g: 0.2,  carbsPer100g: 14.0),
    FoodDatabaseItem(name: "Хлеб цельный",    emoji: "🍞",  caloriesPer100g: 247, proteinPer100g: 9.2,  fatPer100g: 2.9,  carbsPer100g: 46.0),
    FoodDatabaseItem(name: "Макароны",        emoji: "🍝",  caloriesPer100g: 371, proteinPer100g: 13.0, fatPer100g: 1.5,  carbsPer100g: 75.0),
    FoodDatabaseItem(name: "Картофель",       emoji: "🥔",  caloriesPer100g: 77,  proteinPer100g: 2.0,  fatPer100g: 0.1,  carbsPer100g: 17.0),
    FoodDatabaseItem(name: "Греч. йогурт",    emoji: "🍶",  caloriesPer100g: 97,  proteinPer100g: 10.0, fatPer100g: 5.0,  carbsPer100g: 3.6),
    FoodDatabaseItem(name: "Лосось",          emoji: "🐟",  caloriesPer100g: 208, proteinPer100g: 20.0, fatPer100g: 13.0, carbsPer100g: 0.0),
    FoodDatabaseItem(name: "Говядина",        emoji: "🥩",  caloriesPer100g: 187, proteinPer100g: 26.0, fatPer100g: 10.0, carbsPer100g: 0.0),
    FoodDatabaseItem(name: "Протеин (порошок)", emoji: "💪", caloriesPer100g: 390, proteinPer100g: 75.0, fatPer100g: 5.0,  carbsPer100g: 15.0),
    FoodDatabaseItem(name: "Орехи",           emoji: "🥜",  caloriesPer100g: 620, proteinPer100g: 20.0, fatPer100g: 52.0, carbsPer100g: 18.0),
    FoodDatabaseItem(name: "Авокадо",         emoji: "🥑",  caloriesPer100g: 160, proteinPer100g: 2.0,  fatPer100g: 15.0, carbsPer100g: 9.0),
    FoodDatabaseItem(name: "Тунец (конс.)",   emoji: "🐠",  caloriesPer100g: 116, proteinPer100g: 26.0, fatPer100g: 1.0,  carbsPer100g: 0.0),
    FoodDatabaseItem(name: "Сыр",             emoji: "🧀",  caloriesPer100g: 380, proteinPer100g: 23.0, fatPer100g: 31.0, carbsPer100g: 0.0),
]

// MARK: - AddFoodView

struct AddFoodView: View {
    let mealType: String
    let date:     Date

    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var searchText     = ""
    @State private var selectedFood: FoodDatabaseItem? = nil
    @State private var weightGrams    = 100
    @State private var useCustom      = false

    // Custom entry
    @State private var customName      = ""
    @State private var customCalories  = ""
    @State private var customProtein   = ""
    @State private var customFat       = ""
    @State private var customCarbs     = ""

    private var meal: MealType { MealType(rawValue: mealType) ?? .breakfast }

    private var filteredFoods: [FoodDatabaseItem] {
        searchText.isEmpty
            ? foodDatabase
            : foodDatabase.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    // Computed macros
    private var computedCalories: Double { (selectedFood?.caloriesPer100g ?? 0) * Double(weightGrams) / 100 }
    private var computedProtein:  Double { (selectedFood?.proteinPer100g  ?? 0) * Double(weightGrams) / 100 }
    private var computedFat:      Double { (selectedFood?.fatPer100g      ?? 0) * Double(weightGrams) / 100 }
    private var computedCarbs:    Double { (selectedFood?.carbsPer100g    ?? 0) * Double(weightGrams) / 100 }

    private var canAdd: Bool {
        useCustom ? (!customName.isEmpty && !customCalories.isEmpty) : selectedFood != nil
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Meal header
                mealHeader

                // Mode picker
                Picker("", selection: $useCustom) {
                    Text("Из базы").tag(false)
                    Text("Своё").tag(true)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

                if useCustom {
                    customEntryForm
                } else {
                    databaseForm
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") { dismiss() }
                        .foregroundColor(.secondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Добавить") { addFood() }
                        .fontWeight(.semibold)
                        .foregroundColor(canAdd ? .primaryGreen : Color(.systemGray3))
                        .disabled(!canAdd)
                }
            }
        }
    }

    // MARK: - Meal Header

    private var mealHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(meal.gradient)
                    .frame(width: 40, height: 40)
                Image(systemName: meal.icon)
                    .font(.system(size: 17))
                    .foregroundColor(.white)
            }
            Text(mealType)
                .font(.headline)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Database Form

    private var databaseForm: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Search bar
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Поиск продукта...", text: $searchText)
                }
                .padding(12)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .padding(.horizontal, 20)

                // Foods grid
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 10
                ) {
                    ForEach(filteredFoods) { food in
                        foodCell(food)
                    }
                }
                .padding(.horizontal, 20)

                // Selected food detail
                if let food = selectedFood {
                    selectedFoodDetail(food)
                        .padding(.horizontal, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Spacer().frame(height: 40)
            }
            .padding(.top, 8)
        }
    }

    private func foodCell(_ food: FoodDatabaseItem) -> some View {
        let isSelected = selectedFood?.id == food.id
        return Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedFood = isSelected ? nil : food
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }) {
            VStack(spacing: 4) {
                Text(food.emoji)
                    .font(.title2)
                Text(food.name)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .foregroundColor(isSelected ? .white : .primary)
                Text("\(Int(food.caloriesPer100g)) ккал")
                    .font(.system(size: 9))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 80)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected
                          ? AnyShapeStyle(LinearGradient.primaryGradient)
                          : AnyShapeStyle(Color(.systemBackground)))
            )
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func selectedFoodDetail(_ food: FoodDatabaseItem) -> some View {
        VStack(spacing: 14) {
            Divider()

            // Weight stepper
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(food.name + " " + food.emoji)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("на 100 г: \(Int(food.caloriesPer100g)) ккал")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
                HStack(spacing: 10) {
                    Button(action: { if weightGrams > 10 { weightGrams -= 10 } }) {
                        Image(systemName: "minus")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(width: 32, height: 32)
                            .background(Color(.systemGray5))
                            .clipShape(Circle())
                    }
                    .buttonStyle(ScaleButtonStyle())

                    Text("\(weightGrams) г")
                        .font(.headline)
                        .fontWeight(.bold)
                        .frame(minWidth: 56)
                        .multilineTextAlignment(.center)

                    Button(action: { if weightGrams < 2000 { weightGrams += 10 } }) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(width: 32, height: 32)
                            .background(Color.primaryGreen.opacity(0.15))
                            .clipShape(Circle())
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }

            // Macros preview
            HStack(spacing: 0) {
                macroBlock(label: "Калории", value: String(format: "%.0f", computedCalories), unit: "ккал", color: .primaryGreen)
                Divider().frame(height: 32).opacity(0.35)
                macroBlock(label: "Белки",   value: String(format: "%.1f", computedProtein),  unit: "г",    color: .nutritionPurple)
                Divider().frame(height: 32).opacity(0.35)
                macroBlock(label: "Жиры",    value: String(format: "%.1f", computedFat),       unit: "г",    color: .cardioOrange)
                Divider().frame(height: 32).opacity(0.35)
                macroBlock(label: "Углев.",  value: String(format: "%.1f", computedCarbs),     unit: "г",    color: .nutritionBlue)
            }
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        }
    }

    private func macroBlock(label: String, value: String, unit: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(unit)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Custom Form

    private var customEntryForm: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                customField(label: "Название", placeholder: "Например: Протеиновый бар", text: $customName)
                customField(label: "Калории (ккал)", placeholder: "0", text: $customCalories, keyboard: .decimalPad)

                HStack(spacing: 10) {
                    customField(label: "Белки (г)", placeholder: "0", text: $customProtein, keyboard: .decimalPad)
                    customField(label: "Жиры (г)",  placeholder: "0", text: $customFat,     keyboard: .decimalPad)
                    customField(label: "Углев. (г)", placeholder: "0", text: $customCarbs,  keyboard: .decimalPad)
                }

                Spacer().frame(height: 40)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
    }

    private func customField(label: String, placeholder: String,
                             text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .padding(12)
                .background(Color(.systemBackground))
                .cornerRadius(12)
        }
    }

    // MARK: - Save

    private func addFood() {
        let entry      = FoodEntry(context: viewContext)
        entry.id       = UUID()
        entry.date     = date
        entry.mealType = mealType

        if useCustom {
            entry.name     = customName
            entry.calories = Double(customCalories) ?? 0
            entry.protein  = Double(customProtein)  ?? 0
            entry.fat      = Double(customFat)      ?? 0
            entry.carbs    = Double(customCarbs)    ?? 0
            entry.weight   = 100
        } else if let food = selectedFood {
            entry.name     = food.name
            entry.calories = computedCalories
            entry.protein  = computedProtein
            entry.fat      = computedFat
            entry.carbs    = computedCarbs
            entry.weight   = Double(weightGrams)
        }

        try? viewContext.save()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        dismiss()
    }
}
