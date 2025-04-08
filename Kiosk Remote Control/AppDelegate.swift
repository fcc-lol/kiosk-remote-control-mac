import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    @AppStorage("showInDock") private var showInDock = false
    private var initialLoadTask: Task<Void, Never>?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        updateDockVisibility()
        initialLoadTask = Task {
            do {
                let urls = try await KioskService.shared.fetchKioskURLs()
                let currentURL = try await KioskService.shared.fetchCurrentURL()
                NotificationCenter.default.post(
                    name: NSNotification.Name("InitialURLsLoaded"),
                    object: nil,
                    userInfo: ["urls": urls, "currentURL": currentURL]
                )
            } catch {
                NotificationCenter.default.post(
                    name: NSNotification.Name("InitialURLsError"),
                    object: nil,
                    userInfo: ["error": error.localizedDescription]
                )
            }
        }
    }
    
    func updateDockVisibility() {
        NSApp.setActivationPolicy(showInDock ? .regular : .accessory)
    }
} 