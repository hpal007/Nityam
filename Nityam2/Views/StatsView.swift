import SwiftUI
import Charts

struct StatsView: View {
    let habit: Habit
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                StatsSummaryRow(habit: habit)
                    .padding(.top)
                
                CompletionChartView(data: last30DaysData, themeColor: themeManager.primaryColor)
                
                WeeklyPatternView(stats: weekdayStats, themeColor: themeManager.primaryColor)
            }
            .padding()
        }
        .navigationTitle("Statistics")
        .background(Color(.systemBackground))
    }
    
    // Helper computed properties
    private var last30DaysData: [(date: Date, completed: Bool)] {
        let calendar = Calendar.current
        let today = Date()
        return (0..<30).map { daysAgo -> (Date, Bool) in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let wasCompleted = habit.completionDates.contains { calendar.isDate($0, inSameDayAs: date) }
            return (date, wasCompleted)
        }.reversed()
    }
    
    private var weekdayStats: [(day: String, percentage: Double)] {
        let calendar = Calendar.current
        var stats: [Int: (total: Int, completed: Int)] = [:]
        
        // Initialize counters for each weekday
        for weekday in 1...7 {
            stats[weekday] = (0, 0)
        }
        
        // Calculate completion rates
        for date in habit.completionDates {
            let weekday = calendar.component(.weekday, from: date)
            let current = stats[weekday]!
            stats[weekday] = (current.total + 1, current.completed + 1)
        }
        
        // Convert to percentages
        return stats.sorted { $0.key < $1.key }.map { weekday, stat in
            let percentage = stat.total > 0 ? Double(stat.completed) / Double(stat.total) * 100 : 0
            let dayName = calendar.shortWeekdaySymbols[weekday - 1]
            return (dayName, percentage)
        }
    }
}

// MARK: - Supporting Views

struct StatsSummaryRow: View {
    let habit: Habit
    
    var body: some View {
        HStack(spacing: 30) {
            StatBox(title: "Best Streak", value: "\(habit.bestStreak)")
            StatBox(title: "Current Streak", value: "\(habit.currentStreak)")
            StatBox(title: "Completions", value: "\(habit.completionDates.count)")
        }
    }
}

struct CompletionChartView: View {
    let data: [(date: Date, completed: Bool)]
    let themeColor: Color
    
    var body: some View {
        ChartSection(title: "Last 30 Days") {
            Chart(data, id: \.date) { item in
                BarMark(
                    x: .value("Date", item.date, unit: .day),
                    y: .value("Completed", item.completed ? 1 : 0)
                )
                .foregroundStyle(item.completed ? themeColor : Color(.tertiaryLabel))
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                    AxisGridLine()
                        .foregroundStyle(Color(.separator))
                    AxisTick()
                        .foregroundStyle(Color(.separator))
                    AxisValueLabel(format: .dateTime.day())
                        .foregroundStyle(Color(.secondaryLabel))
                }
            }
        }
    }
}

struct WeeklyPatternView: View {
    let stats: [(day: String, percentage: Double)]
    let themeColor: Color
    
    var body: some View {
        ChartSection(title: "Weekly Pattern") {
            HStack(spacing: 12) {
                ForEach(stats, id: \.day) { stat in
                    WeekdayBar(day: stat.day, percentage: stat.percentage, themeColor: themeColor)
                }
            }
        }
    }
}

struct WeekdayBar: View {
    let day: String
    let percentage: Double
    let themeColor: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text("\(Int(percentage))%")
                .font(.caption)
                .foregroundColor(Color(.secondaryLabel))
            RoundedRectangle(cornerRadius: 4)
                .fill(themeColor)
                .frame(height: percentage * 1.2)
            Text(day)
                .font(.caption2)
                .foregroundColor(Color(.secondaryLabel))
        }
    }
}

struct StatBox: View {
    let title: String
    let value: String
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack {
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(themeManager.primaryColor)
            Text(title)
                .font(.caption)
                .foregroundColor(Color(.secondaryLabel))
        }
    }
}

struct ChartSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(Color(.label))
            
            content
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(15)
                .shadow(color: Color(.separator), radius: 2)
        }
    }
} 
