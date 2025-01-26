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

//
//                        if let percentage = calculateCompletionPercentage() {
//                            Text("\(Int(percentage))%")
//                                .font(.system(size: 14, weight: .medium))
//                        }
                    }
                    .foregroundColor(habitColors.foreground)
                }
                
                if habit.targetDuration > 0 {
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
                    // Update best streak here as well, in case removing today's completion
                    // affects historical streaks
                    habit.bestStreak = habit.bestStreak - 1;
                }
            }
            
            try? modelContext.save()
        }
    }
//    private func calculateCompletionPercentage() -> Double? {
//        let calendar = Calendar.current
//        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date())!
//        
//        let recentCompletions = habit.completionDates.filter { $0 >= thirtyDaysAgo }
//        return Double(recentCompletions.count) / 30.0 * 100
//    }
}

// Custom button style for smooth animations
struct HabitButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// New EditHabitView
struct EditHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var themeManager = ThemeManager.shared
    
    let habit: Habit
    @State private var name: String
    @State private var iconName: String
    @State private var duration: TimeInterval
    @State private var habitType: Habit.HabitType
    @State private var frequency: Habit.Frequency
    @State private var selectedDays: Set<Habit.Weekday>
    
    init(habit: Habit) {
        self.habit = habit
        _name = State(initialValue: habit.name)
        _iconName = State(initialValue: habit.iconName)
        _duration = State(initialValue: habit.targetDuration)
        _habitType = State(initialValue: habit.type)
        _frequency = State(initialValue: habit.frequency)
        _selectedDays = State(initialValue: habit.taskDays)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Basic Info")) {
                    TextField("Habit Name", text: $name)
                    Picker("Type", selection: $habitType) {
                        Text("Positive Habit").tag(Habit.HabitType.positive)
                        Text("Negative Habit").tag(Habit.HabitType.negative)
                    }
                    
                    Picker("Frequency", selection: $frequency) {
                        Text("Daily").tag(Habit.Frequency.daily)
                        Text("Weekly").tag(Habit.Frequency.weekly)
                        Text("Custom").tag(Habit.Frequency.custom)
                    }
                }
                
                // Reuse icon grid from AddHabitView
                Section(header: Text("Icon")) {
                    IconGridView(selectedIcon: $iconName)
                }
                
                if frequency != .daily {
                    Section(header: Text("Task Days")) {
                        WeekdaySelector(selectedDays: $selectedDays)
                    }
                }
                
                if habitType == .positive {
                    Section(header: Text("Duration (Optional)")) {
                        DurationPicker(duration: $duration)
                    }
                }
            }
            .navigationTitle("Edit Habit")
            .navigationBarItems(
                trailing: Button("Save") {
                    updateHabit()
                    dismiss()
                }
                .disabled(name.isEmpty)
            )
        }
    }
    
    private func updateHabit() {
        habit.name = name
        habit.iconName = iconName
        habit.targetDuration = duration
        habit.type = habitType
        habit.frequency = frequency
        habit.taskDays = selectedDays
        
        try? modelContext.save()
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
