import SwiftUI

struct ThemeSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        NavigationView {
            List {
                ForEach(themeManager.themes, id: \.name) { theme in
                    ThemeRow(name: theme.name,
                            primaryColor: theme.primary,
                            backgroundColor: theme.background,
                            isSelected: theme.primary == themeManager.primaryColor)
                        .onTapGesture {
                            themeManager.applyTheme(primary: theme.primary,
                                                  background: theme.background)
                        }
                }
            }
            .navigationTitle("Choose Theme")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

struct ThemeRow: View {
    let name: String
    let primaryColor: Color
    let backgroundColor: Color
    let isSelected: Bool
    
    var body: some View {
        HStack {
            // Theme preview
            HStack(spacing: 12) {
                // Primary color circle
                Circle()
                    .fill(primaryColor)
                    .frame(width: 30, height: 30)
                
                // Background color preview
                RoundedRectangle(cornerRadius: 6)
                    .fill(backgroundColor)
                    .frame(width: 30, height: 30)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
            .padding(.trailing, 8)
            
            Text(name)
                .foregroundColor(.primary)
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(primaryColor)
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 8)
    }
}

#Preview {
    ThemeSettingsView()
} 