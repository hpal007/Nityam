import SwiftUI

struct AddHabitView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var iconName = "figure.walk"
    @State private var colorName = "blue"
    @State private var duration: TimeInterval = 0
    @State private var habitType: Habit.HabitType = .positive
    @State private var frequency: Habit.Frequency = .daily
    @State private var selectedDays: Set<Habit.Weekday> = Set(Habit.Weekday.allCases)
    
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
        "clock.fill", "alarm.fill", "calendar", "gift.fill",
        
        // Health Monitoring
        "waveform.path.ecg", "thermometer", "pills", "cross.case",
        "bandage.fill", "ear.fill", "eye.fill", "hand.raised.fill",
        
        // Habits to Break
        "nosign", "smoke.fill", "wineglass.fill", "bolt.slash.fill",
        "hand.thumbsdown.fill", "xmark.circle.fill", "trash.fill", "exclamationmark.triangle.fill",
        
        // Social & Communication
        "message.fill", "phone.fill", "video.fill", "person.2.fill",
        "heart.text.square.fill", "hand.wave.fill", "star.fill", "bell.fill"
    ]
    
    let colors = [
        "red", "orange", "yellow", "green", "mint", "teal",
        "cyan", "blue", "indigo", "purple", "pink"
    ]
    
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
                
                if frequency != .daily {
                    Section(header: Text("Task Days")) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(Habit.Weekday.allCases, id: \.rawValue) { day in
                                    DayToggleButton(day: day, isSelected: selectedDays.contains(day)) {
                                        if selectedDays.contains(day) {
                                            selectedDays.remove(day)
                                        } else {
                                            selectedDays.insert(day)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                Section(header: Text("Icon")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                        ForEach(icons, id: \.self) { icon in
                            Button(action: { iconName = icon }) {
                                Image(systemName: icon)
                                    .font(.system(size: 24))
                                    .foregroundColor(iconName == icon ? Color(colorName) : .primary)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(iconName == icon ? Color(colorName).opacity(0.2) : Color.clear)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("Color")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                        ForEach(colors, id: \.self) { color in
                            Circle()
                                .fill(Color(color))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: colorName == color ? 2 : 0)
                                )
                                .onTapGesture {
                                    colorName = color
                                }
                        }
                    }
                }
                
                if habitType == .positive {
                    Section(header: Text("Duration (Optional)")) {
                        Stepper("Duration: \(Int(duration/60)) minutes", 
                               value: $duration, 
                               in: 0...120*60, 
                               step: 5*60)
                    }
                }
            }
            .navigationTitle("Add New Habit")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    addHabit()
                    dismiss()
                }
                .disabled(name.isEmpty)
            )
        }
    }
    
    private func addHabit() {
        let habit = Habit(name: name,
                         iconName: iconName,
                         colorName: colorName,
                         targetDuration: duration,
                         type: habitType,
                         frequency: frequency,
                         taskDays: selectedDays)
        modelContext.insert(habit)
        try? modelContext.save()
    }
}

// Helper view for day selection
struct DayToggleButton: View {
    let day: Habit.Weekday
    let isSelected: Bool
    let action: () -> Void
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: action) {
            Text(day.shortName)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .frame(width: 40, height: 40)
                .background(isSelected ? themeManager.primaryColor : Color(.systemGray5))
                .clipShape(Circle())
        }
    }
} 