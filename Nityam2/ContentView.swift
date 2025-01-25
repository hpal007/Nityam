//
//  ContentView.swift
//  Nityam2
//
//  Created by Harishchandra Pal on 25/01/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var habits: [Habit]
    @State private var showingAddHabit = false
    @State private var showingThemeSettings = false
    @State private var showingStats = false
    @StateObject private var themeManager = ThemeManager.shared
    
    // Grid layout
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("My Habits")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.primary)
                        Text("Track your daily progress")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    // Stats Overview
                    StatsOverview(habits: habits)
                        .padding(.horizontal)
                    
                    // Habits Grid
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(habits) { habit in
                            HabitView(habit: habit)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: ThemeSettingsView()) {
                        Image(systemName: "paintpalette.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(themeManager.primaryColor)
                            .frame(width: 44, height: 44) // Apple's minimum touch target size
                            .contentShape(Rectangle()) // Makes entire frame tappable
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: Color(.systemGray4).opacity(0.3), radius: 4, x: 0, y: 2)
                            )
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink(destination: AddHabitView()) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(themeManager.primaryColor)
                            .frame(width: 44, height: 44) // Apple's minimum touch target size
                            .contentShape(Rectangle()) // Makes entire frame tappable
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Habit.self, inMemory: true)
}
