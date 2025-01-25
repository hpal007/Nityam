import SwiftUI
import SwiftData
import Charts

struct HabitStatsView: View {
    @Query private var habits: [Habit]
    @StateObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Individual Habit Stats
                ForEach(habits) { habit in
                    NavigationLink(destination: StatsView(habit: habit)) {
                        HabitStatCard(habit: habit)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Habit Statistics")
        .navigationBarItems(trailing: Button("Done") { dismiss() })
        .background(themeManager.backgroundColor.ignoresSafeArea())
    }
}

struct HabitStatCard: View {
    let habit: Habit
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: habit.iconName)
                    .font(.title2)
                    .foregroundColor(themeManager.primaryColor)
                Text(habit.name)
                    .font(.headline)
                Spacer()
                Text("\(habit.currentStreak) 🔥")
                    .font(.subheadline)
                    .foregroundColor(Color(.systemGray))
            }
            
            // Completion rate
            HStack {
                Text("Completion Rate:")
                    .font(.subheadline)
                    .foregroundColor(Color(.systemGray))
                Text("\(Int(calculateCompletionRate() * 100))%")
                    .font(.subheadline)
                    .foregroundColor(themeManager.primaryColor)
            }
            
            // Mini progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray4))
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(themeManager.primaryColor)
                        .frame(width: geometry.size.width * calculateCompletionRate(),
                               height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 2)
    }
    
    private func calculateCompletionRate() -> Double {
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date())!
        let recentCompletions = habit.completionDates.filter { $0 >= thirtyDaysAgo }
        return Double(recentCompletions.count) / 30.0
    }
} 