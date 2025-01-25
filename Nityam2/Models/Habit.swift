import Foundation
import SwiftData
import SwiftUI

// @Model is a SwiftData macro that marks this class as a persistent model
@Model
final class Habit {
    // MARK: - Properties
    
    // Unique identifier for each habit
    var id: UUID
    // Name of the habit (e.g., "Walk the dog")
    var name: String
    // SF Symbol name for the habit's icon
    var iconName: String
    // Name of the color to be used (maps to system colors)
    var colorName: String
    // Duration in minutes (optional, for timed habits)
    var targetDuration: TimeInterval
    // Tracks if the habit is completed for the current day
    var isCompleted: Bool
    // Array of dates when the habit was completed
    var completionDates: [Date]
    // Current streak of consecutive days completed
    var currentStreak: Int
    // Best streak ever achieved
    var bestStreak: Int
    // Last date when the habit was completed
    var lastCompletedDate: Date?
    // Type of habit (positive or negative)
    var type: HabitType
    // How often the habit should be performed
    var frequency: Frequency
    // Days of the week when the habit should be performed
    var taskDays: Set<Weekday>
    
    // MARK: - Computed Properties
    
    // Converts colorName string to SwiftUI Color
    var color: Color {
        switch colorName {
        case "red": return Color(.systemRed)
        case "orange": return Color(.systemOrange)
        case "yellow": return Color(.systemYellow)
        case "green": return Color(.systemGreen)
        case "mint": return Color(.systemMint)
        case "teal": return Color(.systemTeal)
        case "cyan": return Color(.systemCyan)
        case "blue": return Color(.systemBlue)
        case "indigo": return Color(.systemIndigo)
        case "purple": return Color(.systemPurple)
        case "pink": return Color(.systemPink)
        default: return Color(.systemRed)
        }
    }
    
    // MARK: - Enums
    
    // Defines the type of habit
    enum HabitType: String, Codable {
        case positive // habits to build (e.g., exercise)
        case negative // habits to break (e.g., smoking)
    }
    
    // Defines how often the habit should be performed
    enum Frequency: String, Codable {
        case daily   // Every day
        case weekly  // Specific days each week
        case custom  // Custom schedule
    }
    
    // Represents days of the week for scheduling
    enum Weekday: Int, Codable, CaseIterable {
        case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
        
        // Short name for display purposes
        var shortName: String {
            switch self {
            case .sunday: return "Sun"
            case .monday: return "Mon"
            case .tuesday: return "Tue"
            case .wednesday: return "Wed"
            case .thursday: return "Thu"
            case .friday: return "Fri"
            case .saturday: return "Sat"
            }
        }
    }
    
    // MARK: - Initialization
    
    // Creates a new habit with the specified properties
    init(name: String, 
         iconName: String, 
         colorName: String = "red", 
         targetDuration: TimeInterval = 0, 
         type: HabitType = .positive,
         frequency: Frequency = .daily, 
         taskDays: Set<Weekday> = Set(Weekday.allCases)) {
        self.id = UUID()
        self.name = name
        self.iconName = iconName
        self.colorName = colorName
        self.targetDuration = targetDuration
        self.isCompleted = false
        self.completionDates = []
        self.currentStreak = 0
        self.bestStreak = 0
        self.type = type
        self.frequency = frequency
        self.taskDays = taskDays
    }
    
    // MARK: - Methods
    
    /// Calculates the current streak of consecutive days
    /// Returns: Number of consecutive days the habit was completed
    func calculateStreak() -> Int {
        // If no completions, return 0
        guard !completionDates.isEmpty else { return 0 }
        
        var streak = 1
        let calendar = Calendar.current
        
        // Iterate through completion dates to find consecutive days
        for i in 1..<completionDates.count {
            let previous = calendar.startOfDay(for: completionDates[i-1])
            let current = calendar.startOfDay(for: completionDates[i])
            
            // Check if dates are consecutive
            if calendar.dateComponents([.day], from: previous, to: current).day == 1 {
                streak += 1
            } else {
                // Break streak if days are not consecutive
                break
            }
        }
        
        return streak
    }
} 