import SwiftUI

struct AddTitleSheet: View {
    @ObservedObject var viewModel: EditorViewModel
    @FocusState private var titleFocused: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add New Title").font(.system(.title3, design: .rounded, weight: .bold))
            VStack(alignment: .leading, spacing: 6) {
                Text("Title name").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                TextField("For example, Landscaping", text: $viewModel.newTitle)
                    .textFieldStyle(AgreementInputStyle())
                    .accessibilityIdentifier("newWorkTitle")
                    .focused($titleFocused).submitLabel(.done)
                    .onSubmit { if viewModel.canAddTitle { viewModel.addTitle() } }
            }
            Text("The title will be added to this agreement with its next letter. You can add specifications in its work screen.")
                .font(.caption).foregroundStyle(.secondary)
            Spacer(minLength: 8)
            HStack(spacing: 12) {
                Button("Cancel") { viewModel.cancelAddingTitle() }
                    .buttonStyle(AgreementButtonStyle(kind: .secondary))
                Button("Save") { viewModel.addTitle() }
                    .buttonStyle(AgreementButtonStyle())
                    .disabled(!viewModel.canAddTitle)
                    .accessibilityIdentifier("saveNewTitle")
            }
        }.padding(20).background(AgreementTheme.surface)
            .presentationDetents([.height(300), .medium, .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(20)
            .onAppear { titleFocused = true }
    }
}
