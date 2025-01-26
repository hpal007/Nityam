import SwiftUI

struct HabitFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
//    @StateObject private var themeManager = ThemeManager.shared
//    
    // Mode of operation
    private let isEditing: Bool
    private let existingHabit: Habit?
    
    // Form state
    @State private var name: String = ""
    @State private var iconName: String = "figure.walk"
    @State private var duration: TimeInterval = 0
    @State private var habitType: Habit.HabitType = .positive
    @State private var frequency: Habit.Frequency = .daily
    @State private var selectedDays: Set<Habit.Weekday> = Set(Habit.Weekday.allCases)
    @State private var customScheduleType: Habit.CustomScheduleType = .daysOfMonth
    @State private var selectedDaysOfMonth: Set<Int> = []
    @State private var intervalDays: Int = 1
    
    init(habit: Habit? = nil) {
        self.isEditing = habit != nil
        self.existingHabit = habit
        
        if let habit = habit {
            // Editing mode - initialize with existing habit values
            _name = State(initialValue: habit.name)
            _iconName = State(initialValue: habit.iconName)
            _duration = State(initialValue: habit.targetDuration)
            _habitType = State(initialValue: habit.type)
            _frequency = State(initialValue: habit.frequency)
            _selectedDays = State(initialValue: habit.taskDays)
            
            if let customSchedule = habit.customSchedule {
                _customScheduleType = State(initialValue: customSchedule.type)
                
                switch customSchedule.type {
                case .daysOfMonth:
                    _selectedDaysOfMonth = State(initialValue: Set(customSchedule.values))
                case .intervalDays:
                    _intervalDays = State(initialValue: customSchedule.interval ?? 1)
                    _selectedDaysOfMonth = State(initialValue: [])
                }
            } else {
                _customScheduleType = State(initialValue: .daysOfMonth)
                _selectedDaysOfMonth = State(initialValue: [])
                _intervalDays = State(initialValue: 1)
            }
        }
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
                
                if frequency == .weekly {
                    Section(header: Text("Task Days")) {
                        WeekdaySelector(selectedDays: $selectedDays)
                    }
                }
                
                if frequency == .custom {
                    Section(header: Text("Custom Schedule")) {
                        Picker("Schedule Type", selection: $customScheduleType) {
                            Text("Days of Month").tag(Habit.CustomScheduleType.daysOfMonth)
                            Text("Every X Days").tag(Habit.CustomScheduleType.intervalDays)
                        }
                        
                        switch customScheduleType {
                        case .daysOfMonth:
                            MonthDaySelector(selectedDays: $selectedDaysOfMonth)
                            
                        case .intervalDays:
                            Stepper("Every \(intervalDays) days", value: $intervalDays, in: 1...365)
                        }
                    }
                }
                
                Section(header: Text("Icon")) {
                    IconGridView(selectedIcon: $iconName)
                }
                
                if habitType == .positive {
                    Section(header: Text("Duration (Optional)")) {
                        DurationPicker(duration: $duration)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Habit" : "Add New Habit")
            .navigationBarItems(
                trailing: Button("Save") {
                    saveHabit()
                    dismiss()
                }
                .disabled(name.isEmpty || !isValidSchedule)
            )
        }
    }
    
    private var isValidSchedule: Bool {
        switch frequency {
        case .daily:
            return true
        case .weekly:
            return !selectedDays.isEmpty
        case .custom:
            switch customScheduleType {
            case .daysOfMonth:
                return !selectedDaysOfMonth.isEmpty
            case .intervalDays:
                return intervalDays > 0
            }
        }
    }
    
    private func saveHabit() {
        let habit = existingHabit ?? Habit(
            name: name,
            iconName: iconName,
            targetDuration: duration,
            type: habitType,
            frequency: frequency,
            taskDays: selectedDays
        )
        
        // Update existing habit properties
        if isEditing {
            habit.name = name
            habit.iconName = iconName
            habit.targetDuration = duration
            habit.type = habitType
            habit.frequency = frequency
            habit.taskDays = selectedDays
        }
        
        // Set custom schedule if needed
        if frequency == .custom {
            var customSchedule: Habit.CustomSchedule
            
            switch customScheduleType {
            case .daysOfMonth:
                customSchedule = Habit.CustomSchedule(
                    type: .daysOfMonth,
                    values: Array(selectedDaysOfMonth),
                    interval: nil
                )
            case .intervalDays:
                customSchedule = Habit.CustomSchedule(
                    type: .intervalDays,
                    values: [],
                    interval: intervalDays
                )
            }
            
            habit.customSchedule = customSchedule
        } else {
            habit.customSchedule = nil
        }
        
        // Save to storage
        if !isEditing {
            modelContext.insert(habit)
        }
        try? modelContext.save()
    }
}

#Preview {
    HabitFormView()
        .modelContainer(for: Habit.self)
} 
