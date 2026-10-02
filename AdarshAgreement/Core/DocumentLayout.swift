import Foundation

struct DocumentBlock {
    var text: String
    var heading = false
    var pageBreak = false
    var signature = false
    var clientDetails = false
    var documentTitle = false
}

enum DocumentLayout {
    static func blocks(_ d: Agreement) -> [DocumentBlock] {
        var blocks: [DocumentBlock] = []
        func text(_ text: String, heading: Bool = false) { blocks.append(DocumentBlock(text: text, heading: heading)) }
        func page() { blocks.append(DocumentBlock(text: "", pageBreak: true)) }
        func section(_ id: String, filter: ((WorkItem) -> Bool)? = nil, showHeading: Bool = true) {
            guard let s = d.sections.first(where: { $0.id == id }), s.included else { return }
            let items = s.items.filter { $0.included && (filter?($0) ?? true) }
            guard !items.isEmpty else { return }
            if showHeading { text(d.sectionTitle(for: s.id).uppercased(), heading: true) }
            var emittedFixtures = false
            for item in items {
                if id == "D" && ["D-wc", "D-basin", "D-tap"].contains(item.id) {
                    if !emittedFixtures { text(items.filter { ["D-wc", "D-basin", "D-tap"].contains($0.id) }.map(\.output).joined(separator: " ")); emittedFixtures = true }
                } else { text(item.output) }
            }
        }
        blocks.append(DocumentBlock(text: d.title, documentTitle: true))
        blocks.append(DocumentBlock(text: "", clientDetails: true))
        text(d.introduction)
        text("SCOPE OF WORK:", heading: true)
        for id in ["A", "B", "C"] { section(id) }
        page()
        for id in ["D", "E", "F", "G"] { section(id) }
        section("H", filter: { ["H-putty", "H-pop"].contains($0.id) })
        page()
        section("H", filter: { !["H-putty", "H-pop"].contains($0.id) }, showHeading: false)
        section("I"); section("J")
        for custom in d.sections.filter(\.isCustom) { section(custom.id) }
        text("\(d.feesLetter). FEE CHARGABLE:", heading: true)
        text("The Total fee chargable for the above mentioned services is calculated on super built-up area:")
        for floor in d.floors.filter(\.included) { text("\(floor.name): \(floor.area) sq ft × \(rupees(number(floor.rate))) = \(rupees(number(floor.area) * number(floor.rate)))") }
        if d.staircaseConfirmed { text("Additional staircase measurement: \(d.staircaseArea) sq ft × \(rupees(number(d.staircaseRate))) = \(rupees(number(d.staircaseArea) * number(d.staircaseRate)))") }
        text("Base cost: \(rupees(d.baseCost))")
        for item in d.specificationCharges { text("\(item.label): \(rupees(item.fixedCharge))") }
        text("Priced extras: \(rupees(d.extrasCost))\nSubtotal: \(rupees(d.subtotal))" + (d.taxEnabled ? "\nTax (\(d.taxPercent)% on \(rupees(number(d.taxableAmount)))): \(rupees(d.tax))" : "") + "\nTotal cost: \(rupees(d.total))")
        text("NOTE: " + d.areaNote)
        text("TERMS & CONDITIONS", heading: true)
        for clause in d.terms.filter(\.included) { text(clause.text) }
        // Let the last term, late-payment wording, and extra-work section share
        // available page space. The renderer will still begin a new page only
        // when a line genuinely reaches the footer.
        if d.penaltyEnabled { text(d.penaltyWording.replacingOccurrences(of: "{percent}", with: d.penaltyPercent)) }
        text("EXTRA WORK:", heading: true)
        for extra in d.extras.filter(\.included) {
            var value = extra.label
            if extra.pricing == .priced { value += ": \(extra.quantity) \(extra.unit) × \(rupees(number(extra.rate))) = \(rupees(extra.amount))" }
            else if extra.pricing == .covered { value += " — included in base rate" }
            else { value += " — charged separately if required"; if !extra.rate.isEmpty { value += " (\(rupees(number(extra.rate))) / \(extra.unit))" } }
            if !extra.notes.isEmpty { value += ". " + extra.notes }
            text(value)
        }
        text("PAYMENT CONDITION", heading: true)
        text("Payment base: \(d.paymentUsesTotal ? "total including tax" : "subtotal before tax"), \(rupees(d.payable)).")
        for (i, milestone) in d.milestones.enumerated() { text("\(milestone.label): \(milestone.percent)% — \(rupees(d.milestoneAmounts[i]))") }
        page()
        blocks.append(DocumentBlock(text: "", signature: true))
        return blocks
    }
}
