import Foundation

final class AgreementRepository {
    let directory: URL
    private let encoder: JSONEncoder = {
        let e = JSONEncoder(); e.outputFormatting = [.sortedKeys]; return e
    }()
    init(directory: URL) throws {
        self.directory = directory
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }
    func list() throws -> [Agreement] {
        try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" && $0.lastPathComponent != "company.json" }
            .map { try JSONDecoder().decode(Agreement.self, from: Data(contentsOf: $0)) }
            .sorted { $0.modified > $1.modified }
    }
    func save(_ document: Agreement) throws {
        try encoder.encode(document).write(to: recordURL(document.id), options: .atomic)
    }
    func load(_ id: UUID) throws -> Agreement {
        try JSONDecoder().decode(Agreement.self, from: Data(contentsOf: recordURL(id)))
    }
    func duplicate(_ document: Agreement) throws -> Agreement {
        var copy = document; copy.id = UUID(); copy.status = "Draft"; copy.created = Date(); copy.modified = copy.created
        copy.revision = 0; copy.pdfFingerprint = nil; copy.step = 0
        try save(copy); return copy
    }
    func delete(_ id: UUID) throws {
        try FileManager.default.removeItem(at: recordURL(id))
        let pdf = pdfURL(id)
        if FileManager.default.fileExists(atPath: pdf.path) { try FileManager.default.removeItem(at: pdf) }
    }
    func savePDF(_ data: Data, for id: UUID) throws { try data.write(to: pdfURL(id), options: .atomic) }
    func pdfURL(_ id: UUID) -> URL { directory.appendingPathComponent(id.uuidString + ".pdf") }
    private func recordURL(_ id: UUID) -> URL { directory.appendingPathComponent(id.uuidString + ".json") }
    func loadBranding() throws -> Branding {
        let url = directory.appendingPathComponent("company.json")
        guard FileManager.default.fileExists(atPath: url.path) else { return Branding() }
        return try JSONDecoder().decode(Branding.self, from: Data(contentsOf: url))
    }
    func saveBranding(_ branding: Branding) throws {
        try encoder.encode(branding).write(to: directory.appendingPathComponent("company.json"), options: .atomic)
    }
}
