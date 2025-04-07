import Cocoa
import SwiftUI
import Carbon
import ServiceManagement
import UserNotifications
import ApplicationServices
import AVFoundation

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem!
    var settingsWindow: NSWindow?
    var viewModel: SettingsViewModel!
    var soundPlayer: AVAudioPlayer?
    var isSimulatingKeyPress = false
    
    
    // Local shortcut manager
    var localShortcutMonitor: Any? = nil
    var globalShortcutMonitor: Any? = nil
    var shortcutKeyCode: UInt16 = 0
    var shortcutModifiers: UInt32 = 0
    
    // Browser identifiers
    let browsers = [
        "Safari": "com.apple.Safari",
        "Chrome": "com.google.Chrome",
        "Arc": "company.thebrowser.Browser",
        "Edge": "com.microsoft.edgemac",
        "Brave": "com.brave.Browser",
        "Firefox": "org.mozilla.firefox",
        "Opera": "com.operasoftware.Opera",
        "Vivaldi": "com.vivaldi.Vivaldi",
        "Zen": "app.zen-browser.zen"
    ]
    
    // User defaults keys
    let kEnabledBrowsersKey = "EnabledBrowsers"
    let kLaunchOnLoginKey = "LaunchOnLogin"
    let kShortcutKeyCodeKey = "ShortcutKeyCode"
    let kShortcutModifiersKey = "ShortcutModifiers"
    
    private func playCopySound() {
        guard let soundURL = Bundle.main.url(forResource: "copy-sound", withExtension: "caf") else {
            print("Sound file not found")
            return
        }
        
        // Inițializează player-ul folosind try?
        self.soundPlayer = try? AVAudioPlayer(contentsOf: soundURL)
        self.soundPlayer?.play()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ascunde aplicația din Dock
        NSApp.setActivationPolicy(.accessory)
        
        print("URLGrabber started")
        
        setupDefaultsIfNeeded()
        viewModel = SettingsViewModel(appDelegate: self)
        checkImageAssets()
        setupMenuBar()
        checkAccessibilityPermissions()
        registerShortcut()
        
        if #available(macOS 10.14, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
                if granted {
                    print("Notification permission granted")
                } else {
                    print("Notification permission denied: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.updateLoginItemSettings()
        }
        
        // Ascultă notificările pentru schimbarea iconiței menubar
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateMenuBarIcon),
                                               name: NSNotification.Name("MenubarIconChanged"),
                                               object: nil)
    }
    
    func setupDefaultsIfNeeded() {
        let defaults = UserDefaults.standard
        
        if defaults.object(forKey: kEnabledBrowsersKey) == nil {
            defaults.set(Array(browsers.keys), forKey: kEnabledBrowsersKey)
        }
        
        if defaults.object(forKey: kLaunchOnLoginKey) == nil {
            defaults.set(false, forKey: kLaunchOnLoginKey)
        }
        
        if defaults.object(forKey: kShortcutKeyCodeKey) == nil {
            defaults.set(UInt16(kVK_ANSI_C), forKey: kShortcutKeyCodeKey)
        }
        
        if defaults.object(forKey: kShortcutModifiersKey) == nil {
            let defaultModifiers = NSEvent.ModifierFlags.command.rawValue | NSEvent.ModifierFlags.shift.rawValue
            defaults.set(UInt32(defaultModifiers), forKey: kShortcutModifiersKey)
        }
    }
    
    func setupMenuBar() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusBarItem.button {
            let iconName = UserDefaults.standard.string(forKey: "SelectedMenubarIcon") ?? "EXTL"
            if let icon = NSImage(named: iconName) {
                icon.isTemplate = true
                button.image = icon
            } else {
                // Fallback la simbolul "link" (atenție la litere mici)
                button.image = NSImage(systemSymbolName: "link", accessibilityDescription: "URL Grabber")
            }
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Preferences", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusBarItem.menu = menu
    }
    
    @objc func updateMenuBarIcon() {
        if let button = statusBarItem.button {
            let iconName = UserDefaults.standard.string(forKey: "SelectedMenubarIcon") ?? "EXTL"
            if let icon = NSImage(named: iconName) {
                icon.isTemplate = true
                button.image = icon
            }
        }
    }
    
    @objc func openSettings() {
        if settingsWindow == nil {
            let contentView = MainAppView(viewModel: viewModel)
            let hostingController = NSHostingController(rootView: contentView)
            
            settingsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 800, height: 500),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )

            // These settings are good
            settingsWindow?.titleVisibility = .hidden
            settingsWindow?.titlebarAppearsTransparent = true
            settingsWindow?.styleMask.insert(.fullSizeContentView)
            settingsWindow?.isMovableByWindowBackground = true
            
            // Centrează fereastra folosind visibleFrame pentru a o poziționa central (orizontal și vertical)
            if let screen = NSScreen.main {
                let screenFrame = screen.visibleFrame
                let windowFrame = settingsWindow!.frame
                let centerX = screenFrame.origin.x + (screenFrame.size.width - windowFrame.size.width) / 2
                let centerY = screenFrame.origin.y + (screenFrame.size.height - windowFrame.size.height) / 2
                settingsWindow?.setFrameOrigin(NSPoint(x: centerX, y: centerY))
            }
            
            settingsWindow?.contentViewController = hostingController
            settingsWindow?.isReleasedWhenClosed = false
            settingsWindow?.minSize = NSSize(width: 800, height: 500)
        }
        
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func registerShortcut() {
        if let monitor = localShortcutMonitor {
            NSEvent.removeMonitor(monitor)
            localShortcutMonitor = nil
        }
        
        if let monitor = globalShortcutMonitor {
            NSEvent.removeMonitor(monitor)
            globalShortcutMonitor = nil
        }
        
        let defaults = UserDefaults.standard
        shortcutKeyCode = UInt16(defaults.integer(forKey: kShortcutKeyCodeKey))
        shortcutModifiers = UInt32(defaults.integer(forKey: kShortcutModifiersKey))
        
        print("Registered shortcut: Key code \(shortcutKeyCode), Modifiers \(shortcutModifiers)")
        
        globalShortcutMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return }
            // Ignorăm evenimentele simulate
            if self.isSimulatingKeyPress { return }
            if event.keyCode == self.shortcutKeyCode &&
               event.modifierFlags.contains(NSEvent.ModifierFlags(rawValue: UInt(self.shortcutModifiers))) {
                self.getCurrentURL()
            }
        }
        
        localShortcutMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            if self.isSimulatingKeyPress { return event }
            if event.keyCode == self.shortcutKeyCode &&
               event.modifierFlags.contains(NSEvent.ModifierFlags(rawValue: UInt(self.shortcutModifiers))) {
                self.getCurrentURL()
                return nil
            }
            return event
        }
    }
    
    @objc func getCurrentURL() {
        print("getCurrentURL called")
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            print("Error: Could not get frontmost application")
            return
        }
        let bundleID = frontmostApp.bundleIdentifier ?? ""
        print("Frontmost app: \(frontmostApp.localizedName ?? "Unknown"), Bundle ID: \(bundleID)")
        guard let enabledBrowsers = UserDefaults.standard.stringArray(forKey: kEnabledBrowsersKey) else {
            print("Error: No enabled browsers found in UserDefaults")
            return
        }
        print("Enabled browsers: \(enabledBrowsers)")
        guard browsers.values.contains(bundleID),
              let browserName = browsers.first(where: { $0.value == bundleID })?.key else {
            print("Error: Not a supported browser: \(bundleID)")
            return
        }
        guard enabledBrowsers.contains(browserName) else {
            print("Error: Browser \(browserName) is not enabled")
            return
        }
        print("Detected browser: \(browserName)")
        
        let task = Process()
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        task.launchPath = "/usr/bin/osascript"
        
        var args: [String] = []
        switch bundleID {
        case browsers["Safari"]:
            args = [
                "-e", "tell application \"Safari\"",
                "-e", "get URL of current tab of first window",
                "-e", "end tell"
            ]
        case browsers["Chrome"], browsers["Brave"], browsers["Edge"], browsers["Vivaldi"]:
            args = [
                "-e", "tell application \"\(browserName)\"",
                "-e", "get URL of active tab of first window",
                "-e", "end tell"
            ]
        case browsers["Arc"], browsers["Zen"]:
            args = [
                "-e", "tell application \"\(browserName)\"",
                "-e", "get URL of active tab of first window",
                "-e", "end tell"
            ]
        case browsers["Opera"]:
            args = [
                "-e", "tell application \"Opera\"",
                "-e", "get URL of active tab of window 1",
                "-e", "end tell"
            ]
        case browsers["Firefox"]:
            args = [
                "-e", "tell application \"Firefox\"",
                "-e", "get URL of active tab of first window",
                "-e", "end tell"
            ]
        default:
            print("Unsupported browser: \(bundleID)")
            return
        }
        
        task.arguments = args
        print("Executing osascript for \(browserName)...")
        print(args.joined(separator: " "))
        
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let trimmedOutput = output.trimmingCharacters(in: .whitespacesAndNewlines)
                print("osascript result: \(trimmedOutput)")
                if !trimmedOutput.isEmpty && !trimmedOutput.contains("error") {
                    let urlToCopy = trimmedOutput
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(urlToCopy, forType: .string)
                    ClipboardManager.shared.copyURLToClipboard(
                        urlToCopy,
                        playSound: viewModel.urlCopyBehavior.contains(.playSound),
                        showNotification: viewModel.urlCopyBehavior.contains(.showNotification)
                    )
                    print("Successfully copied URL: \(urlToCopy)")
                } else {
                    print("AppleScript failed with output: \(trimmedOutput)")
                    // Fallback logic:
                    if browserName.lowercased() == "firefox" {
                        print("Using fallback sequence (Cmd+L, Cmd+C) for Firefox")
                        simulateFirefoxCopyURL()
                    } else if browserName.lowercased() == "zen" {
                        print("Using Zen shortcut simulation (Cmd+Shift+C)")
                        simulateZenCopyURLShortcut()
                    } else {
                        print("Using fallback sequence (Cmd+L, Cmd+A, Cmd+C)")
                        simulateCopyURLFallback()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        if let fallbackURL = NSPasteboard.general.string(forType: .string) {
                            ClipboardManager.shared.copyURLToClipboard(
                                fallbackURL,
                                playSound: self.viewModel.urlCopyBehavior.contains(.playSound),
                                showNotification: self.viewModel.urlCopyBehavior.contains(.showNotification)
                            )
                            print("Fallback copied URL: \(fallbackURL)")
                        } else {
                            print("Fallback did not retrieve any URL")
                        }
                    }
                }
            }
        } catch {
            print("Failed to execute osascript: \(error)")
            // Fallback logic in case of error
            if browserName.lowercased() == "firefox" {
                print("Using fallback sequence (Cmd+L, Cmd+C) for Firefox")
                simulateFirefoxCopyURL()
            } else if browserName.lowercased() == "zen" {
                print("Using Zen shortcut simulation (Cmd+Shift+C)")
                simulateZenCopyURLShortcut()
            } else {
                print("Using fallback sequence (Cmd+L, Cmd+A, Cmd+C)")
                simulateCopyURLFallback()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if let fallbackURL = NSPasteboard.general.string(forType: .string) {
                    ClipboardManager.shared.copyURLToClipboard(
                        fallbackURL,
                        playSound: self.viewModel.urlCopyBehavior.contains(.playSound),
                        showNotification: self.viewModel.urlCopyBehavior.contains(.showNotification)
                    )
                    print("Fallback copied URL after error: \(fallbackURL)")
                } else {
                    print("Fallback did not retrieve any URL after error")
                }
            }
        }
    }
    
    func simulateKeyPress(keyCode: CGKeyCode, flags: CGEventFlags = []) {
        guard let source = CGEventSource(stateID: .combinedSessionState) else { return }
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
        keyDown?.flags = flags
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        keyUp?.flags = flags
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
    
    func simulateZenCopyURLShortcut() {
        isSimulatingKeyPress = true
        simulateKeyPress(keyCode: CGKeyCode(kVK_ANSI_C), flags: [.maskCommand, .maskShift])
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isSimulatingKeyPress = false
        }
    }
    
    func simulateFirefoxCopyURL() {
        isSimulatingKeyPress = true
        simulateKeyPress(keyCode: CGKeyCode(kVK_ANSI_L), flags: [.maskCommand])
        simulateKeyPress(keyCode: CGKeyCode(kVK_ANSI_C), flags: [.maskCommand])
        simulateKeyPress(keyCode: CGKeyCode(kVK_ANSI_C), flags: [.maskCommand])
        simulateKeyPress(keyCode: CGKeyCode(kVK_Escape), flags: [])
        simulateKeyPress(keyCode: CGKeyCode(kVK_Escape), flags: [])
        isSimulatingKeyPress = false
    }
    
    func simulateCopyURLFallback() {
        isSimulatingKeyPress = true
        simulateKeyPress(keyCode: CGKeyCode(kVK_ANSI_L), flags: [.maskCommand])
        usleep(150_000)
        simulateKeyPress(keyCode: CGKeyCode(kVK_ANSI_A), flags: [.maskCommand])
        usleep(150_000)
        simulateKeyPress(keyCode: CGKeyCode(kVK_ANSI_C), flags: [.maskCommand])
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isSimulatingKeyPress = false
        }
    }
    
    func updateLoginItemSettings() {
        let launchOnLogin = UserDefaults.standard.bool(forKey: kLaunchOnLoginKey)
        if #available(macOS 13.0, *) {
            do {
                let appService = SMAppService.mainApp
                if launchOnLogin {
                    if appService.status != .enabled {
                        try? appService.register()
                    }
                } else {
                    if appService.status == .enabled {
                        try? appService.unregister()
                    }
                }
            }
        } else {
            print("Launch at login for older macOS requires a helper app")
        }
    }
    
    func checkAccessibilityPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
        print("Accessibility access enabled: \(accessEnabled)")
        if !accessEnabled {
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Accessibility Permissions Required"
                alert.informativeText = "Hyperlink needs accessibility permissions to detect keyboard shortcuts. Please open System Preferences and enable permissions."
                alert.addButton(withTitle: "Open System Preferences")
                alert.addButton(withTitle: "Later")
                let response = alert.runModal()
                if response == .alertFirstButtonReturn {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                }
            }
        }
    }
    
    func checkImageAssets() {
        let browserLogos = ["safari-logo", "chrome-logo", "firefox-logo", "edge-logo", "brave-logo",
                            "opera-logo", "arc-logo", "vivaldi-logo", "zen-logo"]
        for logoName in browserLogos {
            if let image = NSImage(named: logoName) {
                print("✅ Found image asset: \(logoName), size: \(image.size)")
            } else {
                print("❌ Missing image asset: \(logoName)")
            }
        }
        let mainBundle = Bundle.main
        if let resourcePath = mainBundle.resourcePath {
            print("Resource path: \(resourcePath)")
            do {
                let files = try FileManager.default.contentsOfDirectory(atPath: resourcePath)
                print("Files in resource path:")
                for file in files {
                    print("  - \(file)")
                }
            } catch {
                print("Error listing files: \(error)")
            }
            if let assetCatalogs = try? FileManager.default.contentsOfDirectory(atPath: resourcePath).filter({ $0.hasSuffix(".car") }) {
                print("Asset catalogs: \(assetCatalogs)")
            }
        }
    }
    
    func showPermissionError() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Permissions Required"
            alert.informativeText = "Hyperlink needs permission to control other applications. Please go to System Preferences > Security & Privacy > Privacy > Automation and enable permissions for this app."
            alert.addButton(withTitle: "Open System Preferences")
            alert.addButton(withTitle: "Cancel")
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")!)
            }
        }
    }
    
    func testURLGrabbing() {
        getCurrentURL()
    }
}
