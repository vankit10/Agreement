import SwiftUI

struct CompanySettingsView: View {
    @EnvironmentObject var store: DocumentsViewModel
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = CompanySettingsViewModel()
    @AppStorage("appLanguage") private var appLanguage = "system"
    // Keep translation on-device unless the person using the app explicitly opts in.
    // Translation clients should read this same key before making any network request.
    @AppStorage("onlineTranslationEnabled") private var onlineTranslationEnabled = false
    var body: some View {
        NavigationStack {
            Form {
                Section("Language") {
                    Picker("App language", selection: $appLanguage) {
                        Text("System default").tag("system")
                        Text("English").tag("en")
                        Text("Hindi").tag("hi")
                    }
                    Toggle("Use online translation", isOn: $onlineTranslationEnabled)
                    Text(onlineTranslationEnabled
                         ? "Online translation is enabled. Text may be sent to the translation service."
                         : "Translation stays on this device using the app’s bundled languages.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
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
                BackupSettingsSection()
            }.agreementForm().navigationTitle("Company Settings").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) { Button("Save") { if viewModel.save(to: store) { dismiss() } } }
                }.onAppear { viewModel.load(from: store) }
                .onChange(of: store.branding) { _, _ in viewModel.load(from: store) }
                .alert("Company settings", isPresented: Binding(get: { store.error != nil }, set: { if !$0 { store.error = nil } })) {
                    Button("Retry Save") { if viewModel.save(to: store) { dismiss() } }
                    Button("Keep Editing", role: .cancel) { store.error = nil }
                } message: { Text(store.error ?? "") }
        }
    }
}
