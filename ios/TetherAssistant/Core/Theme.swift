import SwiftUI

public enum Theme {
    public static let background = Color(red: 0.05, green: 0.05, blue: 0.06) // #0D0D10
    public static let surface = Color(red: 0.10, green: 0.10, blue: 0.12)    // #1A1A1F
    public static let surfaceElevated = Color(red: 0.15, green: 0.15, blue: 0.18)
    
    public static let textPrimary = Color.white
    public static let textSecondary = Color(white: 0.65)
    public static let textMuted = Color(white: 0.45)
    
    public static let accent = Color(red: 0.23, green: 0.51, blue: 0.96) // #3B82F6 Electric Blue
    public static let success = Color(red: 0.06, green: 0.73, blue: 0.51) // #10B981 Emerald
    public static let warning = Color(red: 0.96, green: 0.62, blue: 0.04) // #F59E0B Amber
    public static let danger = Color(red: 0.94, green: 0.27, blue: 0.27)  // #EF4444 Crimson
    
    public static let cornerRadius: CGFloat = 16.0
}

