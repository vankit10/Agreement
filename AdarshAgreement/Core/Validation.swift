import Foundation

struct ValidationIssue: Identifiable, Equatable {
    var id: String
    var step: Int
    var message: String
}

enum Validator {
    static func issues(_ d: Agreement) -> [ValidationIssue] {
        var errors: [ValidationIssue] = []
        func add(_ id: String, _ step: Int, _ text: String) { errors.append(ValidationIssue(id: id, step: step, message: text)) }
        for (key, label, value) in [("clientName", "Client name", d.clientName), ("address", "Address", d.address), ("subject", "Subject", d.subject), ("title", "Document title", d.title)] {
            if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { add(key, 0, "\(label) is required.") }
        }
        let digits = d.mobile.filter(\.isNumber)
        if !(7...15).contains(digits.count) || d.mobile.range(of: "^[+0-9() .-]+$", options: .regularExpression) == nil {
            add("mobile", 0, "Enter a mobile number with 7–15 digits, optionally with country code.")
        }
        let active = d.sections.filter(\.included)
        for section in active {
            let step = 2 + active.firstIndex(where: { $0.id == section.id })!
            if section.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { add(section.id + "-title", step, "Enter a name for this work title.") }
            if section.items.filter(\.included).isEmpty { add(section.id, step, "\(section.title): select at least one item or add a custom clause.") }
            for item in section.items.filter(\.included) {
                if !item.isCustom && item.wording.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { add(item.id, step, "\(item.label): wording is required.") }
                if item.supportsPriceRange, let range = item.priceRange, range.included {
                    if !isNumber(range.minimum) || !isNumber(range.maximum) || number(range.minimum) < 0 || number(range.maximum) < number(range.minimum) {
                        add(item.id + "-price-range", step, "\(item.label): enter a valid price range with maximum no lower than minimum.")
                    }
                }
                if let amount = item.additionalAmount, !amount.isEmpty, (!isNumber(amount) || number(amount) < 0) { add(item.id + "-amount", step, "\(item.label): additional amount must be zero or positive.") }
                if item.wording.contains("{brands}") && item.selectedBrands.isEmpty && item.customBrands.trimmingCharacters(in: .whitespaces).isEmpty { add(item.id + "-brands", step, "\(item.label): choose a brand or enter a custom brand.") }
                if item.wording.contains("{quantity}") && (!isNumber(item.quantity) || number(item.quantity) <= 0) { add(item.id + "-quantity", step, "\(item.label): enter a positive quantity.") }
                if item.wording.contains("{dimension}") {
                    let values = item.dimension.lowercased().replacingOccurrences(of: "×", with: "x").split(separator: "x").map { $0.trimmingCharacters(in: .whitespaces) }
                    if values.isEmpty || values.contains(where: { !isNumber($0) || number($0) <= 0 }) { add(item.id + "-dimension", step, "\(item.label): enter positive dimensions.") }
                }
            }
        }
        let fees = 2 + active.count
        for clause in d.terms.filter(\.included) {
            if clause.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { add(clause.id, fees + 1, "Included clauses need document wording.") }
        }
        if d.floors.filter(\.included).isEmpty { add("floors", fees, "Include at least one floor.") }
        for floor in d.floors.filter(\.included) {
            if !isNumber(floor.area) || number(floor.area) <= 0 { add(floor.id.uuidString + "area", fees, "\(floor.name): area must be positive.") }
            if !isNumber(floor.rate) || number(floor.rate) <= 0 { add(floor.id.uuidString + "rate", fees, "\(floor.name): rate must be positive.") }
        }
        if !d.staircaseArea.isEmpty && !d.staircaseConfirmed { add("staircase-confirm", fees, "Confirm staircase area is additional and not already included.") }
        if d.staircaseConfirmed && (!isNumber(d.staircaseArea) || number(d.staircaseArea) <= 0 || !isNumber(d.staircaseRate) || number(d.staircaseRate) <= 0) { add("staircase", fees, "Additional staircase area and rate must be positive.") }
        if d.taxEnabled {
            if !isNumber(d.taxPercent) || number(d.taxPercent) < 0 || number(d.taxPercent) > 100 { add("taxPercent", fees + 1, "Tax percentage must be between 0 and 100.") }
            if !isNumber(d.taxableAmount) || number(d.taxableAmount) <= 0 || number(d.taxableAmount) > d.subtotal { add("taxableAmount", fees + 1, "Select a taxable amount greater than zero and no greater than the subtotal.") }
        }
        if d.penaltyEnabled && (!isNumber(d.penaltyPercent) || number(d.penaltyPercent) < 0 || number(d.penaltyPercent) > 100) { add("penalty", fees + 1, "Penalty percentage must be between 0 and 100.") }
        for extra in d.extras.filter({ $0.included && $0.pricing == .priced }) {
            if !isNumber(extra.quantity) || number(extra.quantity) <= 0 || !isNumber(extra.rate) || number(extra.rate) <= 0 || extra.unit.trimmingCharacters(in: .whitespaces).isEmpty {
                add(extra.id, fees + 2, "\(extra.label): enter a positive quantity, rate and unit.")
            }
            if extra.id == "gate" && active.contains(where: { $0.items.contains(where: { $0.id == "J-gate" && $0.included }) }) { add("gate-duplicate", fees + 2, "Gate price is already counted in section J; remove it there before pricing it as extra work.") }
        }
        if d.milestones.isEmpty || d.milestones.reduce(Decimal(0), { $0 + number($1.percent) }) != 100 {
            add("milestones", fees + 3, "Payment percentages must total exactly 100%.")
        }
        for m in d.milestones {
            if m.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !isNumber(m.percent) || number(m.percent) <= 0 || number(m.percent) > 100 { add(m.id.uuidString, fees + 3, "Each milestone needs a label and a percentage greater than zero, up to 100.") }
        }
        return errors
    }
}
