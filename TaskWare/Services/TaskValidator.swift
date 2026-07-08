import Foundation

enum TaskValidator {
    static let maxTitleLength = 120

    enum ValidationError: LocalizedError, Equatable {
        case emptyTitle
        case titleTooLong(max: Int)

        var errorDescription: String? {
            switch self {
            case .emptyTitle: "Title can’t be empty."
            case .titleTooLong(let max): "Title must be \(max) characters or fewer."
            }
        }
    }

    /// Returns the normalized (trimmed) title or throws.
    static func validateTitle(_ raw: String) throws -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ValidationError.emptyTitle }
        guard trimmed.count <= maxTitleLength else {
            throw ValidationError.titleTooLong(max: maxTitleLength)
        }
        return trimmed
    }
}
