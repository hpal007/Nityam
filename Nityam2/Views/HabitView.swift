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
                
                Section(header: Text("Duration (Optional)")) {
                    DurationPicker(duration: $duration)
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

// Helper view for icon selection
struct IconGridView: View {
    @Binding var selectedIcon: String
    @StateObject private var themeManager = ThemeManager.shared
    
    let icons = [
        // Health & Fitness
        "figure.walk", "figure.run", "figure.hiking", "figure.yoga", 
        "figure.pool.swim", "figure.dance", "dumbbell.fill", "heart.fill",
        
        // Mindfulness & Wellness
        "brain.head.profile", "bed.double.fill", "zzz", "lungs.fill",
        "leaf.fill", "drop.fill", "pills.fill", "cross.case.fill",
        
        // Productivity
        "book.fill", "text.book.closed.fill", "doc.fill", "pencil",
        "keyboard", "desktopcomputer", "laptopcomputer", "mail.fill",
        
        // Lifestyle
        "house.fill", "cart.fill", "creditcard.fill", "dollarsign.circle.fill",
        "clock.fill", "alarm.fill", "calendar", "gift.fill"
    ]
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
            ForEach(icons, id: \.self) { icon in
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(selectedIcon == icon ? themeManager.primaryColor : .primary)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedIcon == icon ? themeManager.primaryColor.opacity(0.2) : Color.clear)
                    )
                    .onTapGesture {
                        selectedIcon = icon
                    }
            }
        }
        .padding(.vertical, 8)
    }
}

// Add WeekdaySelector if it's missing
struct WeekdaySelector: View {
    @Binding var selectedDays: Set<Habit.Weekday>
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Habit.Weekday.allCases, id: \.self) { day in
                    Toggle(isOn: Binding(
                        get: { selectedDays.contains(day) },
                        set: { isSelected in
                            if isSelected {
                                selectedDays.insert(day)
                            } else {
                                selectedDays.remove(day)
                            }
                        }
                    )) {
                        Text(day.shortName)
                    }
                    .toggleStyle(DayToggleStyle())
                }
            }
            .padding(.horizontal)
        }
    }
}

struct DayToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: { configuration.isOn.toggle() }) {
            configuration.label
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(configuration.isOn ? .white : .primary)
                .frame(width: 40, height: 40)
                .background(configuration.isOn ? Color.blue : Color(.systemGray5))
                .clipShape(Circle())
        }
    }
}

// Add DurationPicker if it's missing
struct DurationPicker: View {
    @Binding var duration: TimeInterval
    
    var body: some View {
        Picker("Duration", selection: $duration) {
            Text("None").tag(TimeInterval(0))
            Text("15 min").tag(TimeInterval(15 * 60))
            Text("30 min").tag(TimeInterval(30 * 60))
            Text("1 hour").tag(TimeInterval(60 * 60))
            Text("2 hours").tag(TimeInterval(120 * 60))
        }
    }
} 

