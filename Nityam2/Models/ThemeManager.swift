import SwiftUI

// MARK: - Theme Management
/// Manages app-wide theme settings using UserDefaults for persistence
class ThemeManager: ObservableObject {
    // MARK: - Persisted Properties
    // These properties are automatically saved to UserDefaults when changed
    @Published var primaryColor: Color {
        didSet {
            UserDefaults.standard.setColor(primaryColor, forKey: "primaryColor")
        }
    }
    
    @Published var backgroundColor: Color {
        didSet {
            UserDefaults.standard.setColor(backgroundColor, forKey: "backgroundColor")
        }
    }
    
    // MARK: - Singleton Instance
    static let shared = ThemeManager()
    
    // MARK: - Theme Presets
    let themes: [(name: String, primary: Color, background: Color)] = [
        ("Warm Sand", Color("#FCE7C8"), Color.white),
        ("Sage", Color("#B1C29E"), Color.white),
        ("Golden", Color("#FADA7A"), Color.white),
        ("Sunset", Color("#F0A04B"), Color.white)
    ]
    
    // MARK: - Initialization
    private init() {
        // Load saved colors from UserDefaults or use default theme
        let savedColor = UserDefaults.standard.color(forKey: "primaryColor")
        let savedBackground = UserDefaults.standard.color(forKey: "backgroundColor")
        
        if let primary = savedColor, let background = savedBackground {
            self.primaryColor = primary
            self.backgroundColor = background
        } else {
            self.primaryColor = themes[0].primary
            self.backgroundColor = themes[0].background
        }
    }
    
    // MARK: - Theme Application
    func applyTheme(primary: Color, background: Color) {
        withAnimation {
            primaryColor = primary
            backgroundColor = background
        }
    }
}

// MARK: - UserDefaults Color Extension
/// Enables storing SwiftUI Color values in UserDefaults
extension UserDefaults {
    func setColor(_ color: Color, forKey key: String) {
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let dict = ["red": red, "green": green, "blue": blue, "alpha": alpha]
        set(dict, forKey: key)
    }
    
    func color(forKey key: String) -> Color? {
        guard let dict = object(forKey: key) as? [String: CGFloat] else { return nil }
        return Color(.sRGB,
                    red: dict["red"] ?? 0,
                    green: dict["green"] ?? 0,
                    blue: dict["blue"] ?? 0,
                    opacity: dict["alpha"] ?? 1)
    }
}

extension Color {
    init(_ hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 