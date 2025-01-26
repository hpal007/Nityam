import SwiftUI
import SwiftData

struct StatsOverview: View {
    let habits: [Habit]
//    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                StatItem(title: "Total Habits", value: "\(habits.count)")
                StatItem(title: "Completed Today", value: "\(completedToday)")
                StatItem(title: "Best Streak", value: "\(bestStreak)")
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.tertiaryLabel))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.accentColor )
                        .frame(width: geometry.size.width * CGFloat(completionRate),
                               height: 8)
                }
            }
            .frame(height: 8)
            
            Text("\(Int(completionRate * 100))% Complete Today")
                .font(.caption)
                .foregroundColor(Color(.secondaryLabel))
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(15)
        .shadow(color: Color(.separator), radius: 2)
    }
    
    private var completedToday: Int {
        habits.filter { $0.isCompleted }.count
    }
    
    private var completionRate: Double {
        habits.isEmpty ? 0 : Double(completedToday) / Double(habits.count)
    }
    
    private var bestStreak: Int {
        habits.map { $0.bestStreak }.max() ?? 0
    }
}

struct StatItem: View {
    let title: String
    let value: String
//    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color.primary)
            Text(title)
                .font(.caption)
                .foregroundColor(Color(.secondaryLabel))
        }
    }
}
