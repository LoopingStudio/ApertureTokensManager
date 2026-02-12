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
    public static let xxLarge: CGFloat = 20
  }
  
  public enum Size {
    // Color squares
    public static let colorSquare: CGFloat = 64
    public static let colorSquareSmall: CGFloat = 24
    public static let colorSquareMedium: CGFloat = 50
    
    // Popovers and panels
    public static let colorPopoverWidth: CGFloat = 320
    public static let colorLabelWidth: CGFloat = 100
    public static let popoverWidth: CGFloat = 320
    public static let historyMaxWidth: CGFloat = 500
    public static let previewWidth: CGFloat = 400
    public static let previewHeight: CGFloat = 300
    
    // Drop zones
    public static let dropZoneMinHeight: CGFloat = 200
    
    // Icons
    public static let iconSmall: CGFloat = 32
    public static let iconMedium: CGFloat = 36
    public static let iconLarge: CGFloat = 44
    public static let headerIconSize: CGFloat = 56
    public static let emptyStateIconSize: CGFloat = 120
    public static let sidebarIndicatorSize: CGFloat = 28
    public static let tutorialIconSize: CGFloat = 72
    
    // Token Tree
    public static let treeChevronSize: CGFloat = 24
    public static let treeIconSize: CGFloat = 16
    public static let treeColorDotSize: CGFloat = 12
    public static let treeMiniColorSize: CGFloat = 14
    
    // Window
    public static let windowMinWidth: CGFloat = 900
    public static let windowMinHeight: CGFloat = 650
    public static let windowDefaultWidth: CGFloat = 1100
    public static let windowDefaultHeight: CGFloat = 750
    public static let settingsMinHeight: CGFloat = 450
    
    // Search field
    public static let searchFieldWidth: CGFloat = 300
    
    // Content areas
    public static let maxContentWidth: CGFloat = 600
    public static let splitViewMinWidth: CGFloat = 250
    public static let splitViewIdealWidth: CGFloat = 600
    
    // Logs
    public static let logTimestampWidth: CGFloat = 80
    
    // Offsets
    public static let buttonOffset: CGFloat = 48
    
    // Misc
    public static let dividerWidth: CGFloat = 200
  }
  
  public enum CornerRadius {
    public static let extraSmall: CGFloat = 3
    public static let small: CGFloat = 4
    public static let medium: CGFloat = 6
    public static let large: CGFloat = 8
    public static let extraLarge: CGFloat = 10
    public static let xxLarge: CGFloat = 12
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
