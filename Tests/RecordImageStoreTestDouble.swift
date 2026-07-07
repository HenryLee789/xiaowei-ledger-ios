import Foundation

enum RecordImageStore {
    static func saveImage(data: Data, for recordID: UUID) throws -> String {
        "\(recordID.uuidString).jpg"
    }

    static func deleteImage(filename: String?) {}

    static func clearAllImages() {}
}
