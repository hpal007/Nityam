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
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Habit.self)
    }
}
