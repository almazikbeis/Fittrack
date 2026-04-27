//
//  QuestEngine.swift
//  FitnessApp
//
//  "Путь Стихий" — quest, NPC, character progression system.
//

import SwiftUI
import Combine

// MARK: - NPC Mentor

struct NPCMentor: Identifiable {
    let id: String
    let name: String
    let title: String
    let element: AvatarElement
    let sfSymbol: String
    let personality: String   // short descriptor shown in UI

    // Context-aware greetings
    let greetings: [String]
    let wisdom: [String]      // random tips

    // Dialogue lines per quest id: [questId: [lines]]
    let questIntro: [String: [String]]
    let questComplete: [String: [String]]
}

// MARK: - Quest

struct Quest: Identifiable {
    let id: String
    let title: String
    let description: String
    let element: AvatarElement
    let mentorId: String
    let xpReward: Int
    let coinReward: Int
    let requirementDescription: String  // shown to user
    let targetCount: Int                // total steps needed
    var isMainQuest: Bool = true

    // runtime
    var currentCount: Int = 0
    var isCompleted: Bool = false

    var progress: Double {
        guard targetCount > 0 else { return isCompleted ? 1 : 0 }
        return min(Double(currentCount) / Double(targetCount), 1.0)
    }
}

// MARK: - Player Stats

struct PlayerStats {
    var strength:  Int = 0   // from strength workouts
    var agility:   Int = 0   // from cardio
    var balance:   Int = 0   // from nutrition logs
    var willpower: Int = 0   // from streak days

    var total: Int { strength + agility + balance + willpower }
}

// MARK: - All NPCs

extension NPCMentor {
    static let all: [NPCMentor] = [lian, koa, bao, agni]

    static let lian = NPCMentor(
        id: "lian",
        name: "Мастер Лиань",
        title: "Страж Воздуха",
        element: .air,
        sfSymbol: "wind",
        personality: "Мудрая • Поэтичная • Свободолюбивая",
        greetings: [
            "Каждый шаг — это вдох. Каждый вдох — это жизнь, ученик.",
            "Снова ты здесь. Твои ноги помнят путь сами.",
            "Ветер не спрашивает разрешения двигаться. Ты тоже не должен.",
            "Лёгкость — не слабость. Это высшая форма силы.",
        ],
        wisdom: [
            "Бег учит не скорости — он учит доверию к своему телу.",
            "Воздух не имеет формы, но он везде. Будь как воздух.",
            "Три километра или тридцать — начало у них одно: первый шаг.",
            "Дыши глубоко. Кислород — топливо твоего пути.",
        ],
        questIntro: [
            "q_air_1": [
                "Юный странник... ты пришёл ко мне.",
                "Значит, ты чувствуешь зов ветра?",
                "Хорошо. Мой первый урок прост:",
                "Выйди и беги. Хотя бы раз. Пусть ноги найдут свой ритм.",
                "Вернись, когда завершишь первую кардио-тренировку.",
            ],
            "q_air_weekly": [
                "Тело скучает по движению. Я вижу это.",
                "Три кардио за неделю — это твоя задача.",
                "Не думай о расстоянии. Думай о ветре за спиной.",
            ],
        ],
        questComplete: [
            "q_air_1": [
                "...",
                "Ты вернулся.",
                "Я чувствую запах свежего воздуха от тебя.",
                "Стихия Воздуха приняла тебя. Носи это с достоинством.",
                "🌪️ Элемент ВОЗДУХ разблокирован!",
            ],
            "q_air_weekly": [
                "Три тренировки. Ты сделал это.",
                "Твои лёгкие становятся сильнее. Я слышу это.",
                "Возвращайся снова, ученик.",
            ],
        ]
    )

