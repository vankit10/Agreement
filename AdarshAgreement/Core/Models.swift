import Foundation

struct Branding: Codable, Equatable {
    var name = "ADARSH INFRADEVELOPERS AND CONSTRUCTIONS"
    var signatureName = "Adarsh Infradevelopers and Construction"
    var phones = "9453919659, 7905443687"
    var address = "1/69 Sec 1 Gomti Nagar, Lucknow 226010"
    var email = "adinfra.cont@gmail.com"
    var website = "https://adarshinfra.co.in/"
    var instagram = "Adarshinfra.co"
    var facebook = "Adasrh Infradevelopers and constructions"
    var trailingBrandPage = true
}

struct HouseDesignAttachment: Identifiable, Codable, Equatable {
    var id = UUID()
    var kind: String
    var filename: String
    var data: Data
    var isPDF: Bool
    var includedInPDF = true
}

struct FlooringPriceRange: Codable, Equatable {
    var included = false
    var minimum = ""
    var maximum = ""
}

struct WorkItem: Identifiable, Codable, Equatable {
    var id: String
    var label: String
    var wording: String
    var included = true
    var brands: [String] = []
    var selectedBrands: [String] = []
    var customBrands = ""
    var quantity: String = ""
    var unit: String = ""
    var dimension: String = ""
    var isCustom = false
    var additionalAmount: String?
    var priceRange: FlooringPriceRange?
    var supportsPriceRange: Bool { id.hasPrefix("F-") }
    var defaultPriceRange: FlooringPriceRange {
        switch id {
        case "F-bath": FlooringPriceRange(minimum: "55", maximum: "60")
        case "F-floor": FlooringPriceRange(minimum: "60", maximum: "65")
        case "F-marble": FlooringPriceRange(minimum: "80", maximum: "100")
        default: FlooringPriceRange()
        }
    }
    var fixedCharge: Decimal {
        guard included else { return 0 }
        return id == "J-gate" ? number(quantity) : number(additionalAmount ?? "")
    }

    var output: String {
        var text = wording
        if supportsPriceRange {
            // Strip legacy reference ranges so unchecked prices cannot leak into saved-draft output.
            text = text.replacingOccurrences(of: " @ ₹55 to ₹60 {unit}", with: "")
                .replacingOccurrences(of: " @ ₹60 to ₹65 {unit}", with: "")
                .replacingOccurrences(of: "Kitchen marble: ₹80 to ₹100 {unit}.", with: "Kitchen marble.")
        }
        let ordered = brands.filter { selectedBrands.contains($0) }
        let custom = customBrands.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        let unique = (ordered + custom).reduce(into: [String]()) { result, brand in
            if !result.contains(where: { $0.lowercased() == brand.lowercased() }) { result.append(brand) }
        }
        text = text.replacingOccurrences(of: "{brands}", with: unique.joined(separator: ", "))
        text = text.replacingOccurrences(of: "{quantity}", with: quantity)
        text = text.replacingOccurrences(of: "{dimension}", with: dimension)
        text = text.replacingOccurrences(of: "{unit}", with: unit)
        if supportsPriceRange, let range = priceRange, range.included {
            text += " Price range: \(rupees(number(range.minimum))) to \(rupees(number(range.maximum)))" + (unit.isEmpty ? "." : " / \(unit).")
        }
        if isCustom, let additionalAmount, !additionalAmount.isEmpty {
            text += " Additional amount: \(rupees(number(additionalAmount)))."
        }
        // A custom option may be deliberately added without a sentence. Keep it
        // visible in the agreement by using its subtitle as the output.
        return text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && isCustom ? label : text
    }
}

struct WorkSection: Identifiable, Codable, Equatable {
    var id: String
    var title: String
    var included = true
    var items: [WorkItem]
    var isCustom: Bool { !["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"].contains(id) }
    var displayTitle: String { isCustom ? title : "\(id). \(title)" }
}

struct Floor: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var included = true
    var area = ""
    var rate = "1700"
}

struct Clause: Identifiable, Codable, Equatable {
    var id: String
    var text: String
    var included = true
}

