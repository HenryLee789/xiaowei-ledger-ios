import Foundation
import UIKit

enum RecordImageStore {
    private static let folderName = "BeanLedgerRecordImages"

    static var folderURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(folderName, isDirectory: true)
    }

    static func saveImage(data: Data, for recordID: UUID) throws -> String {
        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)

        let filename = "\(recordID.uuidString).jpg"
        let fileURL = folderURL.appendingPathComponent(filename)
        let outputData = resizedJPEGData(from: data) ?? data
        try outputData.write(to: fileURL, options: [.atomic])
        return filename
    }

    static func image(for filename: String?) -> UIImage? {
        guard let filename else { return nil }
        let fileURL = folderURL.appendingPathComponent(filename)
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        return UIImage(contentsOfFile: fileURL.path)
    }

    static func deleteImage(filename: String?) {
        guard let filename else { return }
        try? FileManager.default.removeItem(at: folderURL.appendingPathComponent(filename))
    }

    static func clearAllImages() {
        try? FileManager.default.removeItem(at: folderURL)
    }

    private static func resizedJPEGData(from data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let maxSide: CGFloat = 720
        let longestSide = max(image.size.width, image.size.height)
        let scale = min(1, maxSide / max(longestSide, 1))
        let targetSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let rendered = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return rendered.jpegData(compressionQuality: 0.82)
    }
}
