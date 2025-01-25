import SwiftUI

/// Manages app-wide theme settings
class ThemeManager: ObservableObject {
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
    
    static let shared = ThemeManager()
    
    // Curated themes with carefully selected color combinations for both light and dark modes
    let themes: [(name: String, primary: Color, background: Color)] = [
        ("Modern Blue", 
         Color(uiColor: UIColor { traitCollection in
             traitCollection.userInterfaceStyle == .dark ?
             UIColor(red: 0.40, green: 0.60, blue: 1.0, alpha: 1.0) :
             UIColor(red: 0.20, green: 0.47, blue: 0.91, alpha: 1.0)
         }),
         Color(uiColor: UIColor { traitCollection in
             traitCollection.userInterfaceStyle == .dark ?
             UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0) :
             UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0)
         })),
        
        ("Mint Fresh", 
         Color(uiColor: UIColor { traitCollection in
             traitCollection.userInterfaceStyle == .dark ?
             UIColor(red: 0.37, green: 0.78, blue: 0.59, alpha: 1.0) :
             UIColor(red: 0.27, green: 0.68, blue: 0.49, alpha: 1.0)
         }),
         Color(uiColor: UIColor { traitCollection in
             traitCollection.userInterfaceStyle == .dark ?
             UIColor(red: 0.11, green: 0.12, blue: 0.11, alpha: 1.0) :
             UIColor(red: 0.96, green: 0.98, blue: 0.96, alpha: 1.0)
         })),
        
        ("Sunset Orange", 
         Color(uiColor: UIColor { traitCollection in
             traitCollection.userInterfaceStyle == .dark ?
             UIColor(red: 1.0, green: 0.50, blue: 0.37, alpha: 1.0) :
             UIColor(red: 0.95, green: 0.40, blue: 0.27, alpha: 1.0)
         }),
         Color(uiColor: UIColor { traitCollection in
             traitCollection.userInterfaceStyle == .dark ?
             UIColor(red: 0.12, green: 0.11, blue: 0.10, alpha: 1.0) :
             UIColor(red: 0.99, green: 0.96, blue: 0.93, alpha: 1.0)
         })),
        
        ("Deep Purple", 
         Color(uiColor: UIColor { traitCollection in
             traitCollection.userInterfaceStyle == .dark ?
             UIColor(red: 0.55, green: 0.41, blue: 0.95, alpha: 1.0) :
             UIColor(red: 0.45, green: 0.31, blue: 0.85, alpha: 1.0)
         }),
         Color(uiColor: UIColor { traitCollection in
             traitCollection.userInterfaceStyle == .dark ?
             UIColor(red: 0.11, green: 0.10, blue: 0.12, alpha: 1.0) :
             UIColor(red: 0.97, green: 0.97, blue: 0.99, alpha: 1.0)
         })),
        
        ("Minimal", 
         Color(uiColor: UIColor { traitCollection in
             traitCollection.userInterfaceStyle == .dark ?
             UIColor(red: 0.73, green: 0.73, blue: 0.73, alpha: 1.0) :
             UIColor(red: 0.33, green: 0.33, blue: 0.33, alpha: 1.0)
         }),
         Color(uiColor: UIColor { traitCollection in
             traitCollection.userInterfaceStyle == .dark ?
             UIColor(red: 0.11, green: 0.11, blue: 0.11, alpha: 1.0) :
             UIColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1.0)
         }))
    ]
    
    private init() {
        // Default to first theme if no saved preference
        let savedColor = UserDefaults.standard.color(forKey: "primaryColor")
        let savedBackground = UserDefaults.standard.color(forKey: "backgroundColor")
        
        if let primary = savedColor, let background = savedBackground {
            self.primaryColor = primary
            self.backgroundColor = background
        } else {
            // Default to first theme
            self.primaryColor = themes[0].primary
            self.backgroundColor = themes[0].background
        }
    }
    
    func applyTheme(primary: Color, background: Color) {
        withAnimation {
            primaryColor = primary
            backgroundColor = background
        }
    }
}

// Helper extension for Color persistence
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

// Extension to handle dark mode adaptation
extension Color {
    func colorSchemeAdjusted() -> Color {
        return Color(uiColor: UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                // Convert to darker variant for dark mode
                return UIColor(self).adjustBrightness(by: -0.85)
            } else {
                return UIColor(self)
            }
        })
    }
}

// Extension to adjust color brightness
extension UIColor {
    func adjustBrightness(by amount: CGFloat) -> UIColor {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        return UIColor(hue: hue,
                      saturation: saturation,
                      brightness: max(0, min(brightness + amount, 1.0)),
                      alpha: alpha)
    }
} 