import Foundation
import SwiftUI

// MARK: - Brand Constants
public enum Brand {
  public static let legacy = "Legacy"
  public static let newBrand = "New Brand"
}

// MARK: - Theme Constants
public enum ThemeType {
  public static let light = "light"
  public static let dark = "dark"
}

// MARK: - Group Names (for filtering)
public enum GroupNames {
  public static let utility = "utility"
}

// MARK: - UI Constants
public enum UIConstants {
  public enum Spacing {
    public static let extraSmall: CGFloat = 2
    public static let small: CGFloat = 4
    public static let medium: CGFloat = 8
    public static let large: CGFloat = 12
    public static let extraLarge: CGFloat = 16
    public static let section: CGFloat = 24
  }
  
  public enum Size {
    public static let colorSquare: CGFloat = 64
    public static let colorSquareSmall: CGFloat = 24
    public static let colorPopoverWidth: CGFloat = 320
    public static let colorLabelWidth: CGFloat = 100
    public static let dropZoneMinHeight: CGFloat = 200
    public static let historyMaxWidth: CGFloat = 500
  }
  
  public enum CornerRadius {
    public static let small: CGFloat = 4
    public static let medium: CGFloat = 6
    public static let large: CGFloat = 8
  }
}

// MARK: - Animation Constants
public enum AnimationDuration {
  public static let quick: Double = 0.1
  public static let normal: Double = 0.2
  public static let slow: Double = 0.3
  public static let verySlow: Double = 0.4
}

// MARK: - History Constants
public enum HistoryConstants {
  public static let maxEntries = 10
}

// MARK: - Date Format Constants
public enum DateFormatPatterns {
  public static let all: [String] = [
    "yyyy-MM-dd HH:mm:ss",
    "yyyy-MM-dd'T'HH:mm:ss",
    "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
    "yyyy-MM-dd"
  ]
  
  public static let display = "dd MMM yyyy 'à' HH:mm"
}