    static let koa = NPCMentor(
        id: "koa",
        name: "Целительница Коа",
        title: "Хранительница Воды",
        element: .water,
        sfSymbol: "drop.fill",
        personality: "Заботливая • Мудрая • Уравновешенная",
        greetings: [
            "Тело — это сосуд. Наполняй его мудро, дитя.",
            "Вода принимает форму любого сосуда. Будь гибким, но сильным.",
            "Питание — это любовь к себе. Ты любишь себя сегодня?",
            "Восстановление так же важно, как и нагрузка.",
        ],
        wisdom: [
            "Ешь радугу: чем ярче цвет, тем богаче польза.",
            "Вода в теле — это жизнь. Не забывай о ней.",
            "Белок — строительный материал твоего тела. Без него нет роста.",
            "Голод и аппетит — разные вещи. Учись их различать.",
        ],
        questIntro: [
            "q_water_1": [
                "Хм. Ты выглядишь... неплохо.",
                "Но твоё тело — что оно получает каждый день?",
                "Трёхдневное питание. Я хочу видеть его.",
                "Записывай каждый приём пищи три дня подряд.",
                "Только тогда мы поговорим о питании серьёзно.",
            ],
            "q_water_daily": [
                "Сегодня — лёгкое задание.",
                "Запиши все три основных приёма пищи.",
                "Завтрак, обед, ужин. Это всё.",
            ],
        ],
        questComplete: [
            "q_water_1": [
                "Три дня...",
                "Ты дисциплинирован. Это редкость.",
                "Вода принимает тебя в свои объятия.",
                "💧 Элемент ВОДА разблокирован!",
                "Помни: питание — это твой ежедневный ритуал.",
            ],
            "q_water_daily": [
                "Хорошо. Три приёма пищи.",
                "Завтра сделай то же самое.",
                "Из маленьких шагов рождаются большие изменения.",
            ],
        ]
    )

    static let bao = NPCMentor(
        id: "bao",
        name: "Дед Бао",
        title: "Мастер Земли",
        element: .earth,
        sfSymbol: "mountain.2.fill",
        personality: "Суровый • Честный • Надёжный",
        greetings: [
            "Ха! Снова явился. Значит, не такой уж слабак.",
            "Земля не терпит слабости. Ты готов к работе?",
            "В прошлый раз ты неплохо поднял. Сегодня больше.",
            "Не думай. Поднимай. Думать будешь потом.",
        ],
        wisdom: [
            "Один подход с правильной техникой стоит десяти с плохой.",
            "Тело запоминает нагрузку. Будь последователен.",
            "Мышцы растут не во время тренировки — они растут во сне.",
            "Прогрессивная нагрузка — единственный закон в зале.",
        ],
        questIntro: [
            "q_earth_1": [
                "Смотри мне в глаза.",
                "Пять силовых тренировок. Не меньше.",
                "Каждая — с полной отдачей.",
                "Не приходи ко мне с отговорками.",
                "Приходи с результатами.",
            ],
            "q_earth_weekly": [
                "Три силовые за неделю.",
                "Это не обсуждается.",
                "Идёт?",
            ],
        ],
        questComplete: [
            "q_earth_1": [
                "...",
                "Пять тренировок.",
                "Ты сделал это.",
                "Не ожидал. Признаю.",
                "🌍 Элемент ЗЕМЛЯ разблокирован!",
                "Твоя сила — настоящая теперь.",
            ],
            "q_earth_weekly": [
                "Три тренировки. Хорошо.",
                "На следующей неделе — тяжелее.",
                "Иди.",
            ],
        ]
    )

    static let agni = NPCMentor(
        id: "agni",
        name: "Полководец Агни",
        title: "Воин Огня",
        element: .fire,
        sfSymbol: "flame.fill",
        personality: "Страстный • Интенсивный • Бескомпромиссный",
        greetings: [
            "ОГОНЬ внутри или снаружи — выбор за тобой!",
            "Слабость — это опция. Сегодня ты её не выбираешь!",
            "Семь дней подряд. Это я называю серьёзностью!",
            "Я видел твои результаты. Сегодня ты превзойдёшь себя!",
        ],
        wisdom: [
            "HIIT — это не просто тренировка. Это битва с собой.",
            "После каждой тяжёлой тренировки ты сильнее, чем вчера.",
            "Огонь гаснет без топлива. Не пропускай тренировки.",
            "Интенсивность — это не скорость. Это полная отдача здесь и сейчас.",
        ],
        questIntro: [
            "q_fire_1": [
                "Ты хочешь Огонь?",
                "ОГОНЬ — это не подарок. Это испытание!",
                "Семь дней тренировок. Без пропусков. Без оправданий.",
                "Каждый день — хоть одна тренировка.",
                "Только тогда я признаю тебя достойным.",
            ],
            "q_fire_weekly": [
                "Пять дней подряд!",
                "Это твой огненный вызов на эту неделю.",
                "Не остывай!",
            ],
        ],
        questComplete: [
            "q_fire_1": [
                "СЕМЬ ДНЕЙ!",
                "Ты сделал это!",
                "Я... впечатлён. Редко такое говорю.",
                "🔥 Элемент ОГОНЬ разблокирован!",
                "Огонь в тебе настоящий. Не давай ему угаснуть.",
            ],
            "q_fire_weekly": [
                "ПЯТЬ ДНЕЙ! ПРЕВОСХОДНО!",
                "Твой огонь горит ярко!",
                "До встречи на следующей неделе, воин!",
            ],
        ]
    )
}

