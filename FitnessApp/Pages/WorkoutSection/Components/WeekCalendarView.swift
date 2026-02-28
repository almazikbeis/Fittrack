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
        let cal = Calendar.current
        let today = selectedDate.wrappedValue
        let weekday = cal.component(.weekday, from: today)
        // Monday-first: Sunday(1) → -6, Mon(2) → 0, Tue(3) → -1 ...
        let daysToMonday = weekday == 1 ? -6 : 2 - weekday
        let monday = cal.date(byAdding: .day, value: daysToMonday, to: today) ?? today
        self._currentWeekStart = State(initialValue: monday)
    }

    var body: some View {
        VStack(spacing: 14) {
            // Month / navigation
            HStack {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { moveWeek(by: -1) }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: 32, height: 32)
                        .background(Color(.systemGroupedBackground))
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
                }

                Spacer()

                Text(monthYearTitle)
                    .font(.system(size: 15, weight: .semibold))

                Spacer()

                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { moveWeek(by: 1) }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: 32, height: 32)
                        .background(Color(.systemGroupedBackground))
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
                }
            }

            // Day cells
            HStack(spacing: 6) {
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
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(22)
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
    }

    private var monthYearTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        formatter.locale = Locale(identifier: "ru_RU")
        let str = formatter.string(from: currentWeekStart)
        return str.prefix(1).uppercased() + str.dropFirst()
    }

    private func moveWeek(by offset: Int) {
        guard let newStart = calendar.date(byAdding: .weekOfYear, value: offset, to: currentWeekStart) else { return }
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
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        formatter.locale = Locale(identifier: "ru_RU")
        return String(formatter.string(from: day).prefix(2)).uppercased()
    }

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: day)
    }

    var body: some View {
        VStack(spacing: 6) {
            Text(dayLetters)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)

            Text(dayNumber)
                .font(.system(size: 15, weight: isSelected || isToday ? .bold : .regular))
                .foregroundColor(isSelected ? .white : (isToday ? .primaryGreen : .primary))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            Group {
                if isSelected {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(LinearGradient.primaryGradient)
                } else {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.clear)
                }
            }
        )
        .overlay(
            Group {
                if isToday && !isSelected {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.primaryGreen, lineWidth: 1.5)
                }
            }
        )
    }
}
