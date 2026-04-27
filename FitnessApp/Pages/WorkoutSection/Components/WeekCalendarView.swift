//
//  WeekCalendarView.swift
//  FitnessApp
//

import SwiftUI

struct WeekCalendarView: View {
    @Binding var selectedDate: Date
    private let calendar = Calendar.current
    @State private var currentWeekStart: Date

    init(selectedDate: Binding<Date>) {
        self._selectedDate = selectedDate
        let cal   = Calendar.current
        let today = selectedDate.wrappedValue
        let weekday    = cal.component(.weekday, from: today)
        let daysToMon  = weekday == 1 ? -6 : 2 - weekday
        let monday     = cal.date(byAdding: .day, value: daysToMon, to: today) ?? today
        self._currentWeekStart = State(initialValue: monday)
    }

    var body: some View {
        VStack(spacing: DS.md) {
            // Month / navigation row
            HStack {
                navButton("chevron.left") {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { moveWeek(by: -1) }
                }

                Spacer()

                Text(monthYearTitle)
                    .font(.system(size: 14, weight: .semibold))

                Spacer()

                navButton("chevron.right") {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { moveWeek(by: 1) }
                }
            }

            // Day cells
            HStack(spacing: DS.xs) {
                ForEach(weekDays(), id: \.self) { day in
                    DayCell(
                        day: day,
                        isSelected: calendar.isDate(day, inSameDayAs: selectedDate),
                        isToday: calendar.isDateInToday(day)
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedDate = day
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
            }
        }
        .padding(DS.lg)
        .nrcCard(radius: DS.rXL)
    }

    private func navButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.primary)
                .frame(width: 32, height: 32)
                .background(Color(.secondarySystemBackground), in: Circle())
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var monthYearTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        formatter.locale = Locale(identifier: "ru_RU")
        let str = formatter.string(from: currentWeekStart)
        return str.prefix(1).uppercased() + str.dropFirst()
    }

    private func moveWeek(by offset: Int) {
        guard let newStart = calendar.date(byAdding: .weekOfYear,
                                           value: offset,
                                           to: currentWeekStart) else { return }
        currentWeekStart = newStart
    }

    private func weekDays() -> [Date] {
        (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: currentWeekStart) }
    }
}

// MARK: - Day Cell

private struct DayCell: View {
    let day: Date
    let isSelected: Bool
    let isToday: Bool

    private let calendar = Calendar.current

    private var dayLetters: String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        f.locale = Locale(identifier: "ru_RU")
        return String(f.string(from: day).prefix(2)).uppercased()
    }

    private var dayNumber: String {
        let f = DateFormatter(); f.dateFormat = "d"
        return f.string(from: day)
    }

    var body: some View {
        VStack(spacing: DS.xs) {
            Text(dayLetters)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(isSelected ? .white.opacity(0.75) : .secondary)

            Text(dayNumber)
                .font(.system(size: 15, weight: isSelected || isToday ? .bold : .regular))
                .foregroundColor(isSelected ? .white : (isToday ? .primaryGreen : .primary))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.md)
        .background(
            Group {
                if isSelected {
                    RoundedRectangle(cornerRadius: DS.rMD, style: .continuous)
                        .fill(LinearGradient.primaryGradient)
                } else {
                    RoundedRectangle(cornerRadius: DS.rMD, style: .continuous)
                        .fill(Color.clear)
                }
            }
        )
        .overlay(
            Group {
                if isToday && !isSelected {
                    RoundedRectangle(cornerRadius: DS.rMD, style: .continuous)
                        .stroke(Color.primaryGreen, lineWidth: 1.5)
                }
            }
        )
    }
}
