//
//  Nityam2App.swift
//  Nityam2
//
//  Created by Harishchandra Pal on 25/01/25.
//

import SwiftUI
import SwiftData

@main
struct Nityam2App: App {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    if newPhase == .active {
                        resetHabitsForNewDay()
                    }
                }
        }
        .modelContainer(for: Habit.self)
    }
    
    // Reset all habits when needed
    private func resetHabitsForNewDay() {
        do {
            let descriptor = FetchDescriptor<Habit>()
            let habits = try modelContext.fetch(descriptor)
            
            for habit in habits {
                habit.checkAndResetForNewDay()
            }
            
            try modelContext.save()
        } catch {
            print("Error resetting habits: \(error)")
        }
    }
}
