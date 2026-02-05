import Foundation

extension String {
  /// Parses the string using common date formats and returns a Date if successful
  private func parseDate() -> Date? {
    let inputFormatter = DateFormatter()
    for format in DateFormatPatterns.all {
      inputFormatter.dateFormat = format
      if let date = inputFormatter.date(from: self) {
        return date
      }
    }
    return nil
  }
  
  /// Converts date string to French format (medium date, short time)
  public var formatFrenchDate: String {
    guard let date = parseDate() else { return self }
    
    let outputFormatter = DateFormatter()
    outputFormatter.locale = Locale(identifier: "fr_FR")
    outputFormatter.dateStyle = .medium
    outputFormatter.timeStyle = .short
    return outputFormatter.string(from: date)
  }
  
  /// Converts date string to short format (dd/MM/yy)
  func toShortDate() -> String {
    guard let date = parseDate() else { return self }
    
    let outputFormatter = DateFormatter()
    outputFormatter.locale = Locale(identifier: "fr_FR")
    outputFormatter.dateFormat = "dd/MM/yy"
    return outputFormatter.string(from: date)
  }
}
