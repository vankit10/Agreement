import SwiftUI

@main
struct AdarshAgreementApp: App {
    @StateObject private var store = DocumentsViewModel()
    var body: some Scene {
        WindowGroup {
            HomeView().environmentObject(store)
                .tint(AgreementTheme.accent)
                .fontDesign(.rounded)
                .task {
                    if ProcessInfo.processInfo.arguments.contains("--verify") { Verification.run() }
                }
        }
    }
}
