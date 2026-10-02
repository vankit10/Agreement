import SwiftUI

@main
struct AdarshAgreementApp: App {
    @StateObject private var store = DocumentsViewModel()
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("appLanguage") private var appLanguage = "system"
    var body: some Scene {
        WindowGroup {
            HomeView().environmentObject(store)
                .environment(\.locale, appLanguage == "system" ? .current : Locale(identifier: appLanguage))
                .tint(AgreementTheme.accent)
                .fontDesign(.rounded)
                .task {
                    if ProcessInfo.processInfo.arguments.contains("--verify") { Verification.run() }
                    while !Task.isCancelled {
                        AutomaticBackup.runIfDue(repository: store.repository)
                        try? await Task.sleep(for: .seconds(60))
                    }
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { AutomaticBackup.runIfDue(repository: store.repository) }
                }
        }
    }
}
