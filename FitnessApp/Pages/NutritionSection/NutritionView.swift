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
    @State private var addingMeal: MealType?   = nil
    @State private var scanningMeal: MealType? = nil
    @State private var waterGlasses            = 0
    @State private var expandedMeals: Set<String> = Set(MealType.allCases.map(\.rawValue))
    @State private var animateRing             = false
    @State private var heroReady               = false

    @AppStorage("goalCalories") private var caloriesGoal: Int = 2000
    @AppStorage("goalProtein")  private var proteinGoal:  Int = 150
    @AppStorage("goalFat")      private var fatGoal:      Int = 65
    @AppStorage("goalCarbs")    private var carbsGoal:    Int = 250
    @AppStorage("goalWater")    private var waterGoal:    Int = 8

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: DS.xl) {
                    heroSection
                    macroRow
                    waterTrackerCard
                    ForEach(MealType.allCases) { meal in
                        mealSectionCard(meal)
                    }
                    Spacer().frame(height: 110)
                }
                .padding(.horizontal, DS.lg)
            }
        }
        .onAppear {
            loadWater()
            withAnimation(.spring(response: 0.9, dampingFraction: 0.75).delay(0.15)) {
                animateRing = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.05)) {
                heroReady = true
            }
        }
        .onChange(of: selectedDate) {
            loadWater()
            animateRing = false
            withAnimation(.spring(response: 0.9, dampingFraction: 0.75).delay(0.1)) {
                animateRing = true
            }
        }
        .sheet(item: $addingMeal) { meal in
            AddFoodView(mealType: meal.rawValue, date: selectedDate)
                .environment(\.managedObjectContext, viewContext)
        }
        .fullScreenCover(item: $scanningMeal) { meal in
            FoodScannerView(mealType: meal.rawValue) { result, image, grams in
                saveScanResult(result: result, image: image, grams: grams, meal: meal)
            }
        }
    }

    // MARK: - Hero Section (NRC-style big calorie number)

    private var heroSection: some View {
        ZStack {
            // Accent glow
            RadialGradient(
                colors: [Color.primaryGreen.opacity(0.18), .clear],
                center: .center,
                startRadius: 10,
                endRadius: 160
            )
            .frame(height: 280)

            VStack(spacing: DS.xl) {
                // Header row
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("ПИТАНИЕ")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.primaryGreen)
                            .tracking(2)
                        Text(headerDateText)
                            .font(.title3).fontWeight(.bold)
                    }

                    Spacer()

                    HStack(spacing: DS.sm) {
                        // Day nav
                        navArrow("chevron.left") { changeDay(-1) }
                        navArrow("chevron.right",
                                 disabled: Calendar.current.isDateInToday(selectedDate)) { changeDay(+1) }
                        // Scan button
                        Button(action: { scanningMeal = .breakfast }) {
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(LinearGradient.nutritionGradient,
                                            in: RoundedRectangle(cornerRadius: DS.rSM, style: .continuous))
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                .padding(.top, 68)

                // Big calorie display
                HStack(alignment: .bottom, spacing: DS.xxl) {
                    // Ring
                    ZStack {
                        Circle()
                            .stroke(Color.primaryGreen.opacity(0.1), lineWidth: 10)
                        Circle()
                            .trim(from: 0,
                                  to: animateRing ? CGFloat(min(totalCalories / caloriesGoalD, 1.0)) : 0)
                            .stroke(
                                AngularGradient(
                                    colors: [.primaryGreen,
                                             Color(red: 0.05, green: 0.70, blue: 0.90),
                                             .primaryGreen],
                                    center: .center),
                                style: StrokeStyle(lineWidth: 10, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(response: 1.1, dampingFraction: 0.8), value: animateRing)
                    }
                    .frame(width: 100, height: 100)

                    // Number block
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(alignment: .firstTextBaseline, spacing: DS.xs) {
                            Text("\(Int(totalCalories))")
                                .font(.system(size: 52, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                                .contentTransition(.numericText())
                            Text("ккал")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.secondary)
                                .padding(.bottom, 8)
                        }

                        let remaining = max(caloriesGoalD - totalCalories, 0)
                        HStack(spacing: DS.xs) {
                            Circle().fill(remaining > 0 ? Color.primaryGreen : Color.cardioRed)
                                .frame(width: 6, height: 6)
                            Text(remaining > 0
                                 ? "\(Int(remaining)) осталось"
                                 : "Лимит достигнут")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Text("Цель: \(caloriesGoal) ккал")
                            .font(.caption)
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                }
                .offset(y: heroReady ? 0 : 16)
                .opacity(heroReady ? 1 : 0)
            }
        }
        .padding(.bottom, DS.sm)
    }

    private func navArrow(_ icon: String, disabled: Bool = false,
                          action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(disabled ? Color(.systemGray4) : .primary)
                .frame(width: 32, height: 32)
                .background(Color(.secondarySystemBackground),
                            in: Circle())
        }
        .buttonStyle(ScaleButtonStyle()).disabled(disabled)
    }

    // MARK: - Macro Row (3 mini-cards)

    private var macroRow: some View {
        HStack(spacing: DS.md) {
            macroBentoCard(label: "Белки",    value: Int(totalProtein),  goal: proteinGoal, color: .nutritionPurple)
            macroBentoCard(label: "Жиры",     value: Int(totalFat),      goal: fatGoal,     color: .cardioOrange)
            macroBentoCard(label: "Углеводы", value: Int(totalCarbs),    goal: carbsGoal,   color: .nutritionBlue)
        }
    }

    private func macroBentoCard(label: String, value: Int, goal: Int, color: Color) -> some View {
        let progress = min(Double(value) / max(Double(goal), 1), 1.0)
        return VStack(alignment: .leading, spacing: DS.sm) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(color)
                .tracking(0.3)

            Text("\(value)")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundColor(.primary)
                .contentTransition(.numericText())

            Text("/ \(goal) г")
                .font(.caption2)
                .foregroundColor(.secondary)

            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(color.opacity(0.12)).frame(height: 3)
                    Capsule().fill(color)
                        .frame(width: animateRing ? g.size.width * CGFloat(progress) : 0, height: 3)
                        .animation(.spring(response: 1.0, dampingFraction: 0.8).delay(0.3),
                                   value: animateRing)
                }
            }
            .frame(height: 3)
        }
        .padding(DS.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .nrcCard(radius: DS.rLG)
    }

    // MARK: - Water Tracker

    private var waterTrackerCard: some View {
        VStack(alignment: .leading, spacing: DS.md) {
            HStack {
                HStack(spacing: DS.xs) {
                    Image(systemName: "drop.fill").foregroundColor(.waterBlue)
                    Text("Вода").font(.headline)
                }
                Spacer()
                Text("\(waterGlasses) / \(waterGoal) ст.")
                    .font(.caption).foregroundColor(.secondary)
            }

            HStack(spacing: DS.sm) {
                ForEach(0..<waterGoal, id: \.self) { i in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            waterGlasses = waterGlasses == i + 1 ? i : i + 1
                        }
                        saveWater()
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }) {
                        Image(systemName: i < waterGlasses ? "drop.fill" : "drop")
                            .font(.system(size: 18))
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
                    RoundedRectangle(cornerRadius: 6).fill(Color.waterBlue.opacity(0.12)).frame(height: 5)
                    RoundedRectangle(cornerRadius: 6).fill(LinearGradient.waterGradient)
                        .frame(width: geo.size.width * CGFloat(waterGlasses) / CGFloat(max(waterGoal, 1)),
                               height: 5)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: waterGlasses)
                }
            }.frame(height: 5)
        }
        .padding(DS.lg)
        .nrcCard(radius: DS.rLG)
    }

    // MARK: - Meal Section Card

    private func mealSectionCard(_ meal: MealType) -> some View {
        let items      = entries(for: meal)
        let mealCals   = items.reduce(0.0) { $0 + $1.calories }
        let isExpanded = expandedMeals.contains(meal.rawValue)

        return VStack(spacing: 0) {
            // Header row
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    if isExpanded { expandedMeals.remove(meal.rawValue) }
                    else          { expandedMeals.insert(meal.rawValue) }
                }
            }) {
                HStack(spacing: DS.md) {
                    Image(systemName: meal.icon)
                        .font(.system(size: 17))
                        .foregroundColor(.white)
                        .gradientBadge(meal.gradient, radius: DS.rMD, size: 44)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(meal.rawValue).font(.subheadline).fontWeight(.semibold)
                        Text(items.isEmpty ? "Добавить продукты"
                             : "\(items.count) \(productWord(items.count))")
                            .font(.caption2).foregroundColor(.secondary)
                    }

                    Spacer()

                    if mealCals > 0 {
                        Text("\(Int(mealCals)) ккал")
                            .font(.subheadline).fontWeight(.bold)
                            .foregroundColor(meal.color)
                    }

                    Button(action: { scanningMeal = meal }) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(LinearGradient.nutritionGradient,
                                        in: Circle())
                    }
                    .buttonStyle(ScaleButtonStyle())

                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isExpanded)
                }
                .padding(DS.lg)
            }
            .buttonStyle(PlainButtonStyle())

            if isExpanded {
                Divider().overlay(Color.surfaceBorder).padding(.horizontal, DS.lg)

                VStack(spacing: 0) {
                    ForEach(items, id: \.objectID) { entry in
                        foodRow(entry)
                        if entry.objectID != items.last?.objectID {
                            Divider().overlay(Color.surfaceBorder).padding(.horizontal, DS.lg)
                        }
                    }

                    // Action buttons row
                    HStack(spacing: 0) {
                        Button(action: { addingMeal = meal }) {
                            HStack(spacing: DS.xs) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 15)).foregroundColor(meal.color)
                                Text("Добавить")
                                    .font(.subheadline).foregroundColor(meal.color)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, DS.lg).padding(.vertical, DS.md)
                        }
                        .buttonStyle(PlainButtonStyle())

                        Divider().frame(height: 20).opacity(0.3)

                        Button(action: { scanningMeal = meal }) {
                            HStack(spacing: DS.xs) {
                                Image(systemName: "camera.viewfinder")
                                    .font(.system(size: 14)).foregroundColor(.nutritionPurple)
                                Text("Скан")
                                    .font(.subheadline).foregroundColor(.nutritionPurple)
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.horizontal, DS.lg).padding(.vertical, DS.md)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .nrcCard(radius: DS.rLG)
        .clipped()
    }

    // MARK: - Food Row

    private func foodRow(_ entry: FoodEntry) -> some View {
        HStack(spacing: DS.md) {
            if let photoName = entry.photoPath,
               let img = FoodRecognitionService.shared.loadPhoto(named: photoName) {
                Image(uiImage: img)
                    .resizable().scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: DS.rSM, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: DS.xs) {
                    Text(entry.name ?? "")
                        .font(.subheadline).fontWeight(.medium)
                    if entry.photoPath != nil {
                        Image(systemName: "sparkles")
                            .font(.system(size: 9))
                            .foregroundColor(.nutritionPurple)
                    }
                }
                HStack(spacing: DS.sm) {
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
        .padding(.horizontal, DS.lg).padding(.vertical, DS.md)
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

    private func saveScanResult(result: FoodAnalysisResult, image: UIImage,
                                grams: Double, meal: MealType) {
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
    private var caloriesGoalD: Double { max(Double(caloriesGoal), 1) }

    private var headerDateText: String {
        if Calendar.current.isDateInToday(selectedDate) { return "Сегодня" }
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
        switch n % 10 {
        case 1: return "продукт"
        case 2, 3, 4: return "продукта"
        default: return "продуктов"
        }
    }

    private func waterKey(for d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return "water_" + f.string(from: d)
    }
    private func loadWater() { waterGlasses = UserDefaults.standard.integer(forKey: waterKey(for: selectedDate)) }
    private func saveWater() { UserDefaults.standard.set(waterGlasses, forKey: waterKey(for: selectedDate)) }
}
