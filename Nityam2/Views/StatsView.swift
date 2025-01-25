import SwiftUI
import Charts

struct CompletionData: Identifiable, Equatable {
    let id: Date
    let date: Date
    let completed: Bool
    
    static func == (lhs: CompletionData, rhs: CompletionData) -> Bool {
        return lhs.date == rhs.date && lhs.completed == rhs.completed
    }
}

struct StatsView: View {
    let habit: Habit
    @StateObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    // Cache computed values
    private let calendar = Calendar.current
    @State private var cachedLast30DaysData: [CompletionData] = []
    @State private var cachedWeekdayStats: [(day: String, percentage: Double)] = []
    @State private var isLoading = true
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    // Stats Summary
                    StatsSummaryRow(habit: habit)
                        .padding(.top, 8)
                    
                    // Last 30 Days Chart
                    CompletionChartView(data: cachedLast30DaysData, themeColor: themeManager.primaryColor)
                        .frame(height: geometry.size.height * 0.3)
                    
                    // Weekly Pattern
                    WeeklyPatternView(stats: cachedWeekdayStats, themeColor: themeManager.primaryColor)
                }
                .padding(.horizontal)
            }
            .background(Color(.systemBackground))
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("\(habit.name) Statistics")
                    .font(.headline)
                    .foregroundColor(themeManager.primaryColor)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                updateCachedData()
                isLoading = false
            }
        }
        .onChange(of: habit.completionDates) { oldValue, newValue in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                updateCachedData()
            }
        }
    }
    
    private func updateCachedData() {
        let today = Date()
        cachedLast30DaysData = (0..<30).map { daysAgo -> CompletionData in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let wasCompleted = habit.completionDates.contains { calendar.isDate($0, inSameDayAs: date) }
            return CompletionData(id: date, date: date, completed: wasCompleted)
        }.reversed()
        
        var stats: [Int: (total: Int, completed: Int)] = [:]
        for weekday in 1...7 {
            stats[weekday] = (0, 0)
        }
        
        for date in habit.completionDates {
            let weekday = calendar.component(.weekday, from: date)
            let current = stats[weekday]!
            stats[weekday] = (current.total + 1, current.completed + 1)
        }
        
        cachedWeekdayStats = stats.sorted { $0.key < $1.key }.map { weekday, stat in
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
        HStack(spacing: 16) {
            StatBox(title: "Best Streak", value: "\(habit.bestStreak)")
            StatBox(title: "Current Streak", value: "\(habit.currentStreak)")
            StatBox(title: "Completions", value: "\(habit.completionDates.count)")
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(15)
    }
}

struct CompletionChartView: View {
    let data: [CompletionData]
    let themeColor: Color
    
    var body: some View {
        ChartSection(title: "Last 30 Days") {
            Chart(data) { item in
                BarMark(
                    x: .value("Date", item.date, unit: .day),
                    y: .value("Completed", item.completed ? 1 : 0)
                )
                .foregroundStyle(item.completed ? themeColor : Color(.tertiaryLabel))
                .annotation(position: .top) {
                    if item.completed {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(themeColor)
                            .imageScale(.small)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
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
            .chartYAxis(.hidden)
            .chartYScale(domain: 0...1)
            .animation(.spring(response: 0.5), value: data)
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
            .padding(.vertical, 8)
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
                .animation(.spring(response: 0.3), value: percentage)
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 4)
                    .fill(themeColor)
                    .frame(height: max((geo.size.height * percentage) / 100, 4))
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: percentage)
            }
            Text(day)
                .font(.caption2)
                .foregroundColor(Color(.secondaryLabel))
        }
        .frame(maxWidth: .infinity)
    }
}

struct StatBox: View {
    let title: String
    let value: String
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundColor(themeManager.primaryColor)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Text(title)
                .font(.caption2)
                .foregroundColor(Color(.secondaryLabel))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
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
                .padding(.horizontal, 8)
            
            content
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(15)
        }
    }
} 
