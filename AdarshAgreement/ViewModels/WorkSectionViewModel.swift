import SwiftUI

@MainActor
final class WorkSectionViewModel: ObservableObject {
    @Published var subtitle = ""
    @Published var content = ""
    @Published var amount = ""
    var canAddOption: Bool {
        !subtitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && (amount.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (isNumber(amount) && number(amount) >= 0))
    }
    func add(to section: Binding<WorkSection>) {
        guard canAddOption else { return }
        let price = amount.trimmingCharacters(in: .whitespacesAndNewlines)
        section.wrappedValue.items.append(WorkItem(id: UUID().uuidString,
            label: subtitle.trimmingCharacters(in: .whitespacesAndNewlines),
            wording: content.trimmingCharacters(in: .whitespacesAndNewlines),
            isCustom: true, additionalAmount: price.isEmpty ? nil : price))
        subtitle = ""; content = ""; amount = ""
    }
    func remove(_ id: String, from section: Binding<WorkSection>) { section.wrappedValue.items.removeAll { $0.id == id } }
    func rangeIncludedBinding(item: Binding<WorkItem>) -> Binding<Bool> {
        Binding(get: { item.wrappedValue.priceRange?.included ?? false }, set: { included in
            var range = item.wrappedValue.priceRange ?? item.wrappedValue.defaultPriceRange
            range.included = included; item.wrappedValue.priceRange = range
        })
    }
    func rangeValueBinding(item: Binding<WorkItem>, minimum: Bool) -> Binding<String> {
        Binding(get: {
            let range = item.wrappedValue.priceRange ?? item.wrappedValue.defaultPriceRange
            return minimum ? range.minimum : range.maximum
        }, set: { value in
            var range = item.wrappedValue.priceRange ?? item.wrappedValue.defaultPriceRange
            if minimum { range.minimum = value } else { range.maximum = value }
            item.wrappedValue.priceRange = range
        })
    }
    func brandBinding(_ brand: String, item: Binding<WorkItem>) -> Binding<Bool> {
        Binding(get: { item.wrappedValue.selectedBrands.contains(brand) }, set: { selected in
            if selected { if !item.wrappedValue.selectedBrands.contains(brand) { item.wrappedValue.selectedBrands.append(brand) } }
            else { item.wrappedValue.selectedBrands.removeAll { $0 == brand } }
        })
    }
}
