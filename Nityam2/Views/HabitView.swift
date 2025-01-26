import SwiftUI

/// Displays a single habit as a card in the grid
struct HabitView: View {
    // MARK: - Properties
    
    // The habit to display
    let habit: Habit
    // Access to SwiftData storage
    @Environment(\.modelContext) private var modelContext
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showingDeleteAlert = false
    
    // MARK: - View Body
    
    private var habitColors: (background: Color, foreground: Color) {
        // If not a task day, show muted appearance
        guard habit.isTaskDay() else {
            return (Color(.tertiarySystemGroupedBackground), Color(.tertiaryLabel))
        }
        
        if habit.type == .positive {
            return habit.isCompleted ? 
                (themeManager.primaryColor, .white) : 
                (Color(.secondarySystemGroupedBackground), themeManager.primaryColor)
        } else {
            // Negative habits: theme color when completed (good), red when not (bad)
            return habit.isCompleted ? 
                (themeManager.primaryColor, .white) : 
                (Color(.secondarySystemGroupedBackground), .red)
        }
    }
    
    
    var body: some View {
        Button(action: toggleCompletion) {
            VStack(spacing: 16) {
                // Icon with background circle
                ZStack {
                    Circle()
                        .fill(habitColors.background.opacity(0.15))
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: habit.iconName)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(habitColors.foreground)
                        .frame(height: 32)
                }
                .padding(.top, 8)
                
                VStack(spacing: 8) {
                    Text(habit.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(habitColors.foreground)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    if habit.isTaskDay() {
                        // Stats row with improved layout
                        HStack(spacing: 12) {
                            Label {
                                Text("\(habit.currentStreak)")
                                    .font(.system(size: 14, weight: .medium))
                            } icon: {
                                Image(systemName: "flame.fill")
                                    .foregroundColor(.orange)
                            }
                            Label {
                                Text("\(habit.bestStreak)")
                                    .font(.system(size: 14, weight: .medium))
                            } icon: {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.orange)
                            }
                        }
                        .foregroundColor(habitColors.foreground)
                    } else {
                        // Show next task day
                        Text(getNextTaskDayText())
                            .font(.system(size: 14))
                            .foregroundColor(habitColors.foreground)
                    }
                }
                
                if habit.targetDuration > 0 && habit.isTaskDay() {
                    HStack {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12))
                        Text("\(Int(habit.targetDuration/60))m")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(habitColors.foreground.opacity(0.8))
                    .padding(.top, -4)
                }
            }
            .frame(width: UIScreen.main.bounds.width / 2 - 25, height: UIScreen.main.bounds.width / 2 - 25)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(habitColors.background)
                    .shadow(color: Color(.systemGray4).opacity(0.3), radius: 8, x: 0, y: 4)
            )
        }
        .buttonStyle(HabitButtonStyle())
        .contextMenu {
            NavigationLink(destination: StatsView(habit: habit)) {
                Label("View Stats", systemImage: "chart.bar.fill")
                    .foregroundColor(.primary)
            }
            NavigationLink(destination: EditHabitView(habit: habit)) {
                Label("Edit Habit", systemImage: "pencil")
                    .foregroundColor(.primary)
            }
            Divider()
            Button(role: .destructive, action: { showingDeleteAlert = true }) {
                Label("Delete Habit", systemImage: "trash.fill")
            }
        }
        .alert("Delete Habit", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive, action: deleteHabit)
        } message: {
            Text("Are you sure you want to delete '\(habit.name)'? This action cannot be undone.")
        }
    }
    
    // MARK: - Methods
    
    /// Deletes the habit from storage
    private func deleteHabit() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            modelContext.delete(habit)
            try? modelContext.save()
        }
    }
    
    /// Toggles the completion status of the habit
    private func toggleCompletion() {
        // Only allow toggling completion on task days
        guard habit.isTaskDay() else { return }
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            habit.isCompleted.toggle()
            
            if habit.isCompleted {
                // Mark as completed
                habit.completionDates.append(Date())
                habit.currentStreak = habit.calculateStreak()
                habit.bestStreak = max(habit.currentStreak, habit.bestStreak)
            } else {
                // Remove completion if unchecking today's habit
                if let lastDate = habit.completionDates.last,
                   Calendar.current.isDateInToday(lastDate) {
                    habit.completionDates.removeLast()
                    habit.currentStreak = habit.calculateStreak()
                    habit.bestStreak = habit.calculateStreak()
                }
            }
            
            try? modelContext.save()
        }
    }
    
    private func getNextTaskDayText() -> String {
        let calendar = Calendar.current
        var date = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        var daysToNext = 1
        
        // Look ahead up to 31 days to find the next task day
        while daysToNext <= 31 {
            if habit.isTaskDay(for: date) {
                switch habit.frequency {
                case .daily, .weekly:
                    let weekday = calendar.component(.weekday, from: date)
                    if let day = Habit.Weekday(rawValue: weekday) {
                        return "Next: \(day.shortName)"
                    }
                case .custom:
                    if let customSchedule = habit.customSchedule {
                        switch customSchedule.type {
                        case .daysOfMonth:
                            let day = calendar.component(.day, from: date)
                            let month = calendar.component(.month, from: date)
                            let monthName = calendar.monthSymbols[month - 1]
                            return "Next: \(day) \(monthName)"
                        case .intervalDays:
                            let formatter = DateFormatter()
                            formatter.dateFormat = "d MMM"
                            return "Next: \(formatter.string(from: date))"
                        }
                    }
                }
                break
            }
            date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
            daysToNext += 1
        }
        
        return "Not scheduled"
    }
}

// Custom button style for smooth animations
struct HabitButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// New AddHabitView
struct AddHabitView: View {
    var body: some View {
        HabitFormView()
    }
}

// New EditHabitView
struct EditHabitView: View {
    let habit: Habit
    
    var body: some View {
        HabitFormView(habit: habit)
    }
}

// ... existing code ...

#Preview {
    HabitView(habit: Habit(
        name: "Exercise",
        iconName: "figure.run",
        targetDuration: 1800,  // 30 minutes
        type: .positive,
        frequency: .daily,
        taskDays: Set(Habit.Weekday.allCases)
    ))
    .modelContainer(for: Habit.self)
}
