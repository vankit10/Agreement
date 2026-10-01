import SwiftUI

@MainActor
final class SavedDocumentsViewModel: ObservableObject {
    @Published var query = ""
    @Published var route: EditorRoute?
    @Published var deleting: Agreement?
    func matches(in documents: [Agreement]) -> [Agreement] {
        documents.filter { query.isEmpty || [$0.clientName, $0.title, $0.subject, $0.location].joined(separator: " ").localizedCaseInsensitiveContains(query) }
    }
    func open(_ document: Agreement) { route = EditorRoute(document: document) }
    func edit(_ document: Agreement) { var copy = document; copy.step = 0; open(copy) }
    func export(_ document: Agreement) { var copy = document; copy.step = Int.max; open(copy) }
    func confirmDelete(using store: DocumentsViewModel) { if let deleting { store.delete(deleting) }; deleting = nil }
}
