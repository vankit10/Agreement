import SwiftUI
import PDFKit
import UniformTypeIdentifiers


struct PDFFile: FileDocument {
    static var readableContentTypes: [UTType] { [.pdf] }
    var data: Data
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws { data = configuration.file.regularFileContents ?? Data() }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}

struct PDFPreviewScreen: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: PDFPreviewViewModel
    init(url: URL, filename: String) {
        _viewModel = StateObject(wrappedValue: PDFPreviewViewModel(url: url, filename: filename))
    }
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Button { viewModel.previousPage() } label: { Image(systemName: "chevron.left").font(.headline).frame(width: 44, height: 44).background(AgreementTheme.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 12)) }.disabled(viewModel.page == 1).accessibilityLabel("Previous page")
                    Spacer(); Text("Page \(viewModel.page) of \(viewModel.count)").font(.subheadline.weight(.semibold)).monospacedDigit(); Spacer()
                    Button { viewModel.nextPage() } label: { Image(systemName: "chevron.right").font(.headline).frame(width: 44, height: 44).background(AgreementTheme.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 12)) }.disabled(viewModel.page == viewModel.count).accessibilityLabel("Next page")
                }.padding(.horizontal, 20).padding(.vertical, 12).background(AgreementTheme.surface)
                PDFKitView(url: viewModel.url, page: $viewModel.page, count: $viewModel.count, onFailure: viewModel.previewFailed)
                Text(viewModel.status).font(.caption).foregroundStyle(.secondary).padding(10)
                VStack(spacing: 12) {
                    Button { viewModel.download() } label: { Label("Download PDF", systemImage: "arrow.down.document") }.buttonStyle(AgreementButtonStyle())
                    HStack {
                        Button("Save Document") { viewModel.save() }.buttonStyle(AgreementButtonStyle(kind: .secondary))
                        Button { viewModel.share() } label: { Label("Share", systemImage: "square.and.arrow.up") }.buttonStyle(AgreementButtonStyle(kind: .secondary)).accessibilityLabel("Share PDF")
                    }
                }.padding(20).background(AgreementTheme.surface).shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: -4)
            }.navigationTitle("PDF Preview").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
                .fileExporter(isPresented: $viewModel.export, document: viewModel.data.map { PDFFile(data: $0) }, contentType: .pdf, defaultFilename: viewModel.filename) { result in
                    viewModel.exportCompleted(result)
                }
                .sheet(isPresented: $viewModel.sharing) { if let url = viewModel.shareURL { ShareSheet(url: url) } }
                .alert("PDF export", isPresented: Binding(get: { viewModel.error != nil }, set: { if !$0 { viewModel.error = nil } })) {
                    Button("Retry") { viewModel.error = nil; viewModel.download() }
                    Button("Cancel", role: .cancel) { viewModel.error = nil }
                } message: { Text(viewModel.error ?? "") }
        }
    }
}

struct PDFKitView: UIViewRepresentable {
    let url: URL
    @Binding var page: Int
    @Binding var count: Int
    var onFailure: (Error) -> Void
    func makeUIView(context: Context) -> PDFView {
        let view = PDFView(); view.document = PDFDocument(url: url); view.autoScales = true
        if view.document == nil { DispatchQueue.main.async { onFailure(AppError.invalidPDF) } }
        view.displayMode = .singlePageContinuous; view.displayDirection = .vertical
        context.coordinator.view = view
        context.coordinator.observer = NotificationCenter.default.addObserver(forName: .PDFViewPageChanged, object: view, queue: .main) { [weak coordinator = context.coordinator] _ in
            guard let c = coordinator, let view = c.view, let doc = view.document, let current = view.currentPage else { return }
            DispatchQueue.main.async { c.parent.page = doc.index(for: current) + 1 }
        }
        DispatchQueue.main.async { count = view.document?.pageCount ?? 1 }
        return view
    }
    func updateUIView(_ view: PDFView, context: Context) {
        context.coordinator.parent = self
        if let doc = view.document, let target = doc.page(at: page - 1), view.currentPage != target { view.go(to: target) }
    }
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    final class Coordinator {
        var parent: PDFKitView; weak var view: PDFView?; var observer: NSObjectProtocol?
        init(_ parent: PDFKitView) { self.parent = parent }
        deinit { if let observer { NotificationCenter.default.removeObserver(observer) } }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController {
        return UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
