import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: DocumentsViewModel
    @StateObject private var viewModel = HomeViewModel()
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 16) {
                        BrandImage().frame(width: 74, height: 66).padding(8)
                            .background(.white, in: RoundedRectangle(cornerRadius: 16))
                        VStack(alignment: .leading, spacing: 5) {
                            Text("ADARSH").font(.system(.title2, design: .rounded, weight: .bold)).tracking(1.5).foregroundStyle(AgreementTheme.accent)
                            Text("INFRADEVELOPERS\nAND CONSTRUCTIONS").font(.system(.caption, design: .rounded, weight: .medium)).foregroundStyle(.secondary).lineSpacing(3)
                        }
                        Spacer()
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        Label("YOUR PROJECT WORKSPACE", systemImage: "building.2.crop.circle").font(.caption.weight(.semibold)).tracking(0.7).foregroundStyle(AgreementTheme.accent)
                        Text("Every project starts with a clear agreement.").font(.system(.title, design: .rounded, weight: .bold)).fixedSize(horizontal: false, vertical: true)
                        Text("Build, save and share construction agreements with your company’s original branding.")
                            .font(.subheadline).foregroundStyle(.secondary).lineSpacing(4)
                        Button { viewModel.create(using: store) } label: {
                            Label("Create Document", systemImage: "plus.circle.fill")
                        }.buttonStyle(AgreementButtonStyle())
                        Button { viewModel.saved = true } label: {
                            Label("Saved Documents", systemImage: "folder")
                        }.buttonStyle(AgreementButtonStyle(kind: .secondary))
                    }.padding(18).agreementCard()
                    HStack {
                        Text("Recent documents").font(.title3.bold())
                        Spacer()
                        Text("\(store.documents.count) saved").font(.caption.weight(.medium)).foregroundStyle(AgreementTheme.accent).padding(.horizontal, 10).padding(.vertical, 6).background(AgreementTheme.accent.opacity(0.08), in: Capsule())
                    }
                    if store.documents.isEmpty {
                        ContentUnavailableView("Your next project belongs here", systemImage: "doc.text", description: Text("Create an agreement and save a draft at any step."))
                    } else {
                        ForEach(store.documents.prefix(4)) { d in
                            Button { viewModel.open(d) } label: { DocumentRow(document: d) }.buttonStyle(.plain)
                        }
                    }
                    Label("Available offline · Stored on this device", systemImage: "lock.shield").font(.caption).foregroundStyle(.secondary)
                }.padding(AgreementTheme.margin).frame(maxWidth: 760)
                    .frame(maxWidth: .infinity)
            }.background(AgreementTheme.canvas)
                .navigationTitle("Agreement Builder").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { viewModel.settings = true } label: { Image(systemName: "gearshape") }.accessibilityLabel("Company Settings") } }
                .navigationDestination(item: $viewModel.route) { EditorView(document: $0.document).environmentObject(store) }
                .sheet(isPresented: $viewModel.settings) { CompanySettingsView().environmentObject(store) }
                .navigationDestination(isPresented: $viewModel.saved) { SavedDocumentsView() }
                .alert("Local storage", isPresented: Binding(get: { store.error != nil }, set: { if !$0 { store.error = nil } })) {
                    Button("OK") { store.error = nil }
                } message: { Text(store.error ?? "") }
        }
    }
}
