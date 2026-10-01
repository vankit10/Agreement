import SwiftUI

struct CompanySettingsView: View {
    @EnvironmentObject var store: DocumentsViewModel
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = CompanySettingsViewModel()
    var body: some View {
        NavigationStack {
            Form {
                Section("Company identity") {
                    BrandImage().frame(height: 110).frame(maxWidth: .infinity)
                    TextField("Company name", text: $viewModel.branding.name, axis: .vertical)
                    TextField("Signature company name", text: $viewModel.branding.signatureName, axis: .vertical)
                    TextField("Phone numbers", text: $viewModel.branding.phones)
                    TextField("Address", text: $viewModel.branding.address, axis: .vertical)
                    TextField("Email", text: $viewModel.branding.email).textInputAutocapitalization(.never).keyboardType(.emailAddress)
                    TextField("Website", text: $viewModel.branding.website).textInputAutocapitalization(.never).keyboardType(.URL)
                }
                Section("Reference branding") {
                    TextField("Instagram label", text: $viewModel.branding.instagram)
                    TextField("Facebook label", text: $viewModel.branding.facebook, axis: .vertical)
                    CompactToggle(title: "Include trailing branding page", isOn: $viewModel.branding.trailingBrandPage)
                    Text("Changes apply to new agreements. Existing agreements keep their saved company details.").font(.caption).foregroundStyle(.secondary)
                }
            }.agreementForm().navigationTitle("Company Settings").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) { Button("Save") { if viewModel.save(to: store) { dismiss() } } }
                }.onAppear { viewModel.load(from: store) }
                .alert("Company settings", isPresented: Binding(get: { store.error != nil }, set: { if !$0 { store.error = nil } })) {
                    Button("Retry Save") { if viewModel.save(to: store) { dismiss() } }
                    Button("Keep Editing", role: .cancel) { store.error = nil }
                } message: { Text(store.error ?? "") }
        }
    }
}
