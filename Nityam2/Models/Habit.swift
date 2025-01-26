import Foundation
import SwiftData
import SwiftUI

// MARK: - SwiftData Model
@Model // This macro marks the class for SwiftData persistence
final class Habit {
    // MARK: - Core Properties
    var id: UUID                    // Unique identifier for the habit
    var name: String                // Display name of the habit
    var iconName: String            // SF Symbol name for visual representation
    var targetDuration: TimeInterval // Optional duration in minutes for timed habits
    var isCompleted: Bool           // Tracks today's completion status
    
    // MARK: - Progress Tracking
    @Attribute(.externalStorage)    // Stores large arrays externally for better performance
    var completionDates: [Date]     // History of all completion dates
    var currentStreak: Int          // Current consecutive days streak
    var bestStreak: Int            // Highest streak ever achieved
    var lastCompletedDate: Date?   // Most recent completion date
    
    // MARK: - Scheduling
    var type: HabitType           // Positive (to build) or negative (to break) habit
    var frequency: Frequency      // How often the habit should be performed
    var taskDays: Set<Weekday>   // Specific days when the habit should be performed
    
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
//         colorName: String = "red", 
         targetDuration: TimeInterval = 0, 
         type: HabitType = .positive,
         frequency: Frequency = .daily, 
         taskDays: Set<Weekday> = Set(Weekday.allCases)) {
        self.id = UUID()
        self.name = name
        self.iconName = iconName
//        self.colorName = colorName
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
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Sort dates in descending order (most recent first)
        let sortedDates = completionDates
            .map { calendar.startOfDay(for: $0) }
            .sorted(by: >)
            .uniqued() // Remove duplicate dates
        
        // If the most recent completion is not from today or yesterday, streak is broken
        guard let mostRecent = sortedDates.first,
              let dayDifference = calendar.dateComponents([.day], from: mostRecent, to: today).day,
              dayDifference <= 1 else {
            return 0
        }
        
        var streak = 1
        var previousDate = sortedDates[0]
        
        // Count consecutive days from most recent
        for date in sortedDates.dropFirst() {
            let daysBetween = calendar.dateComponents([.day], from: date, to: previousDate).day
            
            if daysBetween == 1 {
                streak += 1
                previousDate = date
            } else {
                break
            }
        }
        
        return streak
    }
}

// MARK: - Date Array Transformer
class DateArrayTransformer: ValueTransformer {
    static let name = NSValueTransformerName("DateArrayTransformer")
    
    static func register() {
        let transformer = DateArrayTransformer()
        ValueTransformer.setValueTransformer(transformer, forName: name)
    }
    
    override static func transformedValueClass() -> AnyClass {
        NSArray.self
    }
    
    override static func allowsReverseTransformation() -> Bool {
        true
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let dates = value as? [Date] else { return nil }
        return try? JSONEncoder().encode(dates)
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        return try? JSONDecoder().decode([Date].self, from: data)
    }
}

// Extension to remove duplicate dates
extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
} 
