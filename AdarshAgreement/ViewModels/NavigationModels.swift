import SwiftUI

struct EditorRoute: Identifiable, Hashable {
    var id: UUID { document.id }
    var document: Agreement
    static func == (lhs: EditorRoute, rhs: EditorRoute) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
