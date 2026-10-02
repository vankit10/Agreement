import SwiftUI
import UniformTypeIdentifiers
import PDFKit

struct EditorView: View {
    @EnvironmentObject var store: DocumentsViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var viewModel: EditorViewModel
    @State private var uploadingDesign = false
    @State private var designKind = "House plan / map"
    init(document: Agreement) {
        _viewModel = StateObject(wrappedValue: EditorViewModel(document: document))
    }
    var body: some View {
        Group {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Step \(viewModel.index + 1) of \(viewModel.steps.count)").font(.caption.weight(.semibold)).foregroundStyle(AgreementTheme.accent)
                            .padding(.horizontal, 10).padding(.vertical, 6).background(AgreementTheme.accent.opacity(0.08), in: Capsule())
                        Spacer()
                        if !viewModel.savedMessage.isEmpty { Label(viewModel.savedMessage, systemImage: "checkmark.circle.fill").font(.caption).foregroundStyle(.green) }
                    }
                    ProgressView(value: Double(viewModel.index + 1), total: Double(viewModel.steps.count))
                        .tint(AgreementTheme.accent)
                        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: viewModel.index)
                    Text(viewModel.stepTitle(viewModel.current)).font(.system(.title3, design: .rounded, weight: .bold))
                        .fixedSize(horizontal: false, vertical: true)
                }.padding(16).agreementCard().padding(.horizontal, AgreementTheme.margin).padding(.vertical, 8)
                Form {
                    if viewModel.showIssues {
                        ForEach(viewModel.issues.filter { $0.step == viewModel.index }) { issue in Text(issue.message).foregroundStyle(.red).font(.callout) }
                    }
                    switch viewModel.current {
                    case .details: details
                    case .selection: selection
                    case .work(let id):
                        if let i = viewModel.document.sections.firstIndex(where: { $0.id == id }) {
                            WorkSectionEditor(section: $viewModel.document.sections[i], showIssues: viewModel.showIssues, onRemoveTitle: viewModel.removeTitle)
                                .id(id)
                        }
                    case .fees: fees
                    case .terms: terms
                    case .extras: extras
                    case .payments: payments
                    case .signatures: signatures
                    case .review: review
                    }
                }.agreementForm().scrollDismissesKeyboard(.interactively)
                VStack(spacing: 8) {
                    HStack {
                        Button { viewModel.back() } label: {
                            Label("Back", systemImage: "chevron.left").font(.subheadline.weight(.semibold)).frame(minHeight: 44)
                        }.disabled(viewModel.index == 0)
                        Spacer()
                        Button { viewModel.saveDraft() } label: {
                            Label("Save Draft", systemImage: "square.and.arrow.down").font(.subheadline.weight(.semibold)).frame(minHeight: 44)
                        }
                    }
                    Button(viewModel.index == viewModel.steps.count - 1 ? "Generate Preview" : "Next") {
                        viewModel.next()
                    }.buttonStyle(AgreementButtonStyle())
                }.padding(.horizontal, 20).padding(.top, 4).padding(.bottom, 8)
                    .background(AgreementTheme.surface)
                    .overlay(alignment: .top) { Rectangle().fill(AgreementTheme.border).frame(height: 1) }
                    .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: -4)
            }.frame(maxWidth: 820).frame(maxWidth: .infinity).background(AgreementTheme.canvas)
                .background(KeyboardDismissOnOutsideTap().frame(width: 0, height: 0))
                .sensoryFeedback(.selection, trigger: viewModel.index)
                .navigationTitle(viewModel.document.displayName).navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(true)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { if viewModel.close() { dismiss() } } } }
                .onChange(of: viewModel.document) { old, new in viewModel.documentChanged(from: old, to: new) }
                .onChange(of: scenePhase) { _, phase in if phase != .active { viewModel.background() } }
                .onDisappear { viewModel.disappear() }
                .sheet(item: $viewModel.preview) { route in PDFPreviewScreen(url: route.url, filename: viewModel.document.filename).environmentObject(store) }
                .sheet(isPresented: $viewModel.addingTitle, onDismiss: { viewModel.cancelAddingTitle() }) {
                    AddTitleSheet(viewModel: viewModel)
                }
                .alert("Could not complete action", isPresented: Binding(get: { store.error != nil }, set: { if !$0 { store.error = nil } })) {
                    Button("Retry Save") { store.error = nil; viewModel.saveDraft() }
                    Button("Keep Editing", role: .cancel) { store.error = nil }
                } message: { Text(store.error ?? "") }
                .onAppear { viewModel.appear(store: store) }
                .fileImporter(isPresented: $uploadingDesign, allowedContentTypes: [.image, .pdf]) { result in
                    do {
                        let url = try result.get()
                        let access = url.startAccessingSecurityScopedResource()
                        defer { if access { url.stopAccessingSecurityScopedResource() } }
                        let data = try Data(contentsOf: url)
                        guard data.count <= 20 * 1024 * 1024 else { store.error = "Choose a file smaller than 20 MB."; return }
                        let isPDF = url.pathExtension.lowercased() == "pdf"
                        guard isPDF ? PDFDocument(data: data) != nil : UIImage(data: data) != nil else {
                            store.error = "Choose a readable image or PDF."; return
                        }
                        var designs = viewModel.document.houseDesigns ?? []
                        designs.removeAll { $0.kind == designKind }
                        designs.append(HouseDesignAttachment(kind: designKind, filename: url.lastPathComponent, data: data, isPDF: isPDF))
                        viewModel.document.houseDesigns = designs
                        viewModel.saveDraft()
                    } catch { store.error = "Could not import the design. Please choose the file again." }
                }
        }
    }
    private func field(_ label: String, _ value: Binding<String>, key: String = "", multiline: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            TextField(label, text: value, axis: multiline ? .vertical : .horizontal)
            if viewModel.showIssues, let issue = viewModel.issues.first(where: { $0.id == key }) { Text(issue.message).font(.caption).foregroundStyle(.red) }
        }.padding(.vertical, 2)
    }
    private var details: some View {
        Group {
        Section("Agreement details") {
            field("Document title", $viewModel.document.title, key: "title")
            field("Client name", $viewModel.document.clientName, key: "clientName")
            field("Address", $viewModel.document.address, key: "address", multiline: true)
            field("Mobile", $viewModel.document.mobile, key: "mobile").keyboardType(.phonePad)
            field("Subject", $viewModel.document.subject, key: "subject", multiline: true)
            field("Project location", $viewModel.document.location, multiline: true)
            field("Introductory wording", $viewModel.document.introduction, multiline: true)
        }
        Section("House designs (optional)") {
            Text("Add a house plan or 3D design now, or reopen this agreement to add them later. Images and PDFs up to 20 MB each.").font(.caption).foregroundStyle(.secondary)
            ForEach(["House plan / map", "3D house design"], id: \.self) { kind in
                VStack(alignment: .leading, spacing: 8) {
                    Text(kind).font(.subheadline.weight(.semibold))
                    if let attachment = viewModel.document.houseDesigns?.first(where: { $0.kind == kind }) {
                        Text(attachment.filename).font(.caption).foregroundStyle(.secondary)
                        if !attachment.isPDF, let image = UIImage(data: attachment.data) {
                            Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 140)
                        }
                        CompactToggle(title: "Include in agreement PDF", isOn: Binding(get: {
                            viewModel.document.houseDesigns?.first(where: { $0.kind == kind })?.includedInPDF ?? false
                        }, set: { included in
                            if let i = viewModel.document.houseDesigns?.firstIndex(where: { $0.kind == kind }) { viewModel.document.houseDesigns?[i].includedInPDF = included }
                        }))
                        Button("Remove file", role: .destructive) { viewModel.document.houseDesigns?.removeAll { $0.kind == kind } }
                    }
                    Button(viewModel.document.houseDesigns?.contains(where: { $0.kind == kind }) == true ? "Replace file" : "Upload file") {
                        designKind = kind; uploadingDesign = true
                    }
                }.padding(.vertical, 4)
            }
        }
        }
    }
    private var selection: some View {
        Group {
            Section {
                Text("Choose the work included in this agreement. Specifications follow in reference order.").foregroundStyle(.secondary)
                ForEach($viewModel.document.sections) { $section in
                    HStack(spacing: 12) {
                        leadingToggle(viewModel.document.sectionTitle(for: section.id), isOn: $section.included)
                        Button(role: .destructive) { viewModel.removeTitle(section.id) } label: {
                            Image(systemName: "minus").font(.headline.weight(.bold))
                                .frame(width: 44, height: 44)
                                .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                        }.buttonStyle(.borderless).accessibilityLabel("Remove title \(section.title)")
                    }.padding(.vertical, 4)
                }
            } header: { Text("Work titles") } footer: { Text("Included titles are lettered automatically. Use − to remove a title; switch it off to keep its draft values.") }
            Section {
                Button { viewModel.beginAddingTitle() } label: {
                    Label("Add New Title", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 8)
                }.buttonStyle(AgreementButtonStyle(kind: .secondary)).accessibilityIdentifier("addNewTitle")
            } footer: { Text("New titles get their own specification step and appear in the agreement PDF.") }
        }
    }
    private var fees: some View {
        Group {
            ForEach($viewModel.document.floors) { $floor in
                Section(floor.name) {
                    field("Area (sq ft)", viewModel.areaBinding(for: floor.id), key: floor.id.uuidString + "area").keyboardType(.decimalPad)
                    field("Rate (₹ / sq ft)", $floor.rate, key: floor.id.uuidString + "rate").keyboardType(.decimalPad)
                    LabeledContent("Cost", value: rupees(floor.included ? number(floor.area) * number(floor.rate) : 0))
                    Text("Leave area blank if this floor is not part of the project.").font(.caption).foregroundStyle(.secondary)
                }
            }
            Section("Staircase double measurement") {
                field("Additional area (sq ft)", $viewModel.document.staircaseArea).keyboardType(.decimalPad)
                field("Rate (₹ / sq ft)", $viewModel.document.staircaseRate).keyboardType(.decimalPad)
                leadingToggle("I confirm this area is not already included", isOn: $viewModel.document.staircaseConfirmed)
            }
            Section("Calculation") { totals; field("Area note", $viewModel.document.areaNote, multiline: true) }
        }.onAppear { viewModel.normalizeFloors() }
    }
    private var terms: some View {
        Group {
            Section("Reference clauses") {
                ForEach($viewModel.document.terms) { $clause in
                    HStack(alignment: .top, spacing: 12) {
                        CompactToggle(title: clause.text.isEmpty ? "Include custom clause" : "Include \(clause.text)", isOn: $clause.included, showsTitle: false)
                        TextField("Clause wording", text: $clause.text, axis: .vertical)
                    }.padding(.vertical, 5)
                }
                Button("Add Custom Clause") { viewModel.addClause() }
            }
            Section("Tax calculation") {
                leadingToggle("Apply tax to total", isOn: $viewModel.document.taxEnabled)
                if viewModel.document.taxEnabled {
                    field("Tax percentage", $viewModel.document.taxPercent, key: "taxPercent").keyboardType(.decimalPad)
                    field("Taxable amount (₹)", $viewModel.document.taxableAmount, key: "taxableAmount").keyboardType(.decimalPad)
                    Button("Use full subtotal") { viewModel.useFullTaxableSubtotal() }
                }
                Text("The reference tax clause is editable wording. Enable this switch separately to calculate tax, and keep the wording consistent with the chosen rate.").font(.caption).foregroundStyle(.secondary)
            }
            Section("Late payment clause") {
                leadingToggle("Late payment clause", isOn: $viewModel.document.penaltyEnabled)
                if viewModel.document.penaltyEnabled {
                    field("Penalty percentage", $viewModel.document.penaltyPercent).keyboardType(.decimalPad)
                    field("Clause wording ({percent} inserts percentage)", $viewModel.document.penaltyWording, multiline: true)
                }
                Text("The clause does not increase the agreement total.").font(.caption).foregroundStyle(.secondary)
            }
        }
    }
    private func leadingToggle(_ text: String, isOn: Binding<Bool>) -> some View {
        CompactToggle(title: text, isOn: isOn)
    }
    private var extras: some View {
        Group {
            ForEach($viewModel.document.extras) { $extra in
                Section(extra.label) {
                    leadingToggle(extra.label, isOn: $extra.included)
                    if extra.included {
                        field("Label", $extra.label)
                        Picker("Pricing status", selection: $extra.pricing) { ForEach(PricingStatus.allCases, id: \.self) { Text($0.rawValue).tag($0) } }
                        field("Quantity", $extra.quantity).keyboardType(.decimalPad)
                        field("Unit", $extra.unit)
                        field("Rate (₹)", $extra.rate).keyboardType(.decimalPad)
                        field("Notes", $extra.notes, multiline: true)
                        if extra.pricing == .priced { LabeledContent("Extra cost", value: rupees(extra.amount)) }
                    }
                }
            }
            Section {
                Button("Add Custom Extra") { viewModel.addExtra() }
                Button("Price main gate separately") {
                    viewModel.priceGateSeparately()
                }
            }
        }
    }
    private var payments: some View {
        Group {
            Section("Payable amount") {
                leadingToggle("Use total including tax", isOn: $viewModel.document.paymentUsesTotal)
                LabeledContent("Payment base", value: rupees(viewModel.document.payable))
            }
            Section("Milestones") {
                ForEach(Array(viewModel.document.milestones.indices), id: \.self) { i in
                    VStack(alignment: .leading, spacing: 8) {
                        field("Milestone", $viewModel.document.milestones[i].label)
                        field("Percentage", $viewModel.document.milestones[i].percent).keyboardType(.decimalPad)
                        if viewModel.document.milestones.reduce(Decimal(0), { $0 + number($1.percent) }) == 100 { Text(rupees(viewModel.document.milestoneAmounts[i])).font(.headline).foregroundStyle(.blue) }
                    }
                }.onDelete { viewModel.removeMilestones($0) }
                Button("Add Milestone") { viewModel.addMilestone() }
                LabeledContent("Percentage total", value: NSDecimalNumber(decimal: viewModel.document.milestones.reduce(Decimal(0), { $0 + number($1.percent) })).stringValue + "%")
            }
        }
    }
    private var signatures: some View {
        Section("Names for blank signature lines") {
            field("Company signer", $viewModel.document.companySigner)
            field("Accepted by", $viewModel.document.clientSigner)
            field("Witness 1", $viewModel.document.witness1)
            field("Witness 2", $viewModel.document.witness2)
            Text("PDF includes company and client signature lines plus two witnesses.").font(.caption).foregroundStyle(.secondary)
        }
    }
    private var totals: some View {
        Group {
            LabeledContent("Base cost", value: rupees(viewModel.document.baseCost))
            ForEach(viewModel.document.specificationCharges) { item in
                LabeledContent(item.label, value: rupees(item.fixedCharge))
            }
            LabeledContent("Priced extras", value: rupees(viewModel.document.extrasCost))
            LabeledContent("Subtotal", value: rupees(viewModel.document.subtotal))
            LabeledContent("Tax", value: rupees(viewModel.document.tax))
            LabeledContent("Total", value: rupees(viewModel.document.total)).font(.headline)
        }
    }
    private var review: some View {
        Group {
            if !viewModel.issues.isEmpty {
                Section("Complete before generating PDF") {
                    ForEach(viewModel.issues) { issue in Button { viewModel.jump(to: issue.step); viewModel.showIssues = true } label: { Label(issue.message, systemImage: "exclamationmark.circle").foregroundStyle(.red) } }
                }
            }
            if !viewModel.document.warnings.isEmpty { Section("Review reference wording") { ForEach(viewModel.document.warnings, id: \.self) { Text($0).foregroundStyle(.orange) } } }
            Section { totals }
            ForEach(Array(viewModel.steps.dropLast().enumerated()), id: \.offset) { i, step in
                Section {
                    HStack { Text(viewModel.stepTitle(step)).font(.headline); Spacer(); Button("Edit") { viewModel.jump(to: i) } }
                    switch step {
                    case .details: Text("\(viewModel.document.clientName)\n\(viewModel.document.address)\n\(viewModel.document.mobile)\n\(viewModel.document.subject)\n\(viewModel.document.introduction)")
                    case .selection: Text("Omitted: " + viewModel.document.sections.filter { !$0.included }.map(\.title).joined(separator: ", "))
                    case .work(let id): if let s = viewModel.document.sections.first(where: { $0.id == id }) { ForEach(s.items.filter(\.included)) { Text($0.output) } }
                    case .fees: ForEach(viewModel.document.floors.filter(\.included)) { Text("\($0.name): \($0.area) sq ft @ \(rupees(number($0.rate)))") }; Text(viewModel.document.areaNote)
                    case .terms: ForEach(viewModel.document.terms.filter(\.included)) { Text($0.text) }; if viewModel.document.penaltyEnabled { Text(viewModel.document.penaltyWording.replacingOccurrences(of: "{percent}", with: viewModel.document.penaltyPercent)) }
                    case .extras: ForEach(viewModel.document.extras.filter(\.included)) { Text("\($0.label) · \($0.pricing.rawValue) · \(rupees($0.amount))") }
                    case .payments: ForEach(viewModel.document.milestones) { Text("\($0.label): \($0.percent)%") }
                    case .signatures: Text("For: \(viewModel.document.companySigner)\nAccepted by: \(viewModel.document.clientSigner.isEmpty ? viewModel.document.clientName : viewModel.document.clientSigner)\nWitnesses: \(viewModel.document.witness1), \(viewModel.document.witness2)")
                    case .review: EmptyView()
                    }
                }
            }
        }
    }
}
