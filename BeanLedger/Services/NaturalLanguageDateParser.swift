import Foundation

enum NaturalLanguageDateParser {
    static func parse(_ dateText: String, now: Date = Date(), calendar: Calendar = .current) -> Date {
        let text = dateText.trimmingCharacters(in: .whitespacesAndNewlines)
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: now)

        if let specificComponents = specificMonthDayComponents(from: text, now: now, calendar: calendar) {
            components.year = specificComponents.year
            components.month = specificComponents.month
            components.day = specificComponents.day
        } else if text.contains("前天") {
            components = shiftedComponents(byAddingDays: -2, to: now, calendar: calendar)
        } else if text.contains("昨天") {
            components = shiftedComponents(byAddingDays: -1, to: now, calendar: calendar)
        } else if text.contains("今天") || text.isEmpty {
            components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: now)
        }

        if text.contains("上午") || text.contains("早上") || text.contains("早餐") {
            components.hour = 9
            components.minute = 0
        } else if text.contains("中午") || text.contains("午饭") {
            components.hour = 12
            components.minute = 0
        } else if text.contains("下午") {
            components.hour = 15
            components.minute = 0
        } else if text.contains("晚上") || text.contains("晚饭") || text.contains("夜里") {
            components.hour = 20
            components.minute = 0
        }

        return calendar.date(from: components) ?? now
    }

    private static func shiftedComponents(byAddingDays days: Int, to now: Date, calendar: Calendar) -> DateComponents {
        let shifted = calendar.date(byAdding: .day, value: days, to: now) ?? now
        return calendar.dateComponents([.year, .month, .day, .hour, .minute], from: shifted)
    }

    private static func specificMonthDayComponents(from text: String, now: Date, calendar: Calendar) -> DateComponents? {
        let pattern = #"(\d{1,2})\s*月\s*(\d{1,2})\s*日?"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              match.numberOfRanges >= 3,
              let monthRange = Range(match.range(at: 1), in: text),
              let dayRange = Range(match.range(at: 2), in: text),
              let month = Int(text[monthRange]),
              let day = Int(text[dayRange]) else {
            return nil
        }

        var components = calendar.dateComponents([.year, .hour, .minute], from: now)
        components.month = month
        components.day = day
        return components
    }
}
