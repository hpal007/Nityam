import SwiftUI
import Charts

struct CompletionData: Identifiable, Equatable {
    let id: Date
    let date: Date
    let completed: Bool
    let isTaskDay: Bool
    
    static func == (lhs: CompletionData, rhs: CompletionData) -> Bool {
        return lhs.date == rhs.date && lhs.completed == rhs.completed && lhs.isTaskDay == rhs.isTaskDay
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
    @State private var selectedMonth: Date = Date()
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    // Stats Summary
                    StatsSummaryRow(habit: habit)
                        .padding(.top, 8)
                    
                    // Last 30 Days Chart
                    CompletionChartView(
                        data: cachedLast30DaysData,
                        themeColor: themeManager.primaryColor,
                        frequency: habit.frequency
                    )
                    .frame(height: geometry.size.height * 0.4)
                    
                    // Weekly Pattern (show only for daily and weekly habits)
                    if habit.frequency != .custom {
                        WeeklyPatternView(stats: cachedWeekdayStats, themeColor: themeManager.primaryColor)
                    }
                    
                    // Calendar View
                    CalendarView(
                        habit: habit,
                        selectedMonth: $selectedMonth,
                        themeColor: themeManager.primaryColor
                    )
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
        
        // For last 30 days
        cachedLast30DaysData = (0..<30).map { daysAgo -> CompletionData in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let isTaskDay = habit.isTaskDay(for: date)
            let wasCompleted = isTaskDay && 
                habit.completionDates.contains { calendar.isDate($0, inSameDayAs: date) }
            return CompletionData(
                id: date,
                date: date,
                completed: wasCompleted,
                isTaskDay: isTaskDay
            )
        }.reversed()
        
        // Weekly pattern stats
        if habit.frequency != .custom {
            let last90Days = (0..<90).compactMap { daysAgo in
                calendar.date(byAdding: .day, value: -daysAgo, to: today)
            }
            
            var stats: [Int: (total: Int, completed: Int)] = [:]
            for weekday in 1...7 {
                stats[weekday] = (0, 0)
            }
            
            for date in last90Days {
                let weekday = calendar.component(.weekday, from: date)
                if habit.isTaskDay(for: date) {
                    let wasCompleted = habit.completionDates.contains { 
                        calendar.isDate($0, inSameDayAs: date)
                    }
                    let current = stats[weekday]!
                    stats[weekday] = (
                        current.total + 1,
                        current.completed + (wasCompleted ? 1 : 0)
                    )
                }
            }
            
            cachedWeekdayStats = stats.sorted { $0.key < $1.key }.map { weekday, stat in
                let percentage = stat.total > 0 ? Double(stat.completed) / Double(stat.total) * 100 : 0
                let dayName = calendar.shortWeekdaySymbols[weekday - 1]
                return (dayName, percentage)
            }
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
    let frequency: Habit.Frequency
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"  // Only show day number
        return formatter
    }()
    
    var body: some View {
        ChartSection(title: "Last 30 Days") {
            VStack(alignment: .leading, spacing: 8) {
                Chart {
                    ForEach(data) { item in
                        if item.isTaskDay {
                            LineMark(
                                x: .value("Date", item.date, unit: .day),
                                y: .value("Completed", item.completed ? 1 : 0)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(themeColor.opacity(0.8))
                            
                            AreaMark(
                                x: .value("Date", item.date, unit: .day),
                                y: .value("Completed", item.completed ? 1 : 0)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(themeColor.opacity(0.1))
                            
                            if item.completed {
                                PointMark(
                                    x: .value("Date", item.date, unit: .day),
                                    y: .value("Completed", 1)
                                )
                                .foregroundStyle(themeColor)
                                .symbolSize(30)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 2)) { value in
                        if let date = value.as(Date.self) {
                            AxisGridLine()
                                .foregroundStyle(Color(.separator))
                            AxisTick()
                                .foregroundStyle(Color(.separator))
                            AxisValueLabel {
                                Text(dateFormatter.string(from: date))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .chartYAxis(.hidden)
                .chartYScale(domain: -0.1...1.1)
                .frame(height: 200)
                
                // Legend
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(themeColor)
                            .frame(width: 8, height: 8)
                        Text("Completed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(.tertiaryLabel))
                            .frame(width: 8, height: 8)
                        Text("Task Days")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

struct FrequencyStatsView: View {
    let habit: Habit
    let themeColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Frequency Details")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                switch habit.frequency {
                case .daily:
                    Text("Daily Habit")
                        .foregroundColor(.secondary)
                case .weekly:
                    Text("Weekly Schedule:")
                        .foregroundColor(.secondary)
                    HStack {
                        ForEach(Array(habit.taskDays).sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) {
                            Text($0.shortName)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(themeColor.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                case .custom:
                    if let schedule = habit.customSchedule {
                        switch schedule.type {
                        case .daysOfMonth:
                            Text("Monthly Schedule:")
                                .foregroundColor(.secondary)
                            Text("Days: \(schedule.values.sorted().map(String.init).joined(separator: ", "))")
                        case .intervalDays:
                            if let interval = schedule.interval {
                                Text("Interval: Every \(interval) days")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(15)
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

// Add new CalendarView
struct CalendarView: View {
    let habit: Habit
    @Binding var selectedMonth: Date
    let themeColor: Color
    private let calendar = Calendar.current
    private let daysInWeek = ["S", "M", "T", "W", "T", "F", "S"]
    
    init(habit: Habit, selectedMonth: Binding<Date>, themeColor: Color) {
        self.habit = habit
        self._selectedMonth = selectedMonth
        self.themeColor = themeColor
    }
    
    // Get the start of the habit's creation date
    private var habitStartDate: Date {
        // If we have completion dates, use the earliest one, otherwise use today
        if let firstCompletion = habit.completionDates.min() {
            return calendar.startOfDay(for: firstCompletion)
        }
        return calendar.startOfDay(for: Date())
    }
    
    private var monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    var body: some View {
        ChartSection(title: "Calendar") {
            VStack(spacing: 16) {
                // Month selector
                HStack {
                    Button(action: previousMonth) {
                        Image(systemName: "chevron.left")
                            .imageScale(.large)
                            .foregroundColor(canGoToPreviousMonth ? themeColor : Color.gray.opacity(0.5))
                            .frame(width: 44, height: 44)
                    }
                    .disabled(!canGoToPreviousMonth)
                    
                    Spacer()
                    Text(monthFormatter.string(from: selectedMonth))
                        .font(.headline)
                    Spacer()
                    
                    Button(action: nextMonth) {
                        Image(systemName: "chevron.right")
                            .imageScale(.large)
                            .foregroundColor(themeColor)
                            .frame(width: 44, height: 44)
                    }
                }
                
                // Day headers
                HStack(spacing: 0) {
                    ForEach(daysInWeek, id: \.self) { day in
                        Text(day)
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Calendar grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                    ForEach(daysInMonth, id: \.self) { date in
                        if let date = date {
                            DayCell(
                                date: date,
                                isSelected: calendar.isDate(date, inSameDayAs: selectedMonth),
                                isTaskDay: isDateAfterHabitStart(date) ? habit.isTaskDay(for: date) : false,
                                isCompleted: isDateAfterHabitStart(date) ? isDateCompleted(date) : false,
                                isEnabled: isDateAfterHabitStart(date),
                                themeColor: themeColor
                            )
                            .frame(height: 44)
                        } else {
                            Color.clear
                                .frame(height: 44)
                        }
                    }
                }
                
                // Legend
                HStack(spacing: 20) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(themeColor)
                        Text("Completed")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "x.circle.fill")
                            .foregroundColor(.red)
                        Text("Missed")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 8)
            }
        }
    }
    
    private var canGoToPreviousMonth: Bool {
        let startOfCurrentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth))!
        return startOfCurrentMonth > habitStartDate
    }
    
    private func isDateAfterHabitStart(_ date: Date) -> Bool {
        return date >= habitStartDate
    }
    
    private var daysInMonth: [Date?] {
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth))!
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let daysInMonth = calendar.range(of: .day, in: .month, for: selectedMonth)!.count
        
        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)
        
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }
        
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
    
    private func isDateCompleted(_ date: Date) -> Bool {
        habit.completionDates.contains { calendar.isDate($0, inSameDayAs: date) }
    }
    
    private func previousMonth() {
        withAnimation {
            if canGoToPreviousMonth,
               let newDate = calendar.date(byAdding: .month, value: -1, to: selectedMonth) {
                selectedMonth = newDate
            }
        }
    }
    
    private func nextMonth() {
        withAnimation {
            if let newDate = calendar.date(byAdding: .month, value: 1, to: selectedMonth) {
                selectedMonth = newDate
            }
        }
    }
}

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isTaskDay: Bool
    let isCompleted: Bool
    let isEnabled: Bool
    let themeColor: Color
    
    private let calendar = Calendar.current
    
    init(date: Date, isSelected: Bool, isTaskDay: Bool, isCompleted: Bool, isEnabled: Bool, themeColor: Color) {
        self.date = date
        self.isSelected = isSelected
        self.isTaskDay = isTaskDay
        self.isCompleted = isCompleted
        self.isEnabled = isEnabled
        self.themeColor = themeColor
    }
    
    private var isPastDate: Bool {
        date < calendar.startOfDay(for: Date())
    }
    
    var body: some View {
        ZStack {
            // Background
            Circle()
                .fill(backgroundColor)
            
            VStack(spacing: 2) {
                // Date number
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(.body, design: .rounded))
                    .fontWeight(isTaskDay ? .semibold : .regular)
                    .foregroundColor(foregroundColor)
                
                // Status indicator
                if isEnabled && isTaskDay {
                    if isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(themeColor)
                    } else if isPastDate {
                        Image(systemName: "x.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .opacity(isEnabled ? 1 : 0.3)
            
            // Selection border
            if isSelected && isEnabled {
                Circle()
                    .strokeBorder(themeColor, lineWidth: 2)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
    
    private var backgroundColor: Color {
        if !isEnabled || !isTaskDay {
            return .clear
        }
        if isCompleted {
            return themeColor.opacity(0.1)
        }
        return isPastDate ? Color.red.opacity(0.1) : .clear
    }
    
    private var foregroundColor: Color {
        if !isEnabled {
            return .secondary.opacity(0.3)
        }
        if !isTaskDay {
            return .secondary.opacity(0.5)
        }
        return .primary
    }
} 
