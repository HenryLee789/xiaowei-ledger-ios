import Foundation
import ImageIO
import UIKit

enum RecordImageStoreError: LocalizedError {
    case invalidImage

    var errorDescription: String? {
        "无法读取所选图片"
    }
}

enum RecordImageStore {
    private static let folderName = "BeanLedgerRecordImages"
    private static let imageCache = NSCache<NSString, UIImage>()

    static var folderURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(folderName, isDirectory: true)
    }

    static func saveImage(data: Data, for recordID: UUID) throws -> String {
        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)

        let filename = "\(recordID.uuidString).jpg"
        let fileURL = folderURL.appendingPathComponent(filename)
        guard let image = previewImage(data: data),
              let outputData = image.jpegData(compressionQuality: 0.82) else {
            throw RecordImageStoreError.invalidImage
        }
        try outputData.write(to: fileURL, options: [.atomic])
        imageCache.setObject(image, forKey: filename as NSString)
        return filename
    }

    static func image(for filename: String?) -> UIImage? {
        guard let filename, let fileURL = safeFileURL(for: filename) else { return nil }
        if let cached = imageCache.object(forKey: filename as NSString) {
            return cached
        }
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        guard let image = UIImage(contentsOfFile: fileURL.path) else { return nil }
        imageCache.setObject(image, forKey: filename as NSString)
        return image
    }

    static func deleteImage(filename: String?) {
        guard let filename, let fileURL = safeFileURL(for: filename) else { return }
        imageCache.removeObject(forKey: filename as NSString)
        try? FileManager.default.removeItem(at: fileURL)
    }

    static func clearAllImages() {
        imageCache.removeAllObjects()
        try? FileManager.default.removeItem(at: folderURL)
    }

    static func previewImage(data: Data, maxPixelSize: Int = 720) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]
        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }
        return UIImage(cgImage: thumbnail)
    }

    private static func safeFileURL(for filename: String) -> URL? {
        let path = URL(fileURLWithPath: filename)
        guard path.lastPathComponent == filename,
              path.pathExtension.lowercased() == "jpg",
              UUID(uuidString: path.deletingPathExtension().lastPathComponent) != nil else {
            return nil
        }
        return folderURL.appendingPathComponent(filename, isDirectory: false)
    }
}
