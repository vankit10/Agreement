import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var route: EditorRoute?
    @Published var saved = false
    @Published var settings = false
    func create(using store: DocumentsViewModel) { route = EditorRoute(document: store.newDocument()) }
    func open(_ document: Agreement) { route = EditorRoute(document: document) }
}
