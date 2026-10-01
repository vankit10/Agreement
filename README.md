# Adarsh Agreement Builder

Native SwiftUI app for iPhone and iPad, iOS 17+. Built from the supplied PRD with the original company logo, construction graphic, watermark and social icons extracted from the six-page agreement PDF.

## Open and run

1. Open `AdarshAgreement.xcodeproj` in Xcode 16 or later.
2. Select the `AdarshAgreement` scheme and an iPhone or iPad Simulator.
3. Press Run. No login, API key, third-party package or network service is required.
4. For a physical device, select your Apple development team under Signing & Capabilities and use a unique bundle identifier if needed.

## Included

- Home, recent documents, searchable saved documents, company settings.
- Shared UI styling with rounded system typography, consistent spacing and field padding, adaptive light/dark surfaces, subtle card shadows, pressed-button animations, haptics and accessible touch targets. Reduced Motion is respected.
- Guided client/project form, scope selection, full A–J specification catalog and section K pricing.
- Agreement creation and editing open as full navigation screens from Home and Saved Documents. Add New Title opens a sheet with a title field and bottom Cancel/Save buttons; Save or the keyboard Done action adds the title, while dismissal cancels.
- **Add New Title** in Scope of Work: name a custom section, edit its work wording and add multiple custom options. Custom titles appear in the wizard, review and PDF; they persist with the draft and can be excluded without losing their values.
- Brand multiselection, read-only built-in specification wording, editable custom options, custom brands, dimensions, quantities and flooring units. Reopening a draft restores any accidentally cleared built-in wording from the reference catalog.
- Flooring price ranges are optional. Enable Show price range to enter minimum/maximum prices and an optional unit. Disabled ranges are omitted from Review and PDF, while entered values remain saved for reuse.
- Option toggles sit beside their subtitles. The minus button removes an option; enter a subtitle and content, then tap plus to add an included option to the current work title.
- Decimal rupee calculations, optional extra work, explicit tax base, staircase adjustment confirmation and gate duplicate protection.
- Totals include the selected gate price, custom option fixed amounts and priced extras on top of area-based construction cost. Fees/review/PDF show the individual specification charges; payment milestones use the updated payable total. Unspecified tile price ranges and per-unit prices without quantities are not added as lump-sum charges.
- Floor measurements appear directly without inclusion switches; entering an area includes that floor and leaving it blank omits it. Terms and tax/penalty switches appear before their text.
- Editable payment milestones with 100% validation and final-milestone rounding allocation.
- Editable reference terms, blank signature lines and witness names.
- Atomic local JSON storage, autosave, draft recovery, independent duplication and confirmed deletion.
- Searchable PDF generation, PDFKit preview, page navigation, zoom, Files export and system sharing using the preview bytes.
- Original page geometry and graphics, overflow pagination, reference page grouping and optional trailing branding page.

## Project structure

| Folder | Purpose |
| --- | --- |
| `AdarshAgreement/Core` | Codable models, versioned default catalog, validation, decimal calculations, document blocks and local repository |
| `AdarshAgreement/Views` | SwiftUI screen layout and bindings; reusable UI components live in `Views/Components` |
| `AdarshAgreement/ViewModels` | Screen state and actions for Home, Saved Documents, Company Settings, Editor, Work Section and PDF Preview; shared DocumentsViewModel coordinates storage and rendering |
| `AdarshAgreement/Services` | UIKit/Core Text PDF rendering; the Foundation-only local repository remains in Core for portable testing |
| `AdarshAgreement/Resources` | Original extracted graphics and application icon |
| `Tests` | Portable calculation, validation, selection, custom title and persistence tests |
| `UITests` | iPhone workflow test for saving/reopening a draft, adding a title and generating a preview |
| `reference` | Unmodified supplied documents and measured PDF geometry |
| `docs` | Delivery notes and retained development checks; final Simulator verification was discontinued at the user's request |

## Tests

```sh
swift test
xcodebuild -project AdarshAgreement.xcodeproj -scheme AdarshAgreement \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO test
```

Simulator launch argument `--verify` produces baseline and long-text PDFs plus machine-readable verification results under the app's Documents/Verification directory. This is a development check, not an app screen.

## Change options and branding

The UI follows MVVM. Views bind to `@StateObject` view models and forward user actions. EditorViewModel owns wizard navigation, validation presentation, draft autosave and preview generation. WorkSectionViewModel owns custom option drafts, addition/removal and brand selection. PDFPreviewViewModel prepares export/share bytes and handles export results. Domain calculations and validation remain in Core; view models coordinate the repository and PDF renderer through DocumentsViewModel. UI dismissal and native PDFKit/share-sheet adapters stay in the view layer.

Update the default catalog in `Core/Catalog.swift`; keep existing option IDs stable and increment `templateVersion` in `Core/Models.swift` when the template changes. Each saved agreement contains its own catalog and branding snapshot, so default edits do not rewrite earlier agreements. Use Company Settings for contact details and the trailing-page preference. Work-title letters are computed from the included title order and rearrange after additions, exclusions or removals; stable section IDs and custom UUIDs do not change. Fees receive the next available letter. The same lettering appears in Scope, the wizard, Review and the PDF.

Graphics can be replaced with higher-resolution original files under the same resource names. `reference/geometry.json` records the measured 595.25 × 842 point PDF pages, source fonts and image positions.

## Console diagnostics and errors

Use Xcode's console or macOS Console and filter the subsystem `in.adarshinfra.agreementbuilder`. Categories are `Storage`, `PDF`, `Validation` and `Lifecycle`. Debug messages cover autosave/cache/export preparation; info messages record completed operations; notice messages record validation blocks; error messages include the failed operation and error domain/code/type. Console logs exclude client details, agreement text, prices, filenames, file paths, `userInfo` and localized error descriptions. Logging is local through Apple's unified logging system.

User-facing errors provide recovery instructions and keep editable form state available. Missing storage no longer silently succeeds for duplicate/delete/settings operations. Export cancellation is handled as cancellation rather than failure. Failed PDF loading is reported to the preview view model. Developer verification uses structured logging instead of print and avoids forced PDF unwraps.

## Release scope

The first release stores data locally and works offline. Optional private CloudKit sync is not enabled; its conflict resolution and tombstone policies require a separate implementation and two-device verification. Handwritten signatures, online signing, payment collection, invoicing and client/team accounts are outside the MVP.

The supplied source uses conflicting sagwan/Sakhu frame wording and leaves tile price units unspecified. The app preserves editable wording and shows review warnings. Tax and late-penalty clauses remain source wording; calculations only use explicit settings. The reconstructed PDF has added structured totals and flexible text layout, so it is not a pixel-identical reproduction of the source.

Production distribution requires device testing and Apple signing. Review final wording and ambiguous materials/units before releasing the app for real agreements.
