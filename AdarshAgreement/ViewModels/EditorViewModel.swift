import SwiftUI

enum WizardStep: Equatable {
    case details, selection, work(String), fees, terms, extras, payments, signatures, review
    var title: String {
        switch self {
        case .details: "Client & project"
        case .selection: "Scope of work"
        case .work: "Specifications"
        case .fees: "Fees & measurements"
        case .terms: "Terms & conditions"
        case .extras: "Extra work"
        case .payments: "Payment schedule"
        case .signatures: "Signatures"
        case .review: "Review agreement"
        }
    }
}

@MainActor
final class EditorViewModel: ObservableObject {
    @Published var document: Agreement
    @Published var showIssues = false
    @Published var preview: PreviewRoute?
    @Published var savedMessage = ""
    @Published var addingTitle = false
    @Published var newTitle = ""
    private var autosave: Task<Void, Never>?
    private var openReady = false
    private weak var store: DocumentsViewModel?
    init(document: Agreement) { self.document = document }
    var steps: [WizardStep] {
        [.details, .selection] + document.sections.filter(\.included).map { .work($0.id) } + [.fees, .terms, .extras, .payments, .signatures, .review]
    }
    var index: Int { min(max(document.step, 0), steps.count - 1) }
    var current: WizardStep { steps[index] }
    var issues: [ValidationIssue] { Validator.issues(document) }
    var canAddTitle: Bool { !newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    func stepTitle(_ step: WizardStep) -> String {
        if case .work(let id) = step { return document.sectionTitle(for: id) }
        if case .fees = step { return "\(document.feesLetter). Fees & measurements" }
        return step.title
    }
    func appear(store: DocumentsViewModel) {
        self.store = store
        document.restoreMissingReferenceWording()
        if document.step >= steps.count { document.step = steps.count - 1; generatePreview() }
        else if document.status == "Ready" && !openReady { openReady = true; document.step = steps.count - 1; generatePreview() }
    }
    func back() { document.step = max(index - 1, 0); showIssues = false }
    func next() {
        if index == steps.count - 1 { generatePreview() }
        else { document.step = index + 1; showIssues = true }
    }
    func jump(to step: Int) { document.step = step }
    func close() -> Bool { autosave?.cancel(); return store?.save(&document) ?? false }
    func saveDraft() {
        autosave?.cancel()
        if store?.save(&document, announce: true) == true { savedMessage = "Draft saved" }
    }
    func generatePreview() {
        showIssues = true; autosave?.cancel()
        guard issues.isEmpty else {
            AppLog.validation.notice("Preview blocked by validation; issue count=\(self.issues.count, privacy: .public)")
            document.step = steps.count - 1; return
        }
        do {
            guard let store else { throw CocoaError(.fileWriteUnknown) }
            preview = PreviewRoute(url: try store.pdf(&document)); savedMessage = "Document saved"
        } catch { store?.error = AppLog.message(.pdf, error) }
    }
    func documentChanged(from old: Agreement, to new: Agreement) {
        var a = old; var b = new
        a.modified = a.created; b.modified = b.created; a.revision = 0; b.revision = 0
        a.status = ""; b.status = ""; a.pdfFingerprint = nil; b.pdfFingerprint = nil
        let navigationChanged = a.step != b.step; a.step = 0; b.step = 0
        let contentChanged = a != b
        guard contentChanged || navigationChanged else { return }
        if contentChanged { document.status = "Draft"; document.pdfFingerprint = nil }
        savedMessage = ""; autosave?.cancel()
        autosave = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(650))
            guard !Task.isCancelled, let self else { return }
            if self.store?.save(&self.document) == true { self.savedMessage = "Saved" }
        }
    }
    func background() { AppLog.lifecycle.debug("Saving editor on background transition"); autosave?.cancel(); _ = store?.save(&document) }
    func disappear() { autosave?.cancel() }
    func beginAddingTitle() { newTitle = ""; addingTitle = true }
    func cancelAddingTitle() { newTitle = ""; addingTitle = false }
    func addTitle() {
        guard document.addWorkTitle(newTitle) else { return }
        newTitle = ""; addingTitle = false
        saveDraft()
    }
    func removeTitle(_ id: String) { document.sections.removeAll { $0.id == id } }
    func addClause() { document.terms.append(Clause(id: UUID().uuidString, text: "")) }
    func addExtra() { document.extras.append(ExtraWork(id: UUID().uuidString, label: "Custom extra")) }
    func addMilestone() { document.milestones.append(Milestone(label: "", percent: "")) }
    func removeMilestones(_ offsets: IndexSet) { document.milestones.remove(atOffsets: offsets) }
    func useFullTaxableSubtotal() { document.taxableAmount = NSDecimalNumber(decimal: document.subtotal).stringValue }
    func normalizeFloors() {
        for i in document.floors.indices { document.floors[i].included = !document.floors[i].area.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    func areaBinding(for id: UUID) -> Binding<String> {
        Binding(get: { self.document.floors.first(where: { $0.id == id })?.area ?? "" }, set: { value in
            guard let i = self.document.floors.firstIndex(where: { $0.id == id }) else { return }
            self.document.floors[i].area = value
            self.document.floors[i].included = !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        })
    }
    func priceGateSeparately() {
        if let s = document.sections.firstIndex(where: { $0.id == "J" }), let i = document.sections[s].items.firstIndex(where: { $0.id == "J-gate" }) { document.sections[s].items[i].included = false }
        if !document.extras.contains(where: { $0.id == "gate" }) { document.extras.append(ExtraWork(id: "gate", label: "Main gate", pricing: .priced, quantity: "1", unit: "gate", rate: "25000")) }
    }
}

struct PreviewRoute: Identifiable { let id = UUID(); let url: URL }
