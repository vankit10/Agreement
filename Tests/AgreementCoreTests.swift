import XCTest
@testable import AgreementCore

final class AgreementCoreTests: XCTestCase {
    func validDocument() -> Agreement {
        var d = Agreement(); d.clientName = "Ankit"; d.address = "Lucknow"; d.mobile = "+91 9453919659"
        d.subject = "Residence construction"; d.floors[0].area = "1000"; return d
    }
    func testReferenceCalculationAndPayments() {
        let d = validDocument()
        XCTAssertTrue(Validator.issues(d).isEmpty)
        XCTAssertEqual(d.baseCost, 1_700_000)
        XCTAssertEqual(d.specificationCost, 25_000)
        XCTAssertEqual(d.total, 1_725_000)
        XCTAssertEqual(d.milestoneAmounts, [517_500, 345_000, 517_500, 172_500, 172_500])
    }
    func testTaxIsExplicitAndExtraExclusionsAreUnpriced() {
        var d = validDocument()
        XCTAssertEqual(d.total, d.baseCost + 25_000)
        d.extras[0].pricing = .priced; d.extras[0].quantity = "2"; d.extras[0].rate = "100.25"; d.extras[0].unit = "sq ft"
        d.taxEnabled = true; d.taxableAmount = "1725200.5"
        XCTAssertEqual(d.subtotal, Decimal(string: "1725200.50")!)
        XCTAssertEqual(d.tax, Decimal(string: "310536.09")!)
        XCTAssertEqual(d.total, Decimal(string: "2035736.59")!)
        d.penaltyPercent = "90"
        XCTAssertEqual(d.total, Decimal(string: "2035736.59")!)
    }
    func testRoundingRemainderAssignedToLastMilestone() {
        var d = validDocument(); d.sections[9].items[4].included = false; d.floors[0].rate = "0.01001"; d.milestones = [Milestone(label: "First", percent: "33.33"), Milestone(label: "Second", percent: "33.33"), Milestone(label: "Final", percent: "33.34")]
        XCTAssertEqual(d.total, Decimal(string: "10.01"))
        XCTAssertEqual(d.milestoneAmounts.reduce(0, +), d.payable)
        XCTAssertEqual(d.milestoneAmounts.last, Decimal(string: "3.33"))
    }
    func testValidationBlocksRequiredErrorsButPreservesDraft() {
        var d = Agreement(); d.floors[0].area = "-5"; d.milestones[0].percent = "20"
        let ids = Validator.issues(d).map(\.id)
        XCTAssertTrue(ids.contains("clientName")); XCTAssertTrue(ids.contains("mobile")); XCTAssertTrue(ids.contains("milestones"))
        XCTAssertTrue(Validator.issues(d).contains { $0.message.contains("area must be positive") })
        d.floors[0].area = "1abc"; XCTAssertTrue(Validator.issues(d).contains { $0.message.contains("area must be positive") })
    }
    func testMultipleBrandsOrderedDeduplicatedAndExcluded() {
        var d = validDocument()
        d.sections[1].items[1].selectedBrands = ["Prism", "Ultratech", "Prism"]
        d.sections[1].items[1].customBrands = "Ultratech, Local"
        XCTAssertEqual(d.sections[1].items[1].output, "Cement: Ultratech, Prism, Local.")
        d.sections[1].included = false
        let output = DocumentLayout.blocks(d).map(\.text).joined()
        XCTAssertFalse(output.contains("Cement:")); XCTAssertTrue(output.contains("B. PLASTER"))
        XCTAssertEqual(d.sections[1].items[1].selectedBrands, ["Prism", "Ultratech", "Prism"])
    }
    func testStaircaseRequiresSeparateConfirmationAndGateCannotDuplicate() {
        var d = validDocument(); d.staircaseArea = "100"
        XCTAssertEqual(d.baseCost, 1_700_000)
        XCTAssertTrue(Validator.issues(d).contains { $0.id == "staircase-confirm" })
        d.staircaseConfirmed = true; XCTAssertEqual(d.baseCost, 1_870_000)
        d.extras.append(ExtraWork(id: "gate", label: "Main gate", pricing: .priced, quantity: "1", unit: "gate", rate: "25000"))
        XCTAssertTrue(Validator.issues(d).contains { $0.id == "gate-duplicate" })
    }
    func testAtomicPersistenceDuplicateAndDelete() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let repository = try AgreementRepository(directory: dir)
        var d = validDocument(); d.step = 7; d.sections[4].items[2].selectedBrands = ["RR Cable", "Polycab", "Anchor"]
        try repository.save(d)
        XCTAssertEqual(try repository.load(d.id), d)
        let copy = try repository.duplicate(d)
        XCTAssertNotEqual(copy.id, d.id); XCTAssertEqual(copy.sections, d.sections)
        try repository.delete(copy.id); XCTAssertEqual(try repository.list().count, 1)
        try repository.saveBranding(d.branding); XCTAssertEqual(try repository.loadBranding(), d.branding)
    }
    func testTemplateSnapshotSurvivesSettingsChange() throws {
        let d = validDocument(); let data = try JSONEncoder().encode(d)
        let restored = try JSONDecoder().decode(Agreement.self, from: data)
        XCTAssertEqual(restored.templateVersion, "adarsh-reference-1.0")
        XCTAssertEqual(restored.sections, Catalog.sections)
        XCTAssertEqual(restored.branding.name, "ADARSH INFRADEVELOPERS AND CONSTRUCTIONS")
    }
    func testDoorAndWindowASIIsRemovedFromLegacyDrafts() {
        var d = Agreement()
        let section = d.sections.firstIndex { $0.id == "G" }!
        let item = d.sections[section].items.firstIndex { $0.id == "G-frame" }!
        d.sections[section].items[item].wording = "Window frame will be of sagwan wood with {dimension} mm glass of {brands}."
        d.sections[section].items[item].brands = ["ASI"]
        d.sections[section].items[item].selectedBrands = ["ASI"]

        d.restoreMissingReferenceWording()

        XCTAssertEqual(d.sections[section].items[item].output, "Window frame will be of sagwan wood with 4 mm glass.")
        XCTAssertTrue(d.sections[section].items[item].brands.isEmpty)
        XCTAssertTrue(d.sections[section].items[item].selectedBrands.isEmpty)
    }
    func testTermsContinueDirectlyIntoLatePaymentAndExtraWork() {
        let blocks = DocumentLayout.blocks(validDocument())
        let finalTerm = blocks.lastIndex { $0.text == Catalog.terms.last?.text }!
        let latePayment = blocks.firstIndex { $0.text.contains("late payment") }!
        XCTAssertEqual(latePayment, finalTerm + 1)
        XCTAssertFalse(blocks[finalTerm + 1].pageBreak)
    }
    func testCustomTitlePersistsValidatesAndExportsOnlyWhenIncluded() throws {
        var d = validDocument()
        XCTAssertFalse(d.addWorkTitle("   "))
        XCTAssertTrue(d.addWorkTitle("  Waterproofing  "))
        let i = d.sections.count - 1
        XCTAssertEqual(d.sections[i].title, "Waterproofing")
        XCTAssertTrue(d.sections[i].isCustom)
        XCTAssertFalse(Validator.issues(d).contains { $0.id == d.sections[i].items[0].id })
        XCTAssertEqual(d.sections[i].items[0].output, "Work specification")
        d.sections[i].items[0].wording = "Terrace waterproofing with two coats."
        XCTAssertTrue(Validator.issues(d).isEmpty)
        let restored = try JSONDecoder().decode(Agreement.self, from: JSONEncoder().encode(d))
        XCTAssertEqual(restored.sections[i], d.sections[i])
        let output = DocumentLayout.blocks(restored).map(\.text).joined(separator: "\n")
        XCTAssertTrue(output.contains("WATERPROOFING"))
        XCTAssertTrue(output.contains("Terrace waterproofing with two coats."))
        d.sections[i].included = false
        XCTAssertFalse(DocumentLayout.blocks(d).map(\.text).joined().contains("Terrace waterproofing"))
        XCTAssertEqual(d.sections[i].items[0].wording, "Terrace waterproofing with two coats.")
        d.addWorkTitle("Landscaping")
        XCTAssertNotEqual(d.sections[i].id, d.sections.last!.id)
    }
    func testFixedChargesIncludedAndRemovedWithTheirOptions() throws {
        var d = validDocument()
        d.addWorkTitle("Landscaping")
        let i = d.sections.count - 1
        d.sections[i].items[0].wording = "Garden planting."
        d.sections[i].items[0].additionalAmount = "5000.50"
        XCTAssertEqual(d.total, Decimal(string: "1730000.50")!)
        XCTAssertEqual(d.milestoneAmounts.reduce(0, +), d.total)
        let loaded = try JSONDecoder().decode(Agreement.self, from: JSONEncoder().encode(d))
        XCTAssertEqual(loaded.total, d.total)
        XCTAssertTrue(DocumentLayout.blocks(d).map(\.text).joined().contains("Additional amount:"))
        d.sections[i].included = false
        XCTAssertEqual(d.total, 1_725_000)
        d.sections[9].items[4].included = false
        XCTAssertEqual(d.total, 1_700_000)
        d.sections[9].items[4].included = true; d.sections[9].items[4].quantity = "30000"
        XCTAssertEqual(d.total, 1_730_000)
    }
    func testTitleLettersRearrangeWithoutChangingStableIDs() throws {
        var d = validDocument()
        XCTAssertEqual(d.sectionTitle(for: "C"), "C. Plaster work")
        d.addWorkTitle("Landscaping")
        let customID = d.sections.last!.id
        XCTAssertEqual(d.sectionTitle(for: customID), "K. Landscaping")
        XCTAssertEqual(d.feesLetter, "L")
        d.sections.removeAll { $0.id == "B" }
        XCTAssertEqual(d.sectionTitle(for: "C"), "B. Plaster work")
        XCTAssertEqual(d.sectionTitle(for: customID), "J. Landscaping")
        d.sections[0].included = false
        XCTAssertEqual(d.sectionTitle(for: "C"), "A. Plaster work")
        XCTAssertEqual(d.sectionTitle(for: customID), "I. Landscaping")
        XCTAssertEqual(d.feesLetter, "J")
        let restored = try JSONDecoder().decode(Agreement.self, from: JSONEncoder().encode(d))
        XCTAssertEqual(restored.sectionTitle(for: customID), "I. Landscaping")
        XCTAssertTrue(DocumentLayout.blocks(restored).map(\.text).joined().contains("A. PLASTER WORK"))
        XCTAssertEqual(Agreement.titleLetter(at: 25), "Z")
        XCTAssertEqual(Agreement.titleLetter(at: 26), "AA")
    }
}
