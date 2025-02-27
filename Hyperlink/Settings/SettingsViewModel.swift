import SwiftUI
import Carbon

enum URLCopyBehavior: Int, Codable {
    case showNotification
    case silentCopy
    case playSound
}

class SettingsViewModel: ObservableObject {
    
    @Published var selectedMenubarIcon: String {
        didSet {
            // Salvează în UserDefaults
            UserDefaults.standard.set(selectedMenubarIcon, forKey: "SelectedMenubarIcon")
            // Postează notificare pentru actualizarea iconiței în menubar
            NotificationCenter.default.post(name: NSNotification.Name("MenubarIconChanged"), object: nil)
        }
    }
    
    private let appDelegate: AppDelegate
    
    @Published var launchOnLogin: Bool
    @Published var enabledBrowsers: Set<String>
    @Published var shortcutKeyCode: UInt16
    @Published var shortcutModifiers: UInt32
    @Published var checkUpdatesAutomatically: Bool = true
    @Published var debugLoggingEnabled: Bool = false
    @Published var formatURLWhenCopying: Bool = false
    
    // Add URL copy behavior property
    @Published var urlCopyBehavior: URLCopyBehavior = .showNotification
    
    // Add the updateChecker property
    let updateChecker = UpdateChecker()
    
    var browsers: [String] {
        return Array(appDelegate.browsers.keys)
    }
    
    var shortcutDisplayString: String {
        if shortcutKeyCode == 0 && shortcutModifiers == 0 {
            return "Click to record"
        }
        
        let modifierString = modifiersToString(shortcutModifiers)
        let keyString = keyCodeToString(shortcutKeyCode)
        return "\(modifierString)\(keyString)"
    }
    
    init(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
        
        let defaults = UserDefaults.standard
        
        self.launchOnLogin = defaults.bool(forKey: appDelegate.kLaunchOnLoginKey)
        
        if let savedBrowsers = defaults.stringArray(forKey: appDelegate.kEnabledBrowsersKey) {
            self.enabledBrowsers = Set(savedBrowsers)
        } else {
            self.enabledBrowsers = Set(appDelegate.browsers.keys)
        }
        
        self.selectedMenubarIcon = UserDefaults.standard.string(forKey: "SelectedMenubarIcon") ?? "EXTL"
        
        self.shortcutKeyCode = UInt16(defaults.integer(forKey: appDelegate.kShortcutKeyCodeKey))
        self.shortcutModifiers = UInt32(defaults.integer(forKey: appDelegate.kShortcutModifiersKey))
        
        // Load auto update check preference
        self.checkUpdatesAutomatically = defaults.bool(forKey: "CheckUpdatesAutomatically")
        
        self.formatURLWhenCopying = defaults.bool(forKey: "FormatURLWhenCopying")
        
        // Load URL copy behavior
        if let rawValue = defaults.object(forKey: "URLCopyBehavior") as? Int,
           let behavior = URLCopyBehavior(rawValue: rawValue) {
            self.urlCopyBehavior = behavior
        }
    }
    
    // URL formatting method
    func formatURL(_ url: String) -> String {
        guard formatURLWhenCopying, var components = URLComponents(string: url) else {
            return url
        }
        
        // Remove tracking parameters
        let trackingParams = ["utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content"]
        components.queryItems = components.queryItems?.filter { item in
            return !trackingParams.contains(item.name)
        }
        
        // Remove www
        if components.host?.hasPrefix("www.") == true {
            components.host = components.host?.replacingOccurrences(of: "www.", with: "")
        }
        
        // Prefer HTTPS
        if components.scheme == "http" {
            components.scheme = "https"
        }
        
        // Reconstruct URL
        return components.url?.absoluteString ?? url
    }
    
    // Method to set URL formatting preference
    func setURLFormatting(enabled: Bool) {
        formatURLWhenCopying = enabled
        UserDefaults.standard.set(enabled, forKey: "FormatURLWhenCopying")
    }
    
