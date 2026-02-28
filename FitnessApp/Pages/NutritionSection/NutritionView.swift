//
//  NutritionView.swift
//  FitnessApp
//

import SwiftUI
import CoreData

// MARK: - Meal Type

enum MealType: String, CaseIterable, Identifiable {
    case breakfast = "Завтрак"
    case lunch     = "Обед"
    case dinner    = "Ужин"
    case snack     = "Перекус"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .breakfast: return "sun.max.fill"
        case .lunch:     return "sun.min.fill"
        case .dinner:    return "moon.fill"
        case .snack:     return "leaf.fill"
        }
    }
    var color: Color {
        switch self {
        case .breakfast: return .cardioOrange
        case .lunch:     return .primaryGreen
        case .dinner:    return .strengthPurple
        case .snack:     return .nutritionBlue
        }
    }
    var gradient: LinearGradient {
        switch self {
        case .breakfast: return .cardioGradient
        case .lunch:     return .primaryGradient
        case .dinner:    return .strengthGradient
        case .snack:     return .snackGradient
        }
    }
}

// MARK: - NutritionView

struct NutritionView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        entity: FoodEntry.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \FoodEntry.date, ascending: false)]
    ) private var allEntries: FetchedResults<FoodEntry>

    @State private var selectedDate   = Date()
    @State private var addingMeal: MealType?     = nil   // manual add
    @State private var scanningMeal: MealType?   = nil   // AI scanner
    @State private var waterGlasses               = 0
    @State private var expandedMeals: Set<String> = Set(MealType.allCases.map(\.rawValue))
    @State private var animateRing                = false

    // Daily goals
    let caloriesGoal: Double = 2000
    let proteinGoal:  Double = 150
    let fatGoal:      Double = 65
    let carbsGoal:    Double = 250
    let waterGoal              = 8

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    headerSection
                    caloriesRingCard
                    macroProgressCard
                    waterTrackerCard
                    ForEach(MealType.allCases) { meal in
                        mealSectionCard(meal)
                    }
                    Spacer().frame(height: 110)
                }
                .padding(.horizontal)
            }
        }
        .onAppear {
            loadWater()
            withAnimation(.spring(response: 0.9, dampingFraction: 0.75).delay(0.2)) {
                animateRing = true
            }
        }
        .onChange(of: selectedDate) {
            loadWater(); animateRing = false
            withAnimation(.spring(response: 0.9, dampingFraction: 0.75).delay(0.1)) {
                animateRing = true
            }
        }
        // Manual add sheet
        .sheet(item: $addingMeal) { meal in
            AddFoodView(mealType: meal.rawValue, date: selectedDate)
                .environment(\.managedObjectContext, viewContext)
        }
        // AI scanner full-screen
        .fullScreenCover(item: $scanningMeal) { meal in
            FoodScannerView(mealType: meal.rawValue) { result, image, grams in
                saveScanResult(result: result, image: image, grams: grams, meal: meal)
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Питание")
                    .font(.largeTitle).fontWeight(.bold)
                Text(headerDateText)
                    .font(.subheadline).foregroundColor(.secondary)
            }
            Spacer()
            // Scan button
            Button(action: { scanningMeal = .breakfast }) {
                HStack(spacing: 5) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Скан")
                        .font(.caption).fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(LinearGradient.nutritionGradient)
                .cornerRadius(20)
                .shadow(color: Color.nutritionPurple.opacity(0.35), radius: 8, x: 0, y: 3)
            }
            .buttonStyle(ScaleButtonStyle())

            // Day navigation
            HStack(spacing: 6) {
                navArrow("chevron.left")  { changeDay(-1) }
                navArrow("chevron.right",
                         disabled: Calendar.current.isDateInToday(selectedDate)) { changeDay(+1) }
            }
        }
        .padding(.top, 60)
    }

    private func navArrow(_ icon: String, disabled: Bool = false,
                          action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(disabled ? Color(.systemGray4) : .primary)
                .frame(width: 32, height: 32)
                .background(Color(.systemBackground)).clipShape(Circle())
                .shadow(color: .black.opacity(0.07), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(ScaleButtonStyle()).disabled(disabled)
    }

    // MARK: - Calories Ring Card

    private var caloriesRingCard: some View {
        HStack(spacing: 24) {
            ZStack {
                Circle().stroke(Color.primaryGreen.opacity(0.12), lineWidth: 14)
                Circle()
                    .trim(from: 0,
                          to: animateRing ? CGFloat(min(totalCalories / caloriesGoal, 1.0)) : 0)
                    .stroke(
                        AngularGradient(
                            colors: [.primaryGreen, Color(red: 0.05, green: 0.55, blue: 0.90), .primaryGreen],
                            center: .center),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 1.0, dampingFraction: 0.8), value: animateRing)

                VStack(spacing: 2) {
                    Text("\(Int(totalCalories))")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                    Text("из \(Int(caloriesGoal))")
                        .font(.caption2).foregroundColor(.secondary)
                    Text("ккал")
                        .font(.caption).foregroundColor(.primaryGreen).fontWeight(.semibold)
                }
            }
            .frame(width: 128, height: 128)

            VStack(alignment: .leading, spacing: 12) {
                nutrientRow(.nutritionPurple, "Белки",  "\(Int(totalProtein))", "/ \(Int(proteinGoal)) г")
                nutrientRow(.cardioOrange,    "Жиры",   "\(Int(totalFat))",     "/ \(Int(fatGoal)) г")
                nutrientRow(.nutritionBlue,   "Углев.", "\(Int(totalCarbs))",   "/ \(Int(carbsGoal)) г")
                let rem = max(caloriesGoal - totalCalories, 0)
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(Int(rem)) ккал").font(.subheadline).fontWeight(.bold)
                        .foregroundColor(rem > 0 ? .primary : .red)
                    Text("осталось").font(.caption2).foregroundColor(.secondary)
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground)).cornerRadius(24)
        .shadow(color: .black.opacity(0.07), radius: 12, x: 0, y: 4)
    }

    private func nutrientRow(_ color: Color, _ label: String,
                              _ value: String, _ goal: String) -> some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 3).fill(color).frame(width: 4, height: 28)
            VStack(alignment: .leading, spacing: 1) {
                Text(label).font(.caption2).foregroundColor(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value).font(.subheadline).fontWeight(.bold)
                    Text(goal).font(.caption2).foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Macro Progress Card

    private var macroProgressCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Макронутриенты").font(.headline)
            macroBar("Белки",    totalProtein, proteinGoal, .nutritionPurple)
            macroBar("Жиры",     totalFat,     fatGoal,     .cardioOrange)
            macroBar("Углеводы", totalCarbs,   carbsGoal,   .nutritionBlue)
        }
        .padding(18)
        .background(Color(.systemBackground)).cornerRadius(22)
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    private func macroBar(_ label: String, _ cur: Double,
                           _ goal: Double, _ color: Color) -> some View {
        VStack(spacing: 6) {
            HStack {
                Text(label).font(.subheadline).fontWeight(.medium)
                Spacer()
                Text("\(Int(cur)) / \(Int(goal)) г").font(.caption).foregroundColor(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6).fill(color.opacity(0.12)).frame(height: 8)
                    RoundedRectangle(cornerRadius: 6).fill(color)
                        .frame(width: animateRing
                               ? geo.size.width * CGFloat(min(cur / max(goal, 1), 1))
                               : 0, height: 8)
                        .animation(.spring(response: 1, dampingFraction: 0.8).delay(0.25),
                                   value: animateRing)
                }
            }.frame(height: 8)
        }
    }

    // MARK: - Water Tracker

    private var waterTrackerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "drop.fill").foregroundColor(.waterBlue)
                    Text("Вода").font(.headline)
                }
                Spacer()
                Text("\(waterGlasses) / \(waterGoal) стаканов")
                    .font(.caption).foregroundColor(.secondary)
            }
            HStack(spacing: 8) {
                ForEach(0..<waterGoal, id: \.self) { i in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            waterGlasses = waterGlasses == i + 1 ? i : i + 1
                        }
                        saveWater()
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }) {
                        Image(systemName: i < waterGlasses ? "drop.fill" : "drop")
                            .font(.system(size: 20))
                            .foregroundColor(i < waterGlasses ? .waterBlue : Color(.systemGray4))
                            .scaleEffect(i < waterGlasses ? 1.1 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6),
                                       value: waterGlasses)
                    }
                    .buttonStyle(ScaleButtonStyle()).frame(maxWidth: .infinity)
                }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.waterBlue.opacity(0.12)).frame(height: 6)
                    RoundedRectangle(cornerRadius: 6).fill(LinearGradient.waterGradient)
                        .frame(width: geo.size.width * CGFloat(waterGlasses) / CGFloat(waterGoal),
                               height: 6)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: waterGlasses)
                }
            }.frame(height: 6)
        }
        .padding(18)
        .background(Color(.systemBackground)).cornerRadius(22)
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    // MARK: - Meal Section Card

    private func mealSectionCard(_ meal: MealType) -> some View {
        let items      = entries(for: meal)
        let mealCals   = items.reduce(0.0) { $0 + $1.calories }
        let isExpanded = expandedMeals.contains(meal.rawValue)

        return VStack(spacing: 0) {
            // Header
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    if isExpanded { expandedMeals.remove(meal.rawValue) }
                    else          { expandedMeals.insert(meal.rawValue) }
                }
            }) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12).fill(meal.gradient)
                            .frame(width: 44, height: 44)
                        Image(systemName: meal.icon)
                            .font(.system(size: 18)).foregroundColor(.white)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(meal.rawValue).font(.subheadline).fontWeight(.semibold)
                        Text(items.isEmpty ? "Добавить продукты"
                             : "\(items.count) \(productWord(items.count))")
                            .font(.caption2).foregroundColor(.secondary)
                    }
                    Spacer()
                    if mealCals > 0 {
                        Text("\(Int(mealCals)) ккал")
                            .font(.subheadline).fontWeight(.semibold)
                            .foregroundColor(meal.color)
                    }
                    // AI scan button (always visible)
                    Button(action: { scanningMeal = meal }) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 30, height: 30)
                            .background(LinearGradient.nutritionGradient)
                            .clipShape(Circle())
                    }
                    .buttonStyle(ScaleButtonStyle())

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isExpanded)
                }
                .padding(16)
            }
            .buttonStyle(PlainButtonStyle())

            if isExpanded {
                Divider().padding(.horizontal, 16)
                VStack(spacing: 0) {
                    ForEach(items, id: \.objectID) { entry in
                        foodRow(entry)
                        if entry.objectID != items.last?.objectID {
                            Divider().padding(.horizontal, 16)
                        }
                    }
                    // Buttons row
                    HStack(spacing: 0) {
                        Button(action: { addingMeal = meal }) {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 16)).foregroundColor(meal.color)
                                Text("Добавить")
                                    .font(.subheadline).foregroundColor(meal.color)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16).padding(.vertical, 14)
                        }
                        .buttonStyle(PlainButtonStyle())

                        Divider().frame(height: 20).opacity(0.4)

                        Button(action: { scanningMeal = meal }) {
                            HStack(spacing: 6) {
                                Image(systemName: "camera.viewfinder")
                                    .font(.system(size: 15)).foregroundColor(.nutritionPurple)
                                Text("Сканировать")
                                    .font(.subheadline).foregroundColor(.nutritionPurple)
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.horizontal, 16).padding(.vertical, 14)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(.systemBackground)).cornerRadius(22)
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
        .clipped()
    }

    // MARK: - Food Row (with photo thumbnail)

    private func foodRow(_ entry: FoodEntry) -> some View {
        HStack(spacing: 12) {
            // Photo thumbnail (if AI-scanned)
            if let photoName = entry.photoPath,
               let img = FoodRecognitionService.shared.loadPhoto(named: photoName) {
                Image(uiImage: img)
                    .resizable().scaledToFill()
                    .frame(width: 46, height: 46)
                    .cornerRadius(10).clipped()
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(.systemGray5), lineWidth: 0.5)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(entry.name ?? "")
                        .font(.subheadline).fontWeight(.medium)
                    if entry.photoPath != nil {
                        Image(systemName: "sparkles")
                            .font(.system(size: 9))
                            .foregroundColor(.nutritionPurple)
                    }
                }
                HStack(spacing: 8) {
                    macroChip(Int(entry.protein), "Б", .nutritionPurple)
                    macroChip(Int(entry.fat),     "Ж", .cardioOrange)
                    macroChip(Int(entry.carbs),   "У", .nutritionBlue)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(entry.calories)) ккал")
                    .font(.subheadline).fontWeight(.semibold)
                Text("\(Int(entry.weight)) г")
                    .font(.caption2).foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .contextMenu {
            Button(role: .destructive) {
                withAnimation { viewContext.delete(entry); try? viewContext.save() }
            } label: { Label("Удалить", systemImage: "trash") }
        }
    }

    private func macroChip(_ val: Int, _ label: String, _ color: Color) -> some View {
        HStack(spacing: 2) {
            Text(label).font(.system(size: 10, weight: .bold)).foregroundColor(color)
            Text("\(val)г").font(.system(size: 10)).foregroundColor(.secondary)
        }
    }

    // MARK: - Save AI scan result

    private func saveScanResult(result: FoodAnalysisResult,
                                image: UIImage,
                                grams: Double,
                                meal: MealType) {
        let photoName = FoodRecognitionService.shared.savePhoto(image)
        let entry     = FoodEntry(context: viewContext)
        entry.id        = UUID()
        entry.date      = selectedDate
        entry.mealType  = meal.rawValue
        entry.name      = result.name
        entry.calories  = result.calories(for: grams)
        entry.protein   = result.protein(for: grams)
        entry.fat       = result.fat(for: grams)
        entry.carbs     = result.carbs(for: grams)
        entry.weight    = grams
        entry.photoPath = photoName
        try? viewContext.save()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    // MARK: - Computed

    private var todayEntries: [FoodEntry] {
        allEntries.filter { Calendar.current.isDate($0.date ?? Date(), inSameDayAs: selectedDate) }
    }
    private func entries(for meal: MealType) -> [FoodEntry] {
        todayEntries.filter { $0.mealType == meal.rawValue }
    }
    private var totalCalories: Double { todayEntries.reduce(0) { $0 + $1.calories } }
    private var totalProtein:  Double { todayEntries.reduce(0) { $0 + $1.protein } }
    private var totalFat:      Double { todayEntries.reduce(0) { $0 + $1.fat } }
    private var totalCarbs:    Double { todayEntries.reduce(0) { $0 + $1.carbs } }

    private var headerDateText: String {
        if Calendar.current.isDateInToday(selectedDate)     { return "Сегодня" }
        if Calendar.current.isDateInYesterday(selectedDate) { return "Вчера" }
        let f = DateFormatter(); f.dateFormat = "d MMMM"; f.locale = Locale(identifier: "ru_RU")
        return f.string(from: selectedDate)
    }
    private func changeDay(_ d: Int) {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedDate = Calendar.current.date(byAdding: .day, value: d, to: selectedDate) ?? selectedDate
        }
    }
    private func productWord(_ n: Int) -> String {
        switch n % 10 { case 1: return "продукт"; case 2,3,4: return "продукта"; default: return "продуктов" }
    }
    private func waterKey(for d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return "water_" + f.string(from: d)
    }
    private func loadWater() { waterGlasses = UserDefaults.standard.integer(forKey: waterKey(for: selectedDate)) }
    private func saveWater() { UserDefaults.standard.set(waterGlasses, forKey: waterKey(for: selectedDate)) }
}
