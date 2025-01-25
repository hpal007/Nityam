import SwiftUI

// MARK: - Shared Constants
struct HabitConstants {
    static let icons = [
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
    
    static let colors = [
        "red", "orange", "yellow", "green", "mint", "teal",
        "cyan", "blue", "indigo", "purple", "pink"
    ]
}

// MARK: - Shared Components
struct IconGridView: View {
    @Binding var selectedIcon: String
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
            ForEach(HabitConstants.icons, id: \.self) { icon in
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

struct WeekdaySelector: View {
    @Binding var selectedDays: Set<Habit.Weekday>
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Habit.Weekday.allCases, id: \.self) { day in
                    DayToggleButton(
                        day: day,
                        isSelected: selectedDays.contains(day),
                        themeColor: themeManager.primaryColor
                    ) {
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

struct DayToggleButton: View {
    let day: Habit.Weekday
    let isSelected: Bool
    let themeColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(day.shortName)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .frame(width: 40, height: 40)
                .background(isSelected ? themeColor : Color(.systemGray5))
                .clipShape(Circle())
        }
    }
}

struct DurationPicker: View {
    @Binding var duration: TimeInterval
    
    var body: some View {
        Stepper("Duration: \(Int(duration/60)) minutes",
                value: $duration,
                in: 0...120*60,
                step: 5*60)
    }
} 
