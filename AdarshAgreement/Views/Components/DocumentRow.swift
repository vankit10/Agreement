import SwiftUI

struct DocumentRow: View {
    let document: Agreement
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: document.status == "Ready" ? "doc.text.fill" : "doc.badge.clock").font(.title2).foregroundStyle(AgreementTheme.accent).frame(width: 46, height: 54).background(AgreementTheme.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 4) {
                Text(document.displayName).font(.system(.headline, design: .rounded))
                Text(document.subject.isEmpty ? "Memorandum of Agreement" : document.subject).font(.subheadline).lineLimit(2).foregroundStyle(.secondary)
                Text(document.modified, style: .relative).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(spacing: 12) {
                Text(document.status).font(.caption.bold()).padding(.horizontal, 10).padding(.vertical, 6)
                    .foregroundStyle(document.status == "Ready" ? Color.green : Color.orange)
                    .background(document.status == "Ready" ? Color.green.opacity(0.12) : Color.orange.opacity(0.12), in: Capsule())
                Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(.tertiary)
            }
        }.padding(12).agreementCard()
    }
}
