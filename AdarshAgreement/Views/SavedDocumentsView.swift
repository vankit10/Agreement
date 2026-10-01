import SwiftUI

struct SavedDocumentsView: View {
    @EnvironmentObject var store: DocumentsViewModel
    @StateObject private var viewModel = SavedDocumentsViewModel()
    var body: some View {
        List {
            ForEach(viewModel.matches(in: store.documents)) { d in
                Button { viewModel.open(d) } label: { DocumentRow(document: d) }.buttonStyle(.plain)
                    .accessibilityIdentifier("savedDocument-\(d.id.uuidString)")
                    .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20)).listRowBackground(Color.clear).listRowSeparator(.hidden)
                    .contextMenu {
                        Button("Edit") { viewModel.edit(d) }
                        Button("Export PDF") { viewModel.export(d) }
                        Button("Duplicate") { store.duplicate(d) }
                        Button("Delete", role: .destructive) { viewModel.deleting = d }
                    }
                    .swipeActions { Button("Delete", role: .destructive) { viewModel.deleting = d }; Button("Duplicate") { store.duplicate(d) }.tint(.blue) }
            }
        }.listStyle(.plain).scrollContentBackground(.hidden).background(AgreementTheme.canvas)
            .navigationTitle("Saved Documents").searchable(text: $viewModel.query, prompt: "Client, title or location")
            .overlay { if viewModel.matches(in: store.documents).isEmpty { ContentUnavailableView.search(text: viewModel.query) } }
            .navigationDestination(item: $viewModel.route) { EditorView(document: $0.document).environmentObject(store) }
            .confirmationDialog("Delete this agreement and its PDF?", isPresented: Binding(get: { viewModel.deleting != nil }, set: { if !$0 { viewModel.deleting = nil } }), titleVisibility: .visible) {
                Button("Delete Agreement", role: .destructive) { viewModel.confirmDelete(using: store) }
                Button("Cancel", role: .cancel) { viewModel.deleting = nil }
            }
    }
}
