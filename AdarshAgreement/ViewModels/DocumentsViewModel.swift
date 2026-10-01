import SwiftUI

@MainActor
final class DocumentsViewModel: ObservableObject {
    @Published var documents: [Agreement] = []
    @Published var branding = Branding()
    @Published var error: String?
    @Published var notice: String?
    private(set) var repository: AgreementRepository?
    init() {
        do {
            let directory = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("Agreements", isDirectory: true)
            let localRepository = try AgreementRepository(directory: directory)
            repository = localRepository
            documents = try localRepository.list(); branding = try localRepository.loadBranding()
            AppLog.storage.info("Local workspace loaded; document count=\(self.documents.count, privacy: .public)")
        } catch { self.error = AppLog.message(.initialize, error) }
    }
    func save(_ document: inout Agreement, ready: Bool = false, announce: Bool = false) -> Bool {
        guard let repository else { error = AppLog.message(.save, AppError.storageUnavailable); return false }
        var saved = document; saved.modified = Date(); saved.revision += 1
        if ready { saved.status = "Ready" }
        do {
            try repository.save(saved); document = saved
            documents = try repository.list()
            if announce { notice = ready ? "Document saved" : "Draft saved" }
            error = nil
            AppLog.storage.debug("Agreement saved atomically; revision=\(saved.revision, privacy: .public), ready=\(ready, privacy: .public)")
            return true
        } catch { self.error = AppLog.message(.save, error); return false }
    }
    func newDocument() -> Agreement { var d = Agreement(); d.branding = branding; return d }
    func duplicate(_ d: Agreement) {
        do {
            guard let repository else { throw AppError.storageUnavailable }
            _ = try repository.duplicate(d); documents = try repository.list(); notice = "Independent copy created"; error = nil
            AppLog.storage.info("Independent agreement copy saved")
        } catch { self.error = AppLog.message(.duplicate, error) }
    }
    func delete(_ d: Agreement) {
        do {
            guard let repository else { throw AppError.storageUnavailable }
            try repository.delete(d.id); documents = try repository.list(); error = nil
            AppLog.storage.info("Agreement deletion completed")
        } catch { self.error = AppLog.message(.delete, error) }
    }
    func saveBranding() {
        do {
            guard let repository else { throw AppError.storageUnavailable }
            try repository.saveBranding(branding); notice = "Company settings saved"; error = nil
            AppLog.storage.info("Company settings saved")
        } catch { self.error = AppLog.message(.settings, error) }
    }
    func pdf(_ d: inout Agreement) throws -> URL {
        guard let repository else { throw AppError.storageUnavailable }
        let issues = Validator.issues(d)
        guard issues.isEmpty else {
            AppLog.validation.notice("PDF finalization blocked; issue count=\(issues.count, privacy: .public)")
            throw AppError.validationFailed(count: issues.count)
        }
        let fingerprint = try AgreementPDFRenderer.fingerprint(d)
        let url = repository.pdfURL(d.id)
        if d.pdfFingerprint != fingerprint || !FileManager.default.fileExists(atPath: url.path) {
            AppLog.pdf.debug("Rendering updated agreement snapshot")
            let bytes = AgreementPDFRenderer.render(d)
            try repository.savePDF(bytes, for: d.id); d.pdfFingerprint = fingerprint
            AppLog.pdf.info("PDF rendered and cached; byte count=\(bytes.count, privacy: .public)")
        } else {
            AppLog.pdf.debug("Using cached PDF for unchanged snapshot")
        }
        guard save(&d, ready: true) else { throw CocoaError(.fileWriteUnknown) }
        return url
    }
}