// MARK: - Quest Definitions

extension Quest {
    static var all: [Quest] {[
        // ── Main Quests ──
        Quest(id: "q_air_1",   title: "Первое Дыхание",
              description: "Соверши первую кардио-тренировку и познай лёгкость Воздуха",
              element: .air,   mentorId: "lian", xpReward: 200, coinReward: 50,
              requirementDescription: "Выполни 1 кардио-тренировку",   targetCount: 1),
        Quest(id: "q_water_1", title: "Поток Воды",
              description: "Записывай питание три дня подряд и обрети баланс Воды",
              element: .water, mentorId: "koa",  xpReward: 250, coinReward: 60,
              requirementDescription: "Записывай питание 3 дня",        targetCount: 3),
        Quest(id: "q_earth_1", title: "Сила Земли",
              description: "Соверши пять силовых тренировок и стань непоколебимым",
              element: .earth, mentorId: "bao",  xpReward: 300, coinReward: 70,
              requirementDescription: "Выполни 5 силовых тренировок",   targetCount: 5),
        Quest(id: "q_fire_1",  title: "Испытание Огнём",
              description: "Тренируйся 7 дней подряд и зажги огонь внутри",
              element: .fire,  mentorId: "agni", xpReward: 400, coinReward: 100,
              requirementDescription: "Серия 7 дней",                   targetCount: 7),

        // ── Side Quests ──
        Quest(id: "q_air_weekly",   title: "Воздушная неделя",
              description: "3 кардио за неделю",
              element: .air,   mentorId: "lian", xpReward: 100, coinReward: 25,
              requirementDescription: "3 кардио-тренировки за неделю",  targetCount: 3, isMainQuest: false),
        Quest(id: "q_water_daily",  title: "День питания",
              description: "Запиши все 3 основных приёма пищи сегодня",
              element: .water, mentorId: "koa",  xpReward: 60,  coinReward: 15,
              requirementDescription: "3 приёма пищи за день",          targetCount: 3, isMainQuest: false),
        Quest(id: "q_earth_weekly", title: "Железная воля",
              description: "3 силовые тренировки за неделю",
              element: .earth, mentorId: "bao",  xpReward: 120, coinReward: 30,
              requirementDescription: "3 силовые за неделю",            targetCount: 3, isMainQuest: false),
        Quest(id: "q_fire_weekly",  title: "Огненная серия",
              description: "5 дней подряд с тренировкой",
              element: .fire,  mentorId: "agni", xpReward: 150, coinReward: 35,
              requirementDescription: "Серия 5 дней",                   targetCount: 5, isMainQuest: false),
    ]}
}

// MARK: - Quest Engine

@MainActor
final class QuestEngine: ObservableObject {
    static let shared = QuestEngine()

    @Published var quests: [Quest] = Quest.all
    @Published var activeDialogue: DialogueSession? = nil
    @Published var showDialogue = false
    @Published var justCompletedQuestId: String? = nil

    // Persistent progress storage
    @AppStorage("qe_completed")    private var completedJSON: String = "[]"
    @AppStorage("qe_progress")     private var progressJSON:  String = "{}"
    @AppStorage("gam_stat_str")    var statStrength:  Int = 0
    @AppStorage("gam_stat_agi")    var statAgility:   Int = 0
    @AppStorage("gam_stat_bal")    var statBalance:   Int = 0
    @AppStorage("gam_stat_will")   var statWillpower: Int = 0

    var playerStats: PlayerStats {
        PlayerStats(strength: statStrength, agility: statAgility,
                    balance: statBalance, willpower: statWillpower)
    }

    private init() { loadProgress() }

    // MARK: - Update from fitness actions

