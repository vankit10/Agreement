import Foundation

struct AgreementBackup: Codable {
    var format = "AdarshAgreementBackup"
    var version = 1
    var created = Date()
    var agreements: [Agreement]
    var branding: Branding

    static func decode(_ data: Data) throws -> AgreementBackup {
        let backup = try JSONDecoder().decode(AgreementBackup.self, from: data)
        guard backup.format == "AdarshAgreementBackup", backup.version == 1,
              Set(backup.agreements.map(\.id)).count == backup.agreements.count else {
            throw CocoaError(.fileReadCorruptFile)
        }
        return backup
    }
}

extension AgreementRepository {
    func backupData() throws -> Data {
        try JSONEncoder().encode(AgreementBackup(agreements: list(), branding: loadBranding()))
    }

    /// Stage a complete replacement before touching the live store; preserve
    /// existing agreements and create a copy for conflicting saved versions.
    func restoreBackup(_ backup: AgreementBackup) throws -> Int {
        let manager = FileManager.default
        let parent = directory.deletingLastPathComponent()
        let staging = parent.appendingPathComponent("Restore-" + UUID().uuidString)
        let recovery = parent.appendingPathComponent("Recovery-" + UUID().uuidString)
        defer { try? manager.removeItem(at: staging) }
        try manager.copyItem(at: directory, to: staging)
        let staged = try AgreementRepository(directory: staging)
        let existing = try list()
        var count = 0
        for var agreement in backup.agreements {
            if let current = existing.first(where: { $0.id == agreement.id }) {
                if current == agreement { continue }
                agreement.id = UUID()
            }
            agreement.pdfFingerprint = nil
            try staged.save(agreement)
            count += 1
        }
        try staged.saveBranding(backup.branding)
        try manager.moveItem(at: directory, to: recovery)
        do { try manager.moveItem(at: staging, to: directory) }
        catch {
            try manager.moveItem(at: recovery, to: directory)
            throw error
        }
        try? manager.removeItem(at: recovery)
        return count
    }
}
