import SwiftUI
import UniformTypeIdentifiers

private struct BackupFile: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws { data = configuration.file.regularFileContents ?? Data() }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}

struct BackupSettingsSection: View {
    @EnvironmentObject var store: DocumentsViewModel
    @State private var exporting = false
    @State private var importing = false
    @State private var file: BackupFile?
    @State private var pending: AgreementBackup?
    @State private var confirming = false
    @State private var message: String?
    @State private var selectingFolder = false
    @AppStorage("backupAutomatic") private var automatic = false
    @AppStorage("backupIntervalDays") private var interval = 1
    @AppStorage("backupTimeMinutes") private var timeMinutes = 1200
    @AppStorage("backupFolderName") private var folderName = ""
    @AppStorage("backupAutomaticError") private var automaticError = ""
    @AppStorage("backupLastSuccess") private var lastSuccess = 0.0

    var body: some View {
        Section("Backup & Restore") {
            CompactToggle(title: "Automatic iCloud backups", isOn: $automatic)
            if automatic {
                Button(folderName.isEmpty ? "Choose folder in iCloud Drive" : "Backup folder: \(folderName)") { selectingFolder = true }
                Picker("Backup frequency", selection: $interval) {
                    Text("Daily").tag(1)
                    Text("Every 3 days").tag(3)
                    Text("Weekly").tag(7)
                }
                DatePicker("Preferred backup time", selection: Binding(get: {
                    Calendar.current.date(byAdding: .minute, value: timeMinutes, to: Calendar.current.startOfDay(for: Date())) ?? Date()
                }, set: { date in
                    let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
                    timeMinutes = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
                }), displayedComponents: .hourAndMinute)
                Text("Choose a folder under iCloud Drive. Backups run while the app is open, or catch up when you reopen it after the scheduled time. Keep previous backups to recover older versions.")
                    .font(.caption).foregroundStyle(.secondary)
                if lastSuccess > 0 {
                    let date = Date(timeIntervalSince1970: lastSuccess)
                    Text("Last backup: \(date.formatted(date: .abbreviated, time: .shortened))").font(.caption)
                }
                if !automaticError.isEmpty { Text(automaticError).font(.caption).foregroundStyle(.red) }
            }
            Text("Save a backup in iCloud Drive or another location outside this app before deleting it. Backups include editable agreements, uploaded designs, and saved company settings. PDFs can be generated again after restoring.")
                .font(.caption).foregroundStyle(.secondary)
            Button { 
                do {
                    guard let repository = store.repository else { throw CocoaError(.fileReadUnknown) }
                    file = BackupFile(data: try repository.backupData()); exporting = true
                } catch { message = "Could not create the backup. Please try again." }
            } label: { Label("Export backup", systemImage: "square.and.arrow.up") }
            Button { importing = true } label: { Label("Restore from backup", systemImage: "square.and.arrow.down") }
            Text("Save Company Settings before exporting to include your latest changes. Backups contain client information; keep them in a private location.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .fileImporter(isPresented: $selectingFolder, allowedContentTypes: [.folder]) { result in
            do {
                try AutomaticBackup.saveFolder(try result.get())
                AutomaticBackup.runIfDue(repository: store.repository)
            } catch {
                if (error as NSError).code != NSUserCancelledError { message = "Could not access the backup folder. Please choose it again." }
            }
        }
        .fileExporter(isPresented: $exporting, document: file, contentType: .json, defaultFilename: "Adarsh-Agreement-Backup") { result in
            switch result {
            case .success: message = "Backup saved. Keep this file outside the app so you can restore it after reinstalling."
            case .failure(let error): if (error as NSError).code != NSUserCancelledError { message = "Backup was not saved. Please try again." }
            }
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            do {
                let url = try result.get()
                let access = url.startAccessingSecurityScopedResource()
                defer { if access { url.stopAccessingSecurityScopedResource() } }
                pending = try AgreementBackup.decode(Data(contentsOf: url)); confirming = true
            } catch {
                if (error as NSError).code != NSUserCancelledError { message = "This file could not be read as an Adarsh backup. No agreements were changed." }
            }
        }
        .alert("Restore backup?", isPresented: $confirming) {
            Button("Restore") {
                do {
                    guard let pending, let repository = store.repository else { throw CocoaError(.fileReadUnknown) }
                    let count = try repository.restoreBackup(pending)
                    store.documents = try repository.list(); store.branding = try repository.loadBranding()
                    message = "Restored \(count) agreements. Existing agreements were kept. Company settings were restored."
                } catch { message = "Restore could not be completed. Please try again." }
                pending = nil
            }
            Button("Cancel", role: .cancel) { pending = nil }
        } message: {
            Text("Import \(pending?.agreements.count ?? 0) agreements and restore saved company settings. Existing agreements are kept; conflicting versions are added as separate copies.")
        }
        .alert("Backup & Restore", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
            Button("OK") { message = nil }
        } message: { Text(message ?? "") }
    }
}
