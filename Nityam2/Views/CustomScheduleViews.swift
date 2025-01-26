import SwiftUI

struct MonthDaySelector: View {
    @Binding var selectedDays: Set<Int>
//    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(1...31, id: \.self) { day in
                    Button(action: {
                        if selectedDays.contains(day) {
                            selectedDays.remove(day)
                        } else {
                            selectedDays.insert(day)
                        }
                    }) {
                        Text("\(day)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(selectedDays.contains(day) ? .white : .primary)
                            .frame(width: 36, height: 36)
                            .background(selectedDays.contains(day) ? Color.accentColor  : Color(.systemGray5))
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct WeekOrdinalPicker: View {
    @Binding var ordinal: Int
    
    var body: some View {
        Picker("Week", selection: $ordinal) {
            Text("First").tag(1)
            Text("Second").tag(2)
            Text("Third").tag(3)
            Text("Fourth").tag(4)
            Text("Last").tag(-1)
        }
    }
}

struct DatesInYearSelector: View {
    @Binding var selectedDates: Set<Int>
//    @StateObject private var themeManager = ThemeManager.shared
    let calendar = Calendar.current
    
    var body: some View {
        List {
            ForEach(1...12, id: \.self) { month in
                Section(header: Text(calendar.monthSymbols[month - 1])) {
                    let daysInMonth = calendar.range(of: .day, in: .month, for: calendar.date(from: DateComponents(month: month))!)!.count
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
                        ForEach(1...daysInMonth, id: \.self) { day in
                            let dateValue = month * 100 + day
                            Button(action: {
                                if selectedDates.contains(dateValue) {
                                    selectedDates.remove(dateValue)
                                } else {
                                    selectedDates.insert(dateValue)
                                }
                            }) {
                                Text("\(day)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(selectedDates.contains(dateValue) ? .white : .primary)
                                    .frame(width: 32, height: 32)
                                    .background(selectedDates.contains(dateValue) ? Color.accentColor : Color(.systemGray5))
                                    .clipShape(Circle())
                            }
                        }
                    }
                }
            }
        }
    }
} 
