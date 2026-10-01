import SwiftUI

struct WorkSectionEditor: View {
    @Binding var section: WorkSection
    var showIssues: Bool
    @StateObject private var viewModel = WorkSectionViewModel()
    var body: some View {
        if section.isCustom {
            Section("Work title") { TextField("Title name", text: $section.title) }
        }
        ForEach($section.items) { $item in
            Section {
                HStack(spacing: 12) {
                    CompactToggle(title: "Include \(item.label)", isOn: $item.included, showsTitle: false)
                        .sensoryFeedback(.selection, trigger: item.included)
                    Text(item.label).font(.system(.subheadline, design: .rounded, weight: .semibold))
                    Spacer(minLength: 0)
                    Button(role: .destructive) {
                        viewModel.remove(item.id, from: $section)
                    } label: {
                        Image(systemName: "minus").font(.headline.weight(.bold))
                            .frame(width: 44, height: 44)
                            .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                    }.buttonStyle(.borderless)
                        .accessibilityLabel("Remove \(item.label)")
                }
                if item.included {
                    if item.isCustom { TextField("Subtitle", text: $item.label) }
                    ForEach(item.brands, id: \.self) { brand in
                        CompactToggle(title: brand, isOn: viewModel.brandBinding(brand, item: $item))
                    }
                    if !item.brands.isEmpty { TextField("Custom brands, comma separated", text: $item.customBrands) }
                    if item.wording.contains("{quantity}") { TextField(item.id == "J-gate" ? "Gate price (₹)" : "Quantity / value", text: $item.quantity).keyboardType(.decimalPad) }
                    if item.wording.contains("{dimension}") { TextField("Dimension", text: $item.dimension) }
                    if item.supportsPriceRange {
                        CompactToggle(title: "Show price range", isOn: viewModel.rangeIncludedBinding(item: $item))
                        if item.priceRange?.included == true {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Minimum price (₹)").font(.caption).foregroundStyle(.secondary)
                                TextField("Minimum price", text: viewModel.rangeValueBinding(item: $item, minimum: true)).keyboardType(.decimalPad)
                                Text("Maximum price (₹)").font(.caption).foregroundStyle(.secondary)
                                TextField("Maximum price", text: viewModel.rangeValueBinding(item: $item, minimum: false)).keyboardType(.decimalPad)
                            }
                            TextField("Price unit (optional)", text: $item.unit)
                            Text("The range describes the specification; it is not a separate fixed charge.").font(.caption).foregroundStyle(.secondary)
                        }
                    } else if item.wording.contains("{unit}") { TextField("Price unit (optional in reference)", text: $item.unit) }
                    if item.isCustom {
                        TextField("Content", text: $item.wording, axis: .vertical)
                        TextField("Additional amount (₹, optional)", text: Binding(get: { item.additionalAmount ?? "" }, set: { item.additionalAmount = $0.isEmpty ? nil : $0 })).keyboardType(.decimalPad)
                    } else {
                        Text(item.output).font(.subheadline).foregroundStyle(.secondary).lineSpacing(4).padding(.vertical, 4)
                    }
                }
            }
        }
        Section("Add option") {
            TextField("Subtitle", text: $viewModel.subtitle)
            TextField("Content", text: $viewModel.content, axis: .vertical)
            TextField("Additional amount (₹, optional)", text: $viewModel.amount).keyboardType(.decimalPad)
            Text("Enter a fixed charge here to add it to the agreement total. Leave blank for work covered by the construction rate.").font(.caption).foregroundStyle(.secondary)
            HStack {
                Spacer()
                Button {
                    viewModel.add(to: $section)
                } label: {
                    Image(systemName: "plus").font(.title3.weight(.bold))
                        .frame(width: 44, height: 44)
                        .foregroundStyle(viewModel.canAddOption ? Color.white : AgreementTheme.accent.opacity(0.4))
                        .background(viewModel.canAddOption ? AgreementTheme.accent : AgreementTheme.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                        .shadow(color: AgreementTheme.accent.opacity(viewModel.canAddOption ? 0.18 : 0), radius: 6, x: 0, y: 3)
                }.buttonStyle(.borderless).disabled(!viewModel.canAddOption)
                    .accessibilityLabel("Add option to \(section.title)")
                    .accessibilityIdentifier("addWorkOption")
            }
        }
    }
}