    func recordCardio() {
        increment("q_air_1"); increment("q_air_weekly")
        statAgility = min(statAgility + 3, 100)
        checkCompletions()
    }

    func recordStrength() {
        increment("q_earth_1"); increment("q_earth_weekly")
        statStrength = min(statStrength + 3, 100)
        checkCompletions()
    }

    func recordMealLogged() {
        increment("q_water_1"); increment("q_water_daily")
        statBalance = min(statBalance + 2, 100)
        checkCompletions()
    }

    func recordStreakDay(_ streak: Int) {
        if let idx = quests.firstIndex(where: { $0.id == "q_fire_1" }) {
            quests[idx].currentCount = min(streak, quests[idx].targetCount)
        }
        if let idx = quests.firstIndex(where: { $0.id == "q_fire_weekly" }) {
            quests[idx].currentCount = min(streak, quests[idx].targetCount)
        }
        statWillpower = min(statWillpower + streak / 2, 100)
        checkCompletions()
    }

    // MARK: - Dialogue

    func openDialogue(questId: String, phase: DialoguePhase) {
        guard let quest = quests.first(where: { $0.id == questId }),
              let mentor = NPCMentor.all.first(where: { $0.id == quest.mentorId }) else { return }

        let lines: [String]
        switch phase {
        case .intro:
            lines = mentor.questIntro[questId] ?? [mentor.greetings.randomElement()!]
        case .complete:
            lines = mentor.questComplete[questId] ?? ["Отлично, ученик!"]
        case .greeting:
            lines = [mentor.greetings.randomElement()!, mentor.wisdom.randomElement()!]
        }

        activeDialogue = DialogueSession(mentor: mentor, lines: lines, questId: questId, phase: phase)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { showDialogue = true }
    }

    func closeDialogue() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { showDialogue = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { self.activeDialogue = nil }
    }

    // MARK: - Private

    private func increment(_ id: String) {
        guard let idx = quests.firstIndex(where: { $0.id == id && !$0.isCompleted }) else { return }
        quests[idx].currentCount = min(quests[idx].currentCount + 1, quests[idx].targetCount)
        saveProgress()
    }

    private func checkCompletions() {
        for i in quests.indices {
            guard !quests[i].isCompleted,
                  quests[i].currentCount >= quests[i].targetCount else { continue }
            completeQuest(at: i)
        }
    }

    private func completeQuest(at index: Int) {
        let quest = quests[index]
        quests[index].isCompleted = true
        justCompletedQuestId = quest.id
        saveProgress()

        GamificationEngine.shared.addXP(quest.xpReward, source: .achievement)
        GamificationEngine.shared.coins += quest.coinReward

        // Show completion dialogue after short delay
        Task {
            try? await Task.sleep(for: .seconds(1.0))
            openDialogue(questId: quest.id, phase: .complete)
        }
    }

    // MARK: - Persistence

    private func loadProgress() {
        let decoder = JSONDecoder()
        if let data = completedJSON.data(using: .utf8),
           let completed = try? decoder.decode([String].self, from: data) {
            for id in completed {
                if let idx = quests.firstIndex(where: { $0.id == id }) {
                    quests[idx].isCompleted = true
                    quests[idx].currentCount = quests[idx].targetCount
                }
            }
        }
        if let data = progressJSON.data(using: .utf8),
           let progress = try? decoder.decode([String: Int].self, from: data) {
            for (id, count) in progress {
                if let idx = quests.firstIndex(where: { $0.id == id }) {
                    quests[idx].currentCount = count
                }
            }
        }
    }

    private func saveProgress() {
        let completed = quests.filter(\.isCompleted).map(\.id)
        let progress  = Dictionary(uniqueKeysWithValues: quests.map { ($0.id, $0.currentCount) })
        if let d1 = try? JSONEncoder().encode(completed)             { completedJSON = String(data: d1, encoding: .utf8) ?? "[]" }
        if let d2 = try? JSONEncoder().encode(progress)              { progressJSON  = String(data: d2, encoding: .utf8) ?? "{}" }
    }
}

// MARK: - Dialogue Model

enum DialoguePhase { case intro, complete, greeting }

struct DialogueSession: Identifiable {
    let id = UUID()
    let mentor: NPCMentor
    let lines: [String]
    let questId: String
    let phase: DialoguePhase
}