enum PricingStatus: String, Codable, CaseIterable {
    case unpriced = "Unpriced exclusion", priced = "Priced extra", covered = "Covered in base"
}

struct ExtraWork: Identifiable, Codable, Equatable {
    var id: String
    var label: String
    var included = true
    var pricing: PricingStatus = .unpriced
    var quantity = ""
    var unit = ""
    var rate = ""
    var notes = ""
    var amount: Decimal { pricing == .priced && included ? number(quantity) * number(rate) : 0 }
}

struct Milestone: Identifiable, Codable, Equatable {
    var id = UUID()
    var label: String
    var percent: String
}

struct Agreement: Identifiable, Codable, Equatable {
    var houseDesigns: [HouseDesignAttachment]?
    var id = UUID()
    var title = "MEMORANDUM OF AGREEMENT"
    var clientName = ""
    var address = ""
    var mobile = ""
    var subject = ""
    var location = ""
    var introduction = "Dear Sir/Mam,\n\n“The Work” according to drawing and details, showing description of the work to be done under the direction of the client approved by the Architect."
    var sections = Catalog.sections
    var floors = [Floor(name: "Ground floor"), Floor(name: "First floor", included: false), Floor(name: "Mumty", included: false)]
    var staircaseArea = ""
    var staircaseRate = "1700"
    var staircaseConfirmed = false
    var areaNote = "The area mentioned in agreement are based on drawings prepared. Final area may vary as per site. Final calculation will be done as per site measurements on actual basis."
    var terms = Catalog.terms
    var taxEnabled = false
    var taxPercent = "18"
    var taxableAmount = ""
    var penaltyEnabled = true
    var penaltyPercent = "10"
    var penaltyWording = "In case of late payment {percent}% penalty charged on amount."
    var extras = Catalog.extras
    var milestones = [Milestone(label: "Advance", percent: "30"), Milestone(label: "After DPC / brickwork", percent: "20"), Milestone(label: "After shuttering, before slab", percent: "30"), Milestone(label: "After plaster", percent: "10"), Milestone(label: "Finishing", percent: "10")]
    var paymentUsesTotal = true
    var companySigner = ""
    var clientSigner = ""
    var witness1 = ""
    var witness2 = ""
    var branding = Branding()
    var templateVersion = "adarsh-reference-1.0"
    var status = "Draft"
    var created = Date()
    var modified = Date()
    var revision = 0
    var pdfFingerprint: String?
    var step = 0
    var syncState = "Local only"
    static func titleLetter(at index: Int) -> String {
        var value = max(0, index) + 1
        var label = ""
        while value > 0 {
            value -= 1
            label = String(UnicodeScalar(65 + value % 26)!) + label
            value /= 26
        }
        return label
    }
    func sectionTitle(for id: String) -> String {
        guard let section = sections.first(where: { $0.id == id }) else { return "" }
        guard let position = sections.filter(\.included).firstIndex(where: { $0.id == id }) else { return section.title }
        return "\(Self.titleLetter(at: position)). \(section.title)"
    }
    var feesLetter: String { Self.titleLetter(at: sections.filter(\.included).count) }
    mutating func restoreMissingReferenceWording() {
        for sectionIndex in sections.indices {
            for itemIndex in sections[sectionIndex].items.indices {
                let item = sections[sectionIndex].items[itemIndex]
                if item.id == "J-gate" && item.wording == "Main gate (₹{quantity}), included in base rate." {
                    sections[sectionIndex].items[itemIndex].wording = "Main gate (₹{quantity})."
                }
                if item.id == "G-frame" && item.wording == "Window frame will be of sagwan wood with {dimension} mm glass of {brands}." {
                    sections[sectionIndex].items[itemIndex].wording = "Window frame will be of sagwan wood with {dimension} mm glass."
                    sections[sectionIndex].items[itemIndex].brands.removeAll { $0.caseInsensitiveCompare("ASI") == .orderedSame }
                    sections[sectionIndex].items[itemIndex].selectedBrands.removeAll { $0.caseInsensitiveCompare("ASI") == .orderedSame }
                }
                guard !item.isCustom, item.wording.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                      let reference = Catalog.sections.flatMap(\.items).first(where: { $0.id == item.id }) else { continue }
                sections[sectionIndex].items[itemIndex].wording = reference.wording
            }
        }
    }
    @discardableResult
    mutating func addWorkTitle(_ name: String) -> Bool {
        let title = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return false }
        sections.append(WorkSection(id: UUID().uuidString, title: title, items: [
            WorkItem(id: UUID().uuidString, label: "Work specification", wording: "", isCustom: true)
        ]))
        return true
    }
    var baseCost: Decimal {
        floors.filter(\.included).reduce(0) { $0 + number($1.area) * number($1.rate) }
        + (staircaseConfirmed ? number(staircaseArea) * number(staircaseRate) : 0)
    }
    var extrasCost: Decimal { extras.reduce(0) { $0 + $1.amount } }
    var specificationCharges: [WorkItem] {
        sections.filter(\.included).flatMap(\.items).filter { $0.included && $0.fixedCharge > 0 }
    }
    var specificationCost: Decimal { specificationCharges.reduce(0) { $0 + $1.fixedCharge } }
    var subtotal: Decimal { moneyRound(baseCost + specificationCost + extrasCost) }
    var tax: Decimal { taxEnabled ? moneyRound(number(taxableAmount) * number(taxPercent) / 100) : 0 }
    var total: Decimal { moneyRound(subtotal + tax) }
    var payable: Decimal { paymentUsesTotal ? total : subtotal }
    var milestoneAmounts: [Decimal] {
        guard !milestones.isEmpty else { return [] }
        var values = milestones.dropLast().map { moneyRound(payable * number($0.percent) / 100) }
        values.append(moneyRound(payable - values.reduce(0, +)))
        return values
    }
    var displayName: String { clientName.isEmpty ? "Untitled agreement" : clientName }
    var hindiFilename: String {
        let stem = filename.replacingOccurrences(of: ".pdf", with: "")
        return stem + "-hi.pdf"
    }
    var warnings: [String] {
        let selected = sections.filter(\.included).flatMap { $0.items.filter(\.included) }
        var result: [String] = []
        if selected.contains(where: { $0.id == "G-frame" }) && selected.contains(where: { $0.id == "I-frame" }) {
            result.append("G specifies sagwan frames and I specifies Malaysian Sakhu. Review both clauses before signing.")
        }
        if selected.contains(where: { $0.supportsPriceRange && $0.unit.isEmpty && $0.priceRange?.included == true }) {
            result.append("Flooring price units are unspecified in the reference. Original wording is retained; enter units if agreed.")
        }
        return result
    }
    var filename: String {
        let safe = clientName.unicodeScalars.map { CharacterSet.alphanumerics.contains($0) ? String($0) : "_" }.joined()
        let formatter = DateFormatter(); formatter.dateFormat = "yyyy-MM-dd"
        return "Adarsh_Agreement_\(safe.isEmpty ? "Client" : String(safe.prefix(50)))_\(formatter.string(from: created))_\(id.uuidString.prefix(8)).pdf"
    }
}

func number(_ text: String) -> Decimal {
    Decimal(string: text.trimmingCharacters(in: .whitespacesAndNewlines), locale: Locale(identifier: "en_US_POSIX")) ?? 0
}

func isNumber(_ text: String) -> Bool {
    let s = text.trimmingCharacters(in: .whitespacesAndNewlines)
    return s.range(of: "^[+-]?[0-9]+(?:\\.[0-9]+)?$", options: .regularExpression) != nil
}

func moneyRound(_ value: Decimal) -> Decimal {
    var source = value; var result = Decimal(); NSDecimalRound(&result, &source, 2, .plain); return result
}

func rupees(_ value: Decimal) -> String {
    let formatter = NumberFormatter(); formatter.locale = Locale(identifier: "en_IN")
    formatter.numberStyle = .currency; formatter.currencyCode = "INR"
    formatter.minimumFractionDigits = 2; formatter.maximumFractionDigits = 2
    return formatter.string(from: NSDecimalNumber(decimal: value)) ?? "₹0.00"
}
