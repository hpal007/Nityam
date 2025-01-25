import SwiftUI

/// Displays a single habit as a card in the grid
struct HabitView: View {
    // MARK: - Properties
    
    // The habit to display
    let habit: Habit
    // Access to SwiftData storage
    @Environment(\.modelContext) private var modelContext
    @State private var showingStats = false
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showingEditSheet = false
    
    // MARK: - View Body
    
    private var habitColors: (background: Color, foreground: Color) {
        if habit.type == .positive {
            return habit.isCompleted ? 
                (themeManager.primaryColor, .white) : 
                (Color(.tertiarySystemBackground), themeManager.primaryColor)
        } else {
            // Negative habits: theme color when completed (good), red when not (bad)
            return habit.isCompleted ? 
                (themeManager.primaryColor, .white) : 
                (Color(.tertiarySystemBackground), .red)
        }
    }
    
    var body: some View {
        // Main button that toggles habit completion
        Button(action: toggleCompletion) {
            VStack(spacing: 16) {
                // Larger icon
                Image(systemName: habit.iconName)
                    .font(.system(size: 60))
                    .foregroundColor(habitColors.foreground)
                    .frame(height: 60)
                
                VStack(spacing: 8) {
                    Text(habit.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(habitColors.foreground)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    // Stats row
                    HStack(spacing: 12) {
                        // Current streak
                        Label("\(habit.currentStreak)", systemImage: "flame.fill")
                            .font(.system(size: 14, weight: .medium))
                        
                        // Completion percentage
                        if let percentage = calculateCompletionPercentage() {
                            Text("\(Int(percentage))%")
                                .font(.system(size: 14, weight: .medium))
                        }
                    }
                    .foregroundColor(habitColors.foreground)
                }
                
                if habit.targetDuration > 0 {
                    Text("\(Int(habit.targetDuration/60))m")
                        .font(.system(size: 14))
                        .foregroundColor(habitColors.foreground)
                }
            }
            .frame(width: UIScreen.main.bounds.width / 2 - 25, height: UIScreen.main.bounds.width / 2 - 25)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(habitColors.background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(.separator), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle()) // This prevents the blue highlight
        .contextMenu {
            Button(action: { showingStats = true }) {
                Label("View Stats", systemImage: "chart.bar.fill")
                    .foregroundColor(.primary)
            }
            Button(action: { showingEditSheet = true }) {
                Label("Edit Habit", systemImage: "pencil")
                    .foregroundColor(.primary)
            }
        }
        .sheet(isPresented: $showingStats) {
            NavigationView {
                StatsView(habit: habit)
                    .navigationTitle("Statistics")
                    .navigationBarItems(trailing: Button("Done") {
                        showingStats = false
                    })
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditHabitView(habit: habit)
        }
    }
    
    // MARK: - Methods
    
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
                }
            }
            
            // Save changes to persistent storage
            try? modelContext.save()
        }
    }
    
    private func calculateCompletionPercentage() -> Double? {
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date())!
        
        let recentCompletions = habit.completionDates.filter { $0 >= thirtyDaysAgo }
        return Double(recentCompletions.count) / 30.0 * 100
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
                leading: Button("Cancel") { dismiss() },
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
