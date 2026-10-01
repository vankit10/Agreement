import SwiftUI

@MainActor
final class CompanySettingsViewModel: ObservableObject {
    @Published var branding = Branding()
    func load(from store: DocumentsViewModel) { branding = store.branding }
    func save(to store: DocumentsViewModel) -> Bool { store.branding = branding; store.saveBranding(); return store.error == nil }
}
