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
        bytes.append(Data("adarsh-renderer-5-branded-header-footer".utf8))
        return SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
    }
    static func render(_ document: Agreement) -> Data {
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [kCGPDFContextTitle as String: document.title,
                               kCGPDFContextCreator as String: "Adarsh Agreement Builder"]
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize), format: format)
        let agreementData = renderer.pdfData { context in
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
        guard let pdf = PDFDocument(data: agreementData) else { return agreementData }
        for attachment in document.houseDesigns ?? [] where attachment.includedInPDF {
            if attachment.isPDF, let design = PDFDocument(data: attachment.data) {
                for index in 0..<design.pageCount {
                    if let page = design.page(at: index) { pdf.insert(page, at: pdf.pageCount) }
                }
            } else if let image = UIImage(data: attachment.data), let page = PDFPage(image: image) {
                pdf.insert(page, at: pdf.pageCount)
            }
        }
        return pdf.dataRepresentation() ?? agreementData
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
    let navy = UIColor(red: 0.06, green: 0.18, blue: 0.34, alpha: 1)
    let green = UIColor(red: 0.27, green: 0.65, blue: 0.22, alpha: 1)
    var pageNumber = 0
    init(context: UIGraphicsPDFRendererContext, document: Agreement) { self.context = context; self.document = document }
    func asset(_ name: String, _ rect: CGRect, alpha: CGFloat = 1) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "png"), let image = UIImage(contentsOfFile: url.path) else {
            AppLog.pdf.error("Bundled branding asset could not be loaded: \(name, privacy: .public)")
            return
        }
        let scale = min(rect.width / image.size.width, rect.height / image.size.height)
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        image.draw(in: CGRect(x: rect.midX - size.width / 2, y: rect.midY - size.height / 2, width: size.width, height: size.height), blendMode: .normal, alpha: alpha)
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
        context.beginPage(); y = 128; pageNumber += 1
        let cg = context.cgContext
        cg.setFillColor(navy.cgColor)
        cg.fill(CGRect(x: 0, y: 0, width: AgreementPDFRenderer.pageSize.width, height: 5))
        asset("logo", CGRect(x: 55, y: 200, width: 485.25, height: 485.25), alpha: 0.065)
        asset("logo", CGRect(x: 15, y: 10.2, width: 100, height: 100))
        asset("construction", CGRect(x: 480.25, y: 10.2, width: 100, height: 100))
        let style = NSMutableParagraphStyle(); style.alignment = .center
        let a: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 17, weight: .bold), .foregroundColor: navy, .paragraphStyle: style]
        let headerWidth: CGFloat = 355.25
        let nameHeight = ceil((document.branding.name as NSString).boundingRect(with: CGSize(width: headerWidth, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: a, context: nil).height)
        (document.branding.name as NSString).draw(in: CGRect(x: (AgreementPDFRenderer.pageSize.width - headerWidth) / 2, y: 10.2 + max(0, (90 - nameHeight) / 2), width: headerWidth, height: nameHeight + 4), withAttributes: a)
        cg.setFillColor(navy.cgColor)
        cg.fill(CGRect(x: 26, y: 108.5, width: 543.25, height: 2))
        cg.setFillColor(green.cgColor)
        cg.fill(CGRect(x: 26, y: 108.5, width: 70, height: 2))
        cg.setFillColor(UIColor(red: 0.96, green: 0.97, blue: 0.985, alpha: 1).cgColor)
        cg.fill(CGRect(x: 0, y: 740, width: AgreementPDFRenderer.pageSize.width, height: 102))
        cg.setFillColor(navy.cgColor)
        cg.fill(CGRect(x: 26, y: 740, width: 543.25, height: 2))
        cg.setFillColor(green.cgColor)
        cg.fill(CGRect(x: 26, y: 740, width: 70, height: 2))
        let b = document.branding
        func footerText(_ text: String, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat = 16, bold: Bool = false) {
            (text as NSString).draw(in: CGRect(x: x, y: y, width: width, height: height), withAttributes: [.font: UIFont.systemFont(ofSize: 9, weight: bold ? .semibold : .regular), .foregroundColor: navy])
        }
        footerText("CONTACT", x: 26, y: 751, width: 270, bold: true)
        footerText(b.phones, x: 26, y: 768, width: 270)
        footerText(b.address, x: 26, y: 785, width: 270, height: 28)
        footerText(b.email, x: 315, y: 751, width: 254)
        footerText(b.website, x: 315, y: 768, width: 254)
        asset("instagram", CGRect(x: 315, y: 786, width: 12, height: 12))
        footerText(b.instagram, x: 333, y: 786, width: 236)
        asset("facebook", CGRect(x: 315, y: 803, width: 12, height: 12))
        footerText(b.facebook, x: 333, y: 803, width: 236, height: 26)
        footerText("Page \(pageNumber)", x: 26, y: 821, width: 270, bold: true)
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
