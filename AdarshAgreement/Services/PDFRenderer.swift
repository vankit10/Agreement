import UIKit
import PDFKit
import CryptoKit
import CoreText

@MainActor
enum AgreementPDFRenderer {
    static let pageSize = CGSize(width: 595.25, height: 842)
    static func fingerprint(_ document: Agreement) throws -> String {
        var snapshot = document
        snapshot.pdfFingerprint = nil; snapshot.modified = snapshot.created
        snapshot.revision = 0; snapshot.step = 0; snapshot.status = ""
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
        var bytes = try encoder.encode(snapshot)
        bytes.append(Data("adarsh-renderer-2-optional-flooring-ranges".utf8))
        return SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
    }
    static func render(_ document: Agreement) -> Data {
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [kCGPDFContextTitle as String: document.title,
                               kCGPDFContextCreator as String: "Adarsh Agreement Builder"]
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize), format: format)
        return renderer.pdfData { context in
            let canvas = PageCanvas(context: context, document: document)
            canvas.beginPage()
            for block in DocumentLayout.blocks(document) {
                if block.pageBreak { canvas.beginPage() }
                else if block.signature { canvas.signatureBlock() }
                else if block.clientDetails { canvas.clientTable() }
                else if block.documentTitle { canvas.title(block.text) }
                else { canvas.paragraph(block.text, heading: block.heading) }
            }
            if document.branding.trailingBrandPage { canvas.beginPage() }
        }
    }
}

