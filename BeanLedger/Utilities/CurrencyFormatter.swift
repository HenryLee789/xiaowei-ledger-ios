import Foundation

enum AmountPolarity {
    case positive
    case negative
    case neutral
}

enum CurrencyFormatter {
    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "¥"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()

    static func string(from amount: Double) -> String {
        formatter.string(from: NSNumber(value: amount)) ?? "¥0.00"
    }

    static func signedString(from amount: Double, sign: String) -> String {
        "\(sign)\(string(from: abs(amount)))"
    }

    static func signedString(fromSigned amount: Double) -> String {
        if amount > 0 {
            return signedString(from: amount, sign: "+")
        }
        if amount < 0 {
            return signedString(from: amount, sign: "-")
        }
        return string(from: 0)
    }

    static func inputString(from amount: Double) -> String {
        guard amount.isFinite else { return "" }
        var text = String(format: "%.2f", locale: Locale(identifier: "en_US_POSIX"), amount)
        while text.last == "0" {
            text.removeLast()
        }
        if text.last == "." {
            text.removeLast()
        }
        return text
    }
}
