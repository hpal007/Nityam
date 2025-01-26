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
//    @StateObject private var themeManager = ThemeManager.shared
    
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
                    HStack{
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Habits")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(.primary)
                            Text("Track your daily progress")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        
                        NavigationLink(destination: AddHabitView()) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 30, weight: .medium))
                                    .foregroundColor(Color.primary)
                                    .frame(width: 44, height: 44)
                                    .contentShape(Rectangle())
                        }.padding(.bottom)
                        
                        
                        
                    }

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
//                ToolbarItem(placement: .topBarTrailing) {
//                    Menu {
//                        ForEach(themeManager.themes, id: \.name) { theme in
//                            Button(action: {
//                                withAnimation(.spring(response: 0.3)) {
//                                    themeManager.applyTheme(primary: theme.primary, background: theme.background)
//                                }
//                            }) {
//                                HStack {
//                                    Circle()
//                                        .fill(theme.primary)
//                                        .frame(width: 20, height: 20)
//                                    Text(theme.name)
//                                    if theme.primary == themeManager.primaryColor {
//                                        Image(systemName: "checkmark")
//                                    }
//                                }
//                            }
//                        }
//                    } label: {
//                        Image(systemName: "paintpalette.fill")
//                            .font(.system(size: 20, weight: .medium))
//                            .foregroundColor(themeManager.primaryColor)
//                            .frame(width: 44, height: 44)
//                            .contentShape(Rectangle())
//                    }
//                }
//                ToolbarItem(placement: .topBarLeading) {
//                    Text("Hello, Harish").font(.largeTitle)
//                }
                
//                ToolbarItem(placement: .topBarTrailing) {
//                    NavigationLink(destination: AddHabitView()) {
//                        Image(systemName: "plus.circle.fill")
//                            .font(.system(size: 20, weight: .medium))
//                            .foregroundColor(Color.primary)
//                            .frame(width: 44, height: 44)
//                            .contentShape(Rectangle())
//                    }
//                }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Habit.self, inMemory: true)
}
