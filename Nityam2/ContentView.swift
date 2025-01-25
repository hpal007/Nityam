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
                Text("Habits").font(.largeTitle).font(.title)
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(habits) { habit in
                        HabitView(habit: habit)
                    }
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement:.topBarTrailing) {
                    Menu {
                        Button(action: { showingAddHabit = true }) {
                            Label("Add Habit", systemImage: "plus")
                        }
                        Button(action: { showingStats = true }) {
                            Label("View Stats", systemImage: "chart.bar")
                        }
                        Button(action: { showingThemeSettings = true }) {
                            Label("Theme Settings", systemImage: "paintpalette")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(themeManager.primaryColor)
                    }
                }
            }
            .sheet(isPresented: $showingAddHabit) {
                AddHabitView()
            }
            .sheet(isPresented: $showingThemeSettings) {
                ThemeSettingsView()
            }
            .sheet(isPresented: $showingStats) {
                NavigationView {
                    HabitStatsView()
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Habit.self, inMemory: true)
}
