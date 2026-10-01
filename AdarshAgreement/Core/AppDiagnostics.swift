import Foundation
import OSLog

enum AppOperation: String {
    case initialize, load, save, duplicate, delete, settings, pdf, download, share, export, verification
}

enum AppError: LocalizedError {
    case storageUnavailable
    case invalidPDF
    case validationFailed(count: Int)
    case operationFailed(AppOperation, underlying: Error)

    var errorDescription: String? {
        switch self {
        case .storageUnavailable: "Local storage is unavailable. Reopen the app to retry."
        case .invalidPDF: "The PDF could not be opened. Generate the preview again; the agreement is still saved."
        case .validationFailed: "Complete the highlighted fields before generating the PDF. You can still save a draft."
        case .operationFailed(let operation, _):
            switch operation {
            case .initialize, .load: "Could not load local documents. Existing files have been preserved. Reopen the app to retry."
            case .save: "Save failed. Your form is still available. Retry saving."
            case .duplicate: "Could not duplicate the agreement. The original is unchanged. Try again."
            case .delete: "Could not finish deleting the agreement. Refresh the list and try again."
            case .settings: "Company settings could not be saved. Keep this screen open and retry."
            case .pdf: "Could not generate or save the PDF. Your agreement data remains available. Try again."
            case .download, .export: "PDF export failed. The saved document remains available. Retry exporting."
            case .share: "Could not prepare the PDF for sharing. The saved document remains available. Try again."
            case .verification: "The development verification could not complete. Check the diagnostic console."
            }
        }
    }
}

enum AppLog {
    private static let subsystem = "in.adarshinfra.agreementbuilder"
    static let storage = Logger(subsystem: subsystem, category: "Storage")
    static let pdf = Logger(subsystem: subsystem, category: "PDF")
    static let validation = Logger(subsystem: subsystem, category: "Validation")
    static let lifecycle = Logger(subsystem: subsystem, category: "Lifecycle")
    // Never log localized descriptions, userInfo, paths, filenames or agreement values.
    static func failure(_ operation: AppOperation, _ error: Error) {
        let cause: Error
        if case AppError.operationFailed(_, let underlying) = error { cause = underlying } else { cause = error }
        let nsError = cause as NSError
        let logger = [.pdf, .download, .share, .export, .verification].contains(operation) ? pdf : storage
        logger.error("Operation \(operation.rawValue, privacy: .public) failed; domain=\(nsError.domain, privacy: .public), code=\(nsError.code, privacy: .public), type=\(String(reflecting: type(of: cause)), privacy: .public)")
    }
    static func message(_ operation: AppOperation, _ error: Error) -> String {
        failure(operation, error)
        if let error = error as? AppError { return error.localizedDescription }
        return AppError.operationFailed(operation, underlying: error).localizedDescription
    }
    static func isCancellation(_ error: Error) -> Bool {
        let e = error as NSError
        return (e.domain == NSCocoaErrorDomain && e.code == NSUserCancelledError)
            || (e.domain == NSURLErrorDomain && e.code == NSURLErrorCancelled)
    }
}
