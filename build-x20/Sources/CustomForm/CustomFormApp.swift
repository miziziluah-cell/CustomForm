import SwiftUI

@main
struct CustomFormApp: App {
    var body: some Scene {
        WindowGroup("Custom Form") {
            ContentView()
                .frame(minWidth: 980, minHeight: 680)
        }
        .windowResizability(.contentMinSize)
    }
}
