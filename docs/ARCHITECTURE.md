# MVVM architecture

Views render state and send actions to view models. They do not save files or generate PDFs.

| Layer | Responsibility |
| --- | --- |
| Core models | Structured agreements, catalog snapshots, prices and payment calculations |
| Core validation and layout | Finalization rules and generated agreement content |
| Views | Screen composition, input bindings, presentation and native UI adapters |
| ViewModels | Observable screen state, wizard actions, autosave scheduling, search, option management, company settings and export preparation |
| DocumentsViewModel | Shared document list and coordination of durable local storage and PDF caching |
| Services | Deterministic PDF renderer; Foundation repository in Core provides atomic local storage |

Existing saved-record formats, original branding assets and agreement pricing behavior remain compatible. Dependencies are explicit in editor lifecycle setup and screen actions; no screen directly accesses the repository. Native UI dismissal remains in SwiftUI views. PDF preview and export use the same persisted PDF bytes.
