import Foundation

@MainActor
enum AutomaticBackup {
    static let defaults = UserDefaults.standard
    static func saveFolder(_ url: URL) throws {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        let bookmark = try url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
        defaults.set(bookmark, forKey: "backupFolder")
        defaults.set(url.lastPathComponent, forKey: "backupFolderName")
        defaults.removeObject(forKey: "backupLastSuccess")
    }

    static func runIfDue(repository: AgreementRepository?) {
        guard defaults.bool(forKey: "backupAutomatic"), let repository,
              let bookmark = defaults.data(forKey: "backupFolder") else { return }
        let calendar = Calendar.current
        let now = Date()
        let days = max(1, defaults.integer(forKey: "backupIntervalDays"))
        let minutes = defaults.object(forKey: "backupTimeMinutes") == nil ? 1200 : defaults.integer(forKey: "backupTimeMinutes")
        let today = calendar.startOfDay(for: now)
        guard let scheduled = calendar.date(byAdding: .minute, value: minutes, to: today) else { return }
        let due: Bool
        if defaults.double(forKey: "backupLastSuccess") > 0 {
            let last = Date(timeIntervalSince1970: defaults.double(forKey: "backupLastSuccess"))
            let nextDay = calendar.date(byAdding: .day, value: days, to: calendar.startOfDay(for: last)) ?? now
            let next = calendar.date(byAdding: .minute, value: minutes, to: nextDay) ?? now
            due = now >= next
        } else { due = now >= scheduled }
        guard due else { return }
        do {
            var stale = false
            let folder = try URL(resolvingBookmarkData: bookmark, options: [], relativeTo: nil, bookmarkDataIsStale: &stale)
            let access = folder.startAccessingSecurityScopedResource()
            defer { if access { folder.stopAccessingSecurityScopedResource() } }
            if stale { defaults.set(try folder.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil), forKey: "backupFolder") }
            let formatter = DateFormatter(); formatter.dateFormat = "yyyy-MM-dd-HHmmss"
            let file = folder.appendingPathComponent("Adarsh-Auto-Backup-\(formatter.string(from: now)).json")
            try repository.backupData().write(to: file, options: .atomic)
            defaults.set(now.timeIntervalSince1970, forKey: "backupLastSuccess")
            defaults.removeObject(forKey: "backupAutomaticError")
        } catch {
            defaults.set("Backup could not be saved. Check your iCloud folder and available space, or select the folder again.", forKey: "backupAutomaticError")
        }
    }
}
