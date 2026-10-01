import SwiftUI

@MainActor
final class PDFPreviewViewModel: ObservableObject {
    let url: URL
    let filename: String
    @Published var export = false
    @Published var sharing = false
    @Published var data: Data?
    @Published var shareURL: URL?
    @Published var error: String?
    @Published var status = "Document saved"
    @Published var page = 1
    @Published var count = 1
    init(url: URL, filename: String) { self.url = url; self.filename = filename }
    func previousPage() { page = max(1, page - 1) }
    func nextPage() { page = min(count, page + 1) }
    func save() { status = "Saved on this device" }
    func previewFailed(_ failure: Error) { error = AppLog.message(.pdf, failure) }
    func download() {
        do {
            let bytes = try Data(contentsOf: url)
            guard !bytes.isEmpty else { throw AppError.invalidPDF }
            data = bytes; error = nil; export = true
            AppLog.pdf.debug("Files export prepared from preview bytes")
        } catch { self.error = AppLog.message(.download, error) }
    }
    func share() {
        do {
            let bytes = try Data(contentsOf: url)
            guard !bytes.isEmpty else { throw AppError.invalidPDF }
            let target = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
            try bytes.write(to: target, options: .atomic)
            shareURL = target; error = nil; sharing = true
            AppLog.pdf.debug("System sharing prepared from preview bytes")
        } catch { self.error = AppLog.message(.share, error) }
    }
    func exportCompleted(_ result: Result<URL, Error>) {
        switch result {
        case .success: status = "PDF exported"; error = nil; AppLog.pdf.info("Files export completed")
        case .failure(let e):
            if AppLog.isCancellation(e) { status = "Export cancelled — document saved"; error = nil; AppLog.pdf.debug("Files export cancelled by user") }
            else { error = AppLog.message(.export, e) }
        }
    }
}
