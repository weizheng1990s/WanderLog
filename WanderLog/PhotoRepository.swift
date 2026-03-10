import UIKit
import Foundation

final class PhotoRepository {

    static let shared = PhotoRepository()
    private init() { createDirectoryIfNeeded() }

    var photosDirectory: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("photos", isDirectory: true)
    }

    private func createDirectoryIfNeeded() {
        try? FileManager.default.createDirectory(
            at: photosDirectory,
            withIntermediateDirectories: true
        )
    }

    func save(_ images: [UIImage]) throws -> [String] {
        try images.map { image in
            let filename = UUID().uuidString + ".jpg"
            let url = photosDirectory.appendingPathComponent(filename)
            let resized = image.resized(maxDimension: 1200)
            guard let data = resized.jpegData(compressionQuality: 0.85) else {
                throw PhotoError.compressionFailed
            }
            try data.write(to: url)
            return filename
        }
    }

    func load(_ filename: String) -> UIImage? {
        let url = photosDirectory.appendingPathComponent(filename)
        return UIImage(contentsOfFile: url.path)
    }

    func loadAll(_ filenames: [String]) -> [UIImage] {
        filenames.compactMap { load($0) }
    }

    func delete(_ filenames: [String]) {
        filenames.forEach { filename in
            let url = photosDirectory.appendingPathComponent(filename)
            try? FileManager.default.removeItem(at: url)
        }
    }

    var totalSizeBytes: Int64 {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: photosDirectory,
            includingPropertiesForKeys: [.fileSizeKey]
        ) else { return 0 }
        return files.reduce(0) { sum, url in
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            return sum + Int64(size)
        }
    }

    var totalSizeFormatted: String {
        let bytes = Double(totalSizeBytes)
        if bytes < 1_000_000 { return String(format: "%.1f KB", bytes / 1000) }
        return String(format: "%.1f MB", bytes / 1_000_000)
    }
}

enum PhotoError: LocalizedError {
    case compressionFailed
    var errorDescription: String? { "照片压缩失败" }
}

extension UIImage {
    func resized(maxDimension: CGFloat) -> UIImage {
        let size = self.size
        guard max(size.width, size.height) > maxDimension else { return self }
        let scale = maxDimension / max(size.width, size.height)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        return UIGraphicsImageRenderer(size: newSize).image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
