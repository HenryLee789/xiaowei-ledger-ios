import Foundation

enum ExportFormat {
    case json
    case csv

    var fileExtension: String {
        switch self {
        case .json: return "json"
        case .csv: return "csv"
        }
    }
}

struct LedgerExportPayload {
    let data: Data
    let filename: String
}

enum ExportService {
    static func makeExport(records: [LedgerRecord], format: ExportFormat) throws -> LedgerExportPayload {
        switch format {
        case .json:
            return try LedgerExportPayload(data: jsonData(records: records), filename: filename(extension: format.fileExtension))
        case .csv:
            return LedgerExportPayload(data: csvData(records: records), filename: filename(extension: format.fileExtension))
        }
    }

    private static func jsonData(records: [LedgerRecord]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(records)
    }

    private static func csvData(records: [LedgerRecord]) -> Data {
        let sortedRecords = records.sorted { $0.date > $1.date }
        var rows = [
            ["id", "amount", "signedAmount", "type", "typeName", "category", "note", "date", "createdAt"]
        ]

        rows.append(contentsOf: sortedRecords.map { record in
            [
                record.id.uuidString,
                decimalString(record.amount),
                decimalString(record.signedAmount),
                record.type.rawValue,
                record.type.displayName,
                spreadsheetSafeText(record.category),
                spreadsheetSafeText(record.note),
                isoFormatter.string(from: record.date),
                isoFormatter.string(from: record.createdAt)
            ]
        })

        let csv = rows
            .map { row in row.map(escapeCSVField).joined(separator: ",") }
            .joined(separator: "\n")
        var data = Data([0xEF, 0xBB, 0xBF])
        data.append(Data(csv.utf8))
        return data
    }

    private static func filename(extension fileExtension: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd"
        return "小魏记账簿_账本导出_\(formatter.string(from: Date())).\(fileExtension)"
    }

    private static func decimalString(_ value: Double) -> String {
        String(format: "%.2f", locale: Locale(identifier: "en_US_POSIX"), value)
    }

    private static func escapeCSVField(_ value: String) -> String {
        let needsEscaping = value.contains(",") || value.contains("\"") || value.contains("\n")
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return needsEscaping ? "\"\(escaped)\"" : escaped
    }

    private static func spreadsheetSafeText(_ value: String) -> String {
        guard let firstContent = value.first(where: { !$0.isWhitespace }),
              ["=", "+", "-", "@"].contains(firstContent) else {
            return value
        }
        return "'" + value
    }

    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}
