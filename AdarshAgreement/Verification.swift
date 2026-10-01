import Foundation
import PDFKit

@MainActor
enum Verification {
    static func run() {
        do {
            let root = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Verification")
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
            var baseline = Agreement(); baseline.clientName = "abc"; baseline.address = "Lucknow"; baseline.mobile = "1234567890"
            baseline.subject = "Quotation for the construction of Residence at Madhav green, Lucknow"
            baseline.floors[0].area = "1000"
            let data = AgreementPDFRenderer.render(baseline)
            try data.write(to: root.appendingPathComponent("baseline.pdf"), options: .atomic)
            var overflow = baseline
            overflow.clientName = String(repeating: "Long client name with multilingual text Ankit Verma ", count: 10)
            overflow.address = String(repeating: "A detailed project address near Gomti Nagar, Lucknow. ", count: 30)
            overflow.sections[1].items.append(WorkItem(id: "stress", label: "Long custom clause", wording: String(repeating: "Custom construction specification must wrap safely and remain above the contact footer. ", count: 180), isCustom: true))
            let stressData = AgreementPDFRenderer.render(overflow)
            try stressData.write(to: root.appendingPathComponent("overflow.pdf"), options: .atomic)
            let repository = try AgreementRepository(directory: root.appendingPathComponent("Store"))
            try repository.save(baseline)
            let restored = try repository.load(baseline.id)
            let copy = try repository.duplicate(baseline)
            try repository.savePDF(data, for: baseline.id)
            let previewBytes = try Data(contentsOf: repository.pdfURL(baseline.id))
            let f1 = try AgreementPDFRenderer.fingerprint(baseline)
            var edited = baseline; edited.subject += " revised"
            let f2 = try AgreementPDFRenderer.fingerprint(edited)
            guard let pdf = PDFDocument(data: stressData), let baselinePDF = PDFDocument(data: data) else { throw AppError.invalidPDF }
            let searchable = (0..<pdf.pageCount).compactMap { pdf.page(at: $0)?.string }.joined()
            let result: [String: Any] = [
                "baselinePages": baselinePDF.pageCount,
                "overflowPages": pdf.pageCount,
                "baselineValid": Validator.issues(baseline).isEmpty,
                "restorationExact": restored == baseline,
                "duplicateIndependent": copy.id != baseline.id,
                "previewExportIdentical": previewBytes == data,
                "editInvalidatesFingerprint": f1 != f2,
                "searchableText": searchable.contains("Custom construction specification"),
                "tailSurvivesOverflow": searchable.contains("PAYMENT CONDITION") && searchable.contains("Witness")
            ]
            try JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys]).write(to: root.appendingPathComponent("results.json"), options: .atomic)
            AppLog.lifecycle.info("Development verification completed")
        } catch { AppLog.failure(.verification, error) }
    }
}
