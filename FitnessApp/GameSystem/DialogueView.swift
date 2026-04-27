//
//  DialogueView.swift
//  FitnessApp
//
//  NPC dialogue with typewriter effect — Avatar-style.
//

import SwiftUI

struct DialogueView: View {

    let session: DialogueSession
    var onComplete: () -> Void = {}

    @State private var lineIndex  = 0
    @State private var displayed  = ""
    @State private var isTyping   = false
    @State private var appeared   = false
    @State private var portraitPulse = false

    private var mentor: NPCMentor { session.mentor }
    private var lines: [String]   { session.lines }
    private var currentLine: String { lines[lineIndex] }

    var body: some View {
        ZStack {
            // Blur backdrop
            Color.black.opacity(0.55).ignoresSafeArea()
                .onTapGesture { advanceLine() }

            VStack(spacing: 0) {
                Spacer()
                dialogueCard
                    .padding(.horizontal, 16)
                    .padding(.bottom, 48)
                    .scaleEffect(appeared ? 1 : 0.85)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 60)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) { appeared = true }
            startTyping(currentLine)
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                portraitPulse = true
            }
        }
    }

    // MARK: - Dialogue Card

    private var dialogueCard: some View {
        VStack(spacing: 0) {
            // NPC Portrait + Name strip
            mentorStrip

            // Text area
            ZStack(alignment: .bottomTrailing) {
                Text(displayed.isEmpty ? " " : displayed)
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .foregroundColor(.primary)
                    .lineSpacing(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(22)
                    .frame(minHeight: 120)

                // Tap hint
                if !isTyping {
                    HStack(spacing: 4) {
                        Image(systemName: lineIndex < lines.count - 1 ? "arrow.right.circle.fill" : "checkmark.circle.fill")
                            .font(.system(size: 14))
                        Text(lineIndex < lines.count - 1 ? "Далее" : "Готово")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(mentor.element.color)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(mentor.element.color.opacity(0.12))
                    .cornerRadius(20)
                    .padding(12)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
            .background(Color(.systemBackground))
            .onTapGesture { advanceLine() }
        }
        .background(Color(.systemBackground))
        .cornerRadius(28)
        .shadow(color: mentor.element.color.opacity(0.3), radius: 30, x: 0, y: 10)
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(mentor.element.color.opacity(0.25), lineWidth: 1.5)
        )
    }

    // MARK: - Mentor Strip

    private var mentorStrip: some View {
        HStack(spacing: 14) {
            // Animated portrait
            ZStack {
                Circle()
                    .fill(mentor.element.gradient)
                    .frame(width: 60, height: 60)
                    .scaleEffect(portraitPulse ? 1.06 : 1.0)
                    .shadow(color: mentor.element.color.opacity(portraitPulse ? 0.6 : 0.3), radius: 14)

                Image(systemName: mentor.sfSymbol)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.leading, 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(mentor.name)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                HStack(spacing: 4) {
                    Image(systemName: mentor.element.icon)
                        .font(.system(size: 10))
                        .foregroundColor(mentor.element.color)
                    Text(mentor.title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Progress dots
            HStack(spacing: 5) {
                ForEach(0..<lines.count, id: \.self) { i in
                    Circle()
                        .fill(i == lineIndex ? mentor.element.color : Color(.systemGray4))
                        .frame(width: i == lineIndex ? 8 : 5, height: i == lineIndex ? 8 : 5)
                        .animation(.spring(response: 0.3), value: lineIndex)
                }
            }
            .padding(.trailing, 20)
        }
        .padding(.vertical, 16)
        .background(mentor.element.color.opacity(0.07))
    }

    // MARK: - Typewriter

    private func startTyping(_ text: String) {
        displayed = ""
        isTyping = true
        Task {
            for char in text {
                displayed.append(char)
                let delay: UInt64 = char == "." || char == "!" || char == "?" ? 80_000_000 : 28_000_000
                try? await Task.sleep(nanoseconds: delay)
            }
            withAnimation { isTyping = false }
        }
    }

    // MARK: - Navigation

    private func advanceLine() {
        if isTyping {
            // Skip typing — show full line instantly
            displayed = currentLine
            Task { try? await Task.sleep(nanoseconds: 50_000_000); withAnimation { isTyping = false } }
            return
        }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        if lineIndex < lines.count - 1 {
            withAnimation(.easeOut(duration: 0.15)) { displayed = "" }
            lineIndex += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                startTyping(lines[lineIndex])
            }
        } else {
            onComplete()
        }
    }
}

// MARK: - Floating dialogue trigger

struct DialogueOverlay: View {
    @ObservedObject var engine = QuestEngine.shared

    var body: some View {
        if engine.showDialogue, let session = engine.activeDialogue {
            DialogueView(session: session) {
                engine.closeDialogue()
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.3), value: engine.showDialogue)
            .zIndex(300)
        }
    }
}