    // Method to set URL copy behavior
    func setURLCopyBehavior(_ behavior: URLCopyBehavior) {
        urlCopyBehavior = behavior
        UserDefaults.standard.set(behavior.rawValue, forKey: "URLCopyBehavior")
    }
    
    func updateLoginSetting(enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: appDelegate.kLaunchOnLoginKey)
        appDelegate.updateLoginItemSettings()
    }
    
    func saveEnabledBrowsers() {
        UserDefaults.standard.set(Array(enabledBrowsers), forKey: appDelegate.kEnabledBrowsersKey)
    }
    
    func recordShortcut(keyCode: UInt16, modifiers: NSEvent.ModifierFlags) {
        self.shortcutKeyCode = keyCode
        self.shortcutModifiers = UInt32(modifiers.rawValue)
        
        // Save to UserDefaults
        let defaults = UserDefaults.standard
        defaults.set(shortcutKeyCode, forKey: appDelegate.kShortcutKeyCodeKey)
        defaults.set(shortcutModifiers, forKey: appDelegate.kShortcutModifiersKey)
        
        // Register the new shortcut
        appDelegate.registerShortcut()
        
        // Print debug information
        print("Recorded Shortcut: Key Code = \(keyCode), Modifiers = \(modifiers.rawValue)")
    }
    
    func checkForUpdates(completion: ((Bool) -> Void)? = nil) {
        updateChecker.checkForUpdates { updateAvailable, _ in
            DispatchQueue.main.async {
                completion?(updateAvailable)
            }
        }
    }
    
    func setAutoUpdateCheck(enabled: Bool) {
        self.checkUpdatesAutomatically = enabled
        UserDefaults.standard.set(enabled, forKey: "CheckUpdatesAutomatically")
    }
    
    // Methods for debug functionality
    func setDebugLogging(enabled: Bool) {
        debugLoggingEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "DebugLoggingEnabled")
        
        if enabled {
            startDebugLogging()
        } else {
            stopDebugLogging()
        }
    }
    
    private func startDebugLogging() {
        // Redirect console output to a file
        let logFileURL = getLogFileURL()
        
        // Redirect stdout and stderr to the log file
        freopen(logFileURL.path.cString(using: .ascii), "a+", stdout)
        freopen(logFileURL.path.cString(using: .ascii), "a+", stderr)
        
        print("Debug logging started at \(Date())")
    }

    private func stopDebugLogging() {
        // Close file handles and reset to default
        fflush(stdout)
        fflush(stderr)
        
        print("Debug logging stopped at \(Date())")
    }

    func saveDebugFile() {
        let logFileURL = getLogFileURL()
        
        // Create save panel
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.plainText]
        savePanel.nameFieldStringValue = "hyperlink_debug_log.txt"
        
        savePanel.begin { result in
            if result == .OK, let url = savePanel.url {
                do {
                    try FileManager.default.copyItem(at: logFileURL, to: url)
                    
                    // Show success alert
                    let alert = NSAlert()
                    alert.messageText = "Debug Log Saved"
                    alert.informativeText = "The debug log has been saved successfully."
                    alert.alertStyle = .informational
                    alert.runModal()
                } catch {
                    // Show error alert
                    let alert = NSAlert()
                    alert.messageText = "Error Saving Log"
                    alert.informativeText = "Could not save the debug log: \(error.localizedDescription)"
                    alert.alertStyle = .warning
                    alert.runModal()
                }
            }
        }
    }

    private func getLogFileURL() -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent("hyperlink_debug.log")
    }
    
    // Resetting to defaults
    func resetToDefaults() {
        let defaults = UserDefaults.standard
        
        // Reset launch on login
        launchOnLogin = false
        defaults.set(false, forKey: appDelegate.kLaunchOnLoginKey)
        appDelegate.updateLoginItemSettings()
        
        // Reset enabled browsers to all browsers
        enabledBrowsers = Set(appDelegate.browsers.keys)
        defaults.set(Array(enabledBrowsers), forKey: appDelegate.kEnabledBrowsersKey)
        
        // Reset shortcut to Command+Shift+C
        shortcutKeyCode = UInt16(kVK_ANSI_C)
        shortcutModifiers = UInt32(NSEvent.ModifierFlags.command.rawValue | NSEvent.ModifierFlags.shift.rawValue)
        defaults.set(shortcutKeyCode, forKey: appDelegate.kShortcutKeyCodeKey)
        defaults.set(shortcutModifiers, forKey: appDelegate.kShortcutModifiersKey)
        appDelegate.registerShortcut()
        
        // Reset other settings
        checkUpdatesAutomatically = true
        defaults.set(true, forKey: "CheckUpdatesAutomatically")
        
        print("All settings have been reset to defaults")
    }
    
    private func modifiersToString(_ modifiers: UInt32) -> String {
        var result = ""
        let modifierFlags = NSEvent.ModifierFlags(rawValue: UInt(modifiers))
        
        if modifierFlags.contains(.control) { result += "⌃" }
        if modifierFlags.contains(.option) { result += "⌥" }
        if modifierFlags.contains(.shift) { result += "⇧" }
        if modifierFlags.contains(.command) { result += "⌘" }
        
        return result
    }
    
    private func keyCodeToString(_ keyCode: UInt16) -> String {
        switch Int(keyCode) {
        case kVK_ANSI_A: return "A"
        case kVK_ANSI_B: return "B"
        case kVK_ANSI_C: return "C"
        case kVK_ANSI_D: return "D"
        case kVK_ANSI_E: return "E"
        case kVK_ANSI_F: return "F"
        case kVK_ANSI_G: return "G"
        case kVK_ANSI_H: return "H"
        case kVK_ANSI_I: return "I"
        case kVK_ANSI_J: return "J"
        case kVK_ANSI_K: return "K"
        case kVK_ANSI_L: return "L"
        case kVK_ANSI_M: return "M"
        case kVK_ANSI_N: return "N"
        case kVK_ANSI_O: return "O"
        case kVK_ANSI_P: return "P"
        case kVK_ANSI_Q: return "Q"
        case kVK_ANSI_R: return "R"
        case kVK_ANSI_S: return "S"
        case kVK_ANSI_T: return "T"
        case kVK_ANSI_U: return "U"
        case kVK_ANSI_V: return "V"
        case kVK_ANSI_W: return "W"
        case kVK_ANSI_X: return "X"
        case kVK_ANSI_Y: return "Y"
        case kVK_ANSI_Z: return "Z"
        case kVK_ANSI_0: return "0"
        case kVK_ANSI_1: return "1"
        case kVK_ANSI_2: return "2"
        case kVK_ANSI_3: return "3"
        case kVK_ANSI_4: return "4"
        case kVK_ANSI_5: return "5"
        case kVK_ANSI_6: return "6"
        case kVK_ANSI_7: return "7"
        case kVK_ANSI_8: return "8"
        case kVK_ANSI_9: return "9"
        case kVK_Space: return "Space"
        case kVK_Return: return "↩"
        case kVK_Tab: return "⇥"
        case kVK_Escape: return "⎋"
        case kVK_Delete: return "⌫"
        case kVK_ForwardDelete: return "⌦"
        case kVK_LeftArrow: return "←"
        case kVK_RightArrow: return "→"
        case kVK_UpArrow: return "↑"
        case kVK_DownArrow: return "↓"
        case kVK_F1: return "F1"
        case kVK_F2: return "F2"
        case kVK_F3: return "F3"
        case kVK_F4: return "F4"
        case kVK_F5: return "F5"
        case kVK_F6: return "F6"
        case kVK_F7: return "F7"
        case kVK_F8: return "F8"
        case kVK_F9: return "F9"
        case kVK_F10: return "F10"
        case kVK_F11: return "F11"
        case kVK_F12: return "F12"
        default: return "Key(\(keyCode))"
        }
    }
}
