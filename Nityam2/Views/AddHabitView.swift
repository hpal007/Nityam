import SwiftUI

//struct AddHabitView: View {
//    var body: some View {
//        HabitFormView()
//    }
//}

//// New supporting views for custom scheduling
//struct DaysOfMonthSelector: View {
//    @Binding var selectedDays: Set<Int>
//    @StateObject private var themeManager = ThemeManager.shared
//    
//    var body: some View {
//        ScrollView(.horizontal, showsIndicators: false) {
//            HStack(spacing: 8) {
//                ForEach(1...31, id: \.self) { day in
//                    Button(action: {
//                        if selectedDays.contains(day) {
//                            selectedDays.remove(day)
//                        } else {
//                            selectedDays.insert(day)
//                        }
//                    }) {
//                        Text("\(day)")
//                            .font(.system(size: 14, weight: .medium))
//                            .foregroundColor(selectedDays.contains(day) ? .white : .primary)
//                            .frame(width: 36, height: 36)
//                            .background(selectedDays.contains(day) ? themeManager.primaryColor : Color(.systemGray5))
//                            .clipShape(Circle())
//                    }
//                }
//            }
//            .padding(.horizontal)
//        }
//    }
//}
