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
    var taskDays: Set<Weekday>   // Specific days when the habit should be performed (for weekly)
    var customSchedule: CustomSchedule? // Advanced scheduling options for custom frequency
    
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
        case custom  // Custom schedule (monthly, yearly patterns)
    }
    
    // Custom scheduling options
    enum CustomScheduleType: String, Codable {
        case daysOfMonth    // Specific days of the month (1-31)
        case intervalDays   // Every X days
    }
    
    // Structure to hold custom scheduling information
    struct CustomSchedule: Codable {
        var type: CustomScheduleType
        var values: [Int]    // Days of month (1-31)
        var interval: Int?   // For intervalDays type
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
         targetDuration: TimeInterval = 0, 
         type: HabitType = .positive,
         frequency: Frequency = .daily, 
         taskDays: Set<Weekday> = Set(Weekday.allCases),
         customSchedule: CustomSchedule? = nil) {
        self.id = UUID()
        self.name = name
        self.iconName = iconName
        self.targetDuration = targetDuration
        self.isCompleted = false
        self.completionDates = []
        self.currentStreak = 0
        self.bestStreak = 0
        self.type = type
        self.frequency = frequency
        self.taskDays = taskDays
        self.customSchedule = customSchedule
    }
    
    // MARK: - Methods
    
    /// Checks if the given date is a task day for this habit
    func isTaskDay(for date: Date = Date()) -> Bool {
        let calendar = Calendar.current
        
        switch frequency {
        case .daily:
            return true
            
        case .weekly:
            let weekday = Weekday(rawValue: calendar.component(.weekday, from: date)) ?? .sunday
            return taskDays.contains(weekday)
            
        case .custom:
            guard let schedule = customSchedule else { return false }
            
            switch schedule.type {
            case .daysOfMonth:
                let dayOfMonth = calendar.component(.day, from: date)
                return schedule.values.contains(dayOfMonth)
                
            case .intervalDays:
                guard let interval = schedule.interval else { return false }
                let startOfDay = calendar.startOfDay(for: date)
                let daysSinceEpoch = calendar.dateComponents([.day], from: Date(timeIntervalSince1970: 0), to: startOfDay).day ?? 0
                return daysSinceEpoch % interval == 0
            }
        }
    }
    
    /// Calculates the current streak of consecutive task days
    /// Returns: Number of consecutive task days the habit was completed
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
        
        // For the streak to be active, the last completion must be on the most recent task day
        var currentDate = today
        while !isTaskDay(for: currentDate) {
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
            currentDate = previousDay
        }
        
        guard let mostRecent = sortedDates.first,
              mostRecent >= currentDate else {
            return 0
        }
        
        var streak = 1
        var dateToCheck = mostRecent
        
        // Count back through dates, only counting task days
        while let previousDate = calendar.date(byAdding: .day, value: -1, to: dateToCheck) {
            // If this is not a task day, skip to next date without breaking streak
            if !isTaskDay(for: previousDate) {
                dateToCheck = previousDate
                continue
            }
            
            // Check if this task day was completed
            if sortedDates.contains(previousDate) {
                streak += 1
                dateToCheck = previousDate
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