@MainActor
private final class PageCanvas {
    let context: UIGraphicsPDFRendererContext
    let document: Agreement
    var y: CGFloat = 128
    let left: CGFloat = 42
    let width: CGFloat = 511.25
    let bodyBottom: CGFloat = 725
    let blue = UIColor(red: 0.25, green: 0.44, blue: 0.76, alpha: 1)
    init(context: UIGraphicsPDFRendererContext, document: Agreement) { self.context = context; self.document = document }
    func asset(_ name: String, _ rect: CGRect) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "png"), let image = UIImage(contentsOfFile: url.path) else {
            AppLog.pdf.error("Bundled branding asset could not be loaded: \(name, privacy: .public)")
            return
        }
        image.draw(in: rect)
    }
    func attributes(size: CGFloat, bold: Bool = false, color: UIColor = .black) -> [NSAttributedString.Key: Any] {
        [.font: UIFont(name: bold ? "TimesNewRomanPS-BoldMT" : "TimesNewRomanPSMT", size: size) ?? UIFont.systemFont(ofSize: size), .foregroundColor: color]
    }
    func draw(_ text: String, _ rect: CGRect, size: CGFloat = 11, bold: Bool = false, color: UIColor = .black) {
        (text as NSString).draw(in: rect, withAttributes: attributes(size: size, bold: bold, color: color))
    }
    func rule(_ y: CGFloat) {
        let cg = context.cgContext; cg.setStrokeColor(UIColor.black.cgColor); cg.setLineWidth(0.75)
        cg.move(to: CGPoint(x: 26, y: y)); cg.addLine(to: CGPoint(x: 579, y: y)); cg.strokePath()
    }
    func beginPage() {
        context.beginPage(); y = 128
        asset("watermark", CGRect(x: -19.4, y: 171.25, width: 617.4, height: 485.1))
        asset("logo", CGRect(x: 10.2, y: 10.2, width: 121.16, height: 100.25))
        asset("construction", CGRect(x: 466.2, y: 15.6, width: 111.25, height: 77.8))
        asset("construction-detail", CGRect(x: 466.2, y: 41.05, width: 24.381, height: 14.9))
        let style = NSMutableParagraphStyle(); style.alignment = .center
        let a: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 18, weight: .bold), .foregroundColor: blue, .paragraphStyle: style]
        (document.branding.name as NSString).draw(in: CGRect(x: 115, y: 13, width: 346, height: 83), withAttributes: a)
        rule(108.5); rule(738)
        let b = document.branding
        draw("Contact- \(b.phones)", CGRect(x: 25, y: 753, width: 320, height: 25), size: 10, bold: true)
        draw("Address - \(b.address)", CGRect(x: 25, y: 775, width: 300, height: 36), size: 10)
        draw(b.website, CGRect(x: 25, y: 816, width: 300, height: 16), size: 10, color: .systemBlue)
        draw("E-Mail: \(b.email)", CGRect(x: 355, y: 753, width: 226, height: 20), size: 10)
        asset("instagram", CGRect(x: 360.45, y: 775, width: 18.55, height: 18.67))
        draw("- \(b.instagram)", CGRect(x: 389, y: 775, width: 190, height: 23), size: 10)
        asset("facebook", CGRect(x: 361.4, y: 799, width: 17.25, height: 16.89))
        draw("- \(b.facebook)", CGRect(x: 389, y: 799, width: 190, height: 36), size: 10)
    }
    func paragraph(_ text: String, heading: Bool) {
        let fontSize: CGFloat = heading ? 13 : 11.5
        let lineHeight: CGFloat = heading ? 17 : 14.5
        if y + (heading ? lineHeight * 2 + 10 : lineHeight) > bodyBottom { beginPage() }
        if heading { y += 7 }
        // Break with Core Text instead of truncating long NSString bounding rectangles.
        for paragraph in text.components(separatedBy: "\n") {
            if paragraph.isEmpty { y += lineHeight; continue }
            let attributed = NSAttributedString(string: paragraph, attributes: attributes(size: fontSize, bold: heading))
            let typesetter = CTTypesetterCreateWithAttributedString(attributed)
            let string = paragraph as NSString
            var offset = 0
            while offset < string.length {
                let count = max(1, CTTypesetterSuggestLineBreak(typesetter, offset, Double(width)))
                if y + lineHeight > bodyBottom { beginPage() }
                let line = CTTypesetterCreateLine(typesetter, CFRange(location: offset, length: min(count, string.length - offset)))
                let cg = context.cgContext
                cg.saveGState(); cg.textMatrix = .identity
                cg.translateBy(x: left, y: y + fontSize); cg.scaleBy(x: 1, y: -1)
                cg.textPosition = .zero; CTLineDraw(line, cg); cg.restoreGState()
                offset += count; y += lineHeight
            }
        }
        y += heading ? 7 : 3
    }
    func title(_ text: String) {
        let style = NSMutableParagraphStyle(); style.alignment = .center
        let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 16.5, weight: .bold), .foregroundColor: blue, .paragraphStyle: style]
        let height = (text as NSString).boundingRect(with: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude), options: [.usesLineFragmentOrigin], attributes: attrs, context: nil).height
        if height > bodyBottom - y { paragraph(text, heading: true); return }
        (text as NSString).draw(in: CGRect(x: left, y: y + 10, width: width, height: height + 5), withAttributes: attrs)
        y += height + 40
    }
    func clientTable() {
        var rows = [("Name", document.clientName), ("Address", document.address), ("Mobile", document.mobile), ("Subject", document.subject)]
        if !document.location.isEmpty { rows.append(("Location", document.location)) }
        for (label, value) in rows {
            let attrs = attributes(size: 14, bold: true)
            let height = max(28, ceil((value as NSString).boundingRect(with: CGSize(width: width - 99, height: CGFloat.greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attrs, context: nil).height) + 14)
            if height > bodyBottom - 128 {
                paragraph(label + ":", heading: true); paragraph(value, heading: false); continue
            }
            if y + height > bodyBottom { beginPage() }
            let cg = context.cgContext; cg.setStrokeColor(UIColor.black.cgColor); cg.setLineWidth(0.5)
            cg.stroke(CGRect(x: left, y: y, width: width, height: height))
            cg.move(to: CGPoint(x: left + 85, y: y)); cg.addLine(to: CGPoint(x: left + 85, y: y + height)); cg.strokePath()
            draw(label, CGRect(x: left + 5, y: y + 7, width: 78, height: height - 7), size: 14, bold: true)
            (value as NSString).draw(in: CGRect(x: left + 92, y: y + 7, width: width - 99, height: height - 7), withAttributes: attrs)
            y += height
        }
        y += 24
    }
    func signatureBlock() {
        // Two columns with wrapped names, followed by witnesses; remain together if possible.
        let b = document.branding
        let texts = ["For,\n\(b.signatureName)\n\(document.companySigner)\n\n_______________________\nSignature",
                     "Accepted by\n\(document.clientSigner.isEmpty ? document.clientName : document.clientSigner)\n\n\n_______________________\nName & Signature"]
        let heights = texts.map { ($0 as NSString).boundingRect(with: CGSize(width: 242, height: CGFloat.greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes(size: 12), context: nil).height }
        let height = max(heights.max() ?? 120, 130)
        if height + 110 > bodyBottom - y { beginPage() }
        // Very long names use normal pagination rather than clipping the signature block.
        if height + 110 > bodyBottom - y {
            paragraph(texts[0], heading: false); paragraph(texts[1], heading: false)
        } else {
            for i in 0..<2 { draw(texts[i], CGRect(x: left + CGFloat(i) * 269, y: y + 20, width: 242, height: height + 5), size: 12) }
            y += height + 35
        }
        paragraph("1- Witness: \(document.witness1)\n_______________________\n\n2- Witness: \(document.witness2)\n_______________________", heading: false)
    }
}
