//
//  KioskRemoteControlApp.swift
//  Kiosk Remote Control
//
//  Created by Leo Mancini on 4/7/25.
//

import SwiftUI

@main
struct KioskRemoteControlApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("showInDock") private var showInDock = false
    @StateObject private var kioskState = KioskState()
    
    var body: some Scene {
        MenuBarExtra("Kiosk Control", systemImage: "display") {
            MenuContent(
                kioskURLs: $kioskState.kioskURLs,
                isLoading: $kioskState.isLoading,
                errorMessage: $kioskState.errorMessage,
                currentURL: $kioskState.currentURL,
                loadURLs: kioskState.loadKioskURLs
            )
        }
        .onChange(of: showInDock) { oldValue, newValue in
            appDelegate.updateDockVisibility()
        }
    }
}

class KioskState: ObservableObject {
    @Published var kioskURLs: [KioskURL] = []
    @Published var isLoading = true
    @Published var errorMessage: String? = nil
    @Published var currentURL: String? = nil
    
    init() {
        setupNotifications()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("InitialURLsLoaded"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let urls = notification.userInfo?["urls"] as? [KioskURL],
               let currentURL = notification.userInfo?["currentURL"] as? String {
                self?.kioskURLs = urls
                self?.currentURL = currentURL
                self?.isLoading = false
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("InitialURLsError"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let error = notification.userInfo?["error"] as? String {
                self?.errorMessage = error
                self?.isLoading = false
            }
        }
    }
    
    @MainActor
    func loadKioskURLs() async {
        isLoading = true
        errorMessage = nil
        
        do {
            kioskURLs = try await KioskService.shared.fetchKioskURLs()
            currentURL = try await KioskService.shared.fetchCurrentURL()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

struct MenuContent: View {
    @Binding var kioskURLs: [KioskURL]
    @Binding var isLoading: Bool
    @Binding var errorMessage: String?
    @Binding var currentURL: String?
    var loadURLs: () async -> Void
    
    private struct MenuItemPrefix: View {
        let isSelected: Bool
        
        var body: some View {
            HStack(spacing: 0) {
                if isSelected {
                    Text("✓")
                }
                Text("   ")
            }
            .frame(width: 20, alignment: .leading)
        }
    }
    
    var body: some View {
        Group {
            // Kiosk URLs Section
            if isLoading {
                Text("Loading available URLs...")
                    .foregroundColor(.secondary)
            } else if let error = errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                Button("Retry") {
                    Task { await loadURLs() }
                }
            } else if kioskURLs.isEmpty {
                Text("No URLs available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Button("Refresh") {
                    Task { await loadURLs() }
                }
            } else {
                ForEach(kioskURLs) { kioskURL in
                    Button {
                        Task {
                            do {
                                try await KioskService.shared.changeKioskURL(kioskURL.id)
                                currentURL = kioskURL.url
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                        }
                    } label: {
                        Text("\(currentURL == kioskURL.url ? "✓" : "   ")   \(kioskURL.title)")
                            .frame(minWidth: 250, alignment: .leading)
                    }
                }
            }
            
            Divider()
            
            Button("Refresh URLs") {
                Task { await loadURLs() }
            }
            
            Divider()
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
