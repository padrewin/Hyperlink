//
//  MainAppView.swift
//  Hyperlink
//
//  Created by padrewin on 26.02.2025.
//

import SwiftUI
import Cocoa
import Carbon

struct MainAppView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @State private var selectedTab = "general"
    @State private var isCheckingForUpdates = false
    
    // Detectăm Light/Dark Mode prin Environment
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            (colorScheme == .dark
                ? Color(red: 0.12, green: 0.12, blue: 0.10)
                : Color(red: 0.95, green: 0.92, blue: 0.88)
            )
            .edgesIgnoringSafeArea(.all)
            
            HStack(spacing: 0) {
                // MARK: - Sidebar
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 12) {
                            if let appIcon = NSApplication.shared.applicationIconImage {
                                Image(nsImage: appIcon)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 32, height: 32)
                            }
                            Text("Hyperlink")
                                .font(.title)
                                .fontWeight(.semibold)
                        }
                        .padding(.top, 20)
                        Text("Version 1.0.0")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
                    
                    Divider()
                        .padding(.horizontal, 12)
                    
                    SidebarNavItem(icon: "gearshape.fill", label: "General", tag: "general", selectedTab: $selectedTab)
                    SidebarNavItem(icon: "safari.fill",    label: "Browsers", tag: "browsers", selectedTab: $selectedTab)
                    SidebarNavItem(icon: "keyboard",       label: "Shortcut", tag: "shortcut", selectedTab: $selectedTab)
                    SidebarNavItem(icon: "wrench.and.screwdriver.fill", label: "Advanced", tag: "advanced", selectedTab: $selectedTab)
                    SidebarNavItem(icon: "paintbrush",     label: "Appearance", tag: "appearance", selectedTab: $selectedTab)
                    
                    Spacer()
                    
                    HStack {
                        // Quit button
                        Button(action: {
                            NSApp.terminate(nil)
                        }) {
                            Image(systemName: "power")
                                .font(.system(size: 16))
                                .frame(width: 40, height: 40)
                                .background(Color.gray.opacity(0.2))
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                        
                        // GitHub button
                        Button(action: {
                            NSWorkspace.shared.open(URL(string: "https://github.com/padrewin/hyperlink")!)
                        }) {
                            HStack(spacing: 8) {
                                // Încarci iconița GitHub din asset catalog (e.g. "GitHubIcon")
                                if let ghIcon = NSImage(named: "GitHubIcon") {
                                    Image(nsImage: ghIcon)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 25, height: 25)
                                        .frame(width: 25, height: 25)
                                }
                                Text("GitHub")
                            }
                            .font(.system(size: 14))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    // Crești padding-ul pe partea dreaptă
                    .padding(.leading, 20)
                    .padding(.trailing, 40)
                    .padding(.bottom, 20)
                }
                .frame(width: 220)
                .padding(.top, 1)
                
                // MARK: - Main content area
                VStack(spacing: 0) {
                    HStack {
                        Text(tabTitle)
                            .font(.title2)
                            .fontWeight(.medium)
                        Spacer()
                        if selectedTab == "general" {
                            Button(action: {
                                isCheckingForUpdates = true
                                viewModel.checkForUpdates { updateAvailable in
                                    isCheckingForUpdates = false
                                    if updateAvailable {
                                        let alert = NSAlert()
                                        alert.messageText = "Update Available"
                                        alert.informativeText = "A new version of Hyperlink is available. Would you like to download it?"
                                        alert.alertStyle = .informational
                                        alert.addButton(withTitle: "Download")
                                        alert.addButton(withTitle: "Cancel")
                                        let response = alert.runModal()
                                        if response == .OK {
                                            NSWorkspace.shared.open(URL(string: "https://github.com/padrewin/hyperlink/releases")!)
                                        }
                                    } else {
                                        let alert = NSAlert()
                                        alert.messageText = "No Updates Available"
                                        alert.informativeText = "You are running the latest version of Hyperlink."
                                        alert.alertStyle = .informational
                                        alert.runModal()
                                    }
                                }
                            }) {
                                HStack {
                                    if isCheckingForUpdates {
                                        ProgressView().scaleEffect(0.7)
                                        Text("Checking...")
                                    } else {
                                        Text("Check for Updates")
                                    }
                                }
                                .font(.system(size: 12))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(6)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 25)
                    .padding(.top, 20)
                    .padding(.bottom, 15)
                    
                    ScrollView {
                        ZStack {
                            if selectedTab == "general" {
                                GeneralSettingsCard(viewModel: viewModel)
                                    .transition(.move(edge: .trailing))
                            }
                            if selectedTab == "browsers" {
                                BrowsersSettingsCard(viewModel: viewModel)
                                    .transition(.move(edge: .trailing))
                            }
                            if selectedTab == "shortcut" {
                                ShortcutSettingsCard(viewModel: viewModel)
                                    .transition(.move(edge: .trailing))
                            }
                            if selectedTab == "advanced" {
                                AdvancedSettingsCard(viewModel: viewModel)
                                    .transition(.move(edge: .trailing))
                            }
                            if selectedTab == "appearance" {
                                AppearanceSettingsCard(viewModel: viewModel)
                                    .transition(.move(edge: .trailing))
                            }
                        }
                        .animation(.easeInOut, value: selectedTab)
                        .padding(.horizontal, 25)
                        .padding(.bottom, 25)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(width: 800, height: 500)
        }
    }
    
    var tabTitle: String {
        switch selectedTab {
        case "general":    return "General"
        case "browsers":   return "Manage Browsers"
        case "shortcut":   return "Keyboard Shortcut"
        case "advanced":   return "Advanced Settings"
        case "appearance": return "Appearance"
        default:           return "Settings"
        }
    }
}

// MARK: - Sidebar Navigation Item
struct SidebarNavItem: View {
    let icon: String
    let label: String
    let tag: String
    @Binding var selectedTab: String
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut) { selectedTab = tag }
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                Text(label)
                    .font(.system(size: 16, weight: .medium))
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(selectedTab == tag ? Color.blue.opacity(0.2) : Color.clear)
            )
            .foregroundColor(selectedTab == tag ? .blue : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - General Settings Card
struct GeneralSettingsCard: View {
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Launch settings card
            CardView {
                VStack(alignment: .leading, spacing: 16) {
                    Label("App Settings", systemImage: "gearshape")
                        .font(.headline)
                    
                    Divider()
                    
                    HStack {
                        Label("Launch at Login", systemImage: "play.circle")
                            .font(.body)
                        
                        Spacer()
                        
                        Toggle("", isOn: $viewModel.launchOnLogin)
                            .toggleStyle(SwitchToggleStyle())
                            .labelsHidden()
                            .onChange(of: viewModel.launchOnLogin) { newValue in
                                viewModel.updateLoginSetting(enabled: newValue)
                            }
                    }
                    
                    HStack {
                        Label("Check for Updates Automatically", systemImage: "arrow.clockwise")
                            .font(.body)
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { viewModel.checkUpdatesAutomatically },
                            set: { viewModel.setAutoUpdateCheck(enabled: $0) }
                        ))
                        .toggleStyle(SwitchToggleStyle())
                        .labelsHidden()
                    }
                }
                .padding()
            }
            
            // Help card
            CardView {
                VStack(alignment: .leading, spacing: 16) {
                    Label("Help & Support", systemImage: "questionmark.circle")
                        .font(.headline)
                    
                    Divider()
                    
                    HStack(spacing: 15) {
                        Button(action: {
                            NSWorkspace.shared.open(URL(string: "https://github.com/padrewin/hyperlink/issues")!)
                        }) {
                            Label("Report Issue", systemImage: "exclamationmark.triangle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(CardButtonStyle())
                        
                        Button(action: {
                            NSWorkspace.shared.open(URL(string: "https://github.com/padrewin/hyperlink/wiki")!)
                        }) {
                            Label("Documentation", systemImage: "book")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(CardButtonStyle())
                    }
                    
                    HStack(spacing: 15) {
                        Button(action: {
                            // Comprehensive diagnostic information
                            let diagnosticInfo = """
                            Hyperlink Diagnostic Information
                            
                            App Details:
                            Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
                            Build: \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown")
                            
                            Settings:
                            Enabled Browsers: \(viewModel.enabledBrowsers.joined(separator: ", "))
                            Launch on Login: \(viewModel.launchOnLogin)
                            Shortcut: \(viewModel.shortcutDisplayString)
                            Auto-Update Enabled: \(viewModel.checkUpdatesAutomatically)
                            
                            Debug Logging: \(UserDefaults.standard.bool(forKey: "DebugLoggingEnabled") ? "Enabled" : "Disabled")
                            
                            Timestamp: \(Date())
                            """
                            
                            let pasteboard = NSPasteboard.general
                            pasteboard.clearContents()
                            pasteboard.setString(diagnosticInfo, forType: .string)
                            
                            // Show confirmation alert
                            let alert = NSAlert()
                            alert.messageText = "Diagnostics Copied"
                            alert.informativeText = "Detailed diagnostic information has been copied to your clipboard."
                            alert.alertStyle = .informational
                            alert.runModal()
                        }) {
                            Label("Copy Diagnostics", systemImage: "doc.on.clipboard")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(CardButtonStyle())
                        
                        Button(action: {
                            // Reset settings function here
                            viewModel.resetToDefaults()
                        }) {
                            Label("Reset Settings", systemImage: "arrow.counterclockwise")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(CardButtonStyle())
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - Browsers Settings Card
struct BrowsersSettingsCard: View {
    @ObservedObject var viewModel: SettingsViewModel
    private let browserOrder = ["Safari", "Chrome", "Arc", "Edge", "Brave", "Firefox", "Opera", "Vivaldi", "Zen"]
    
    private func orderedBrowsers() -> [String] {
        return browserOrder.filter { viewModel.browsers.contains($0) }
    }
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                Label("Enable URL grabbing for these browsers", systemImage: "globe")
                    .font(.headline)
                
                Divider()
                
                ForEach(orderedBrowsers(), id: \.self) { browser in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 12) {
                            // Browser icon
                            BrowserIconLoader.createBrowserIcon(for: browser)
                                .frame(width: 24, height: 24)
                            
                            // Browser name
                            Text(browser)
                                .frame(minWidth: 80, alignment: .leading)
                            
                            Spacer()
                            
                            // Toggle switch
                            Toggle("", isOn: Binding(
                                get: { viewModel.enabledBrowsers.contains(browser) },
                                set: { newValue in
                                    if newValue {
                                        viewModel.enabledBrowsers.insert(browser)
                                    } else {
                                        viewModel.enabledBrowsers.remove(browser)
                                    }
                                    viewModel.saveEnabledBrowsers()
                                }
                            ))
                            .toggleStyle(SwitchToggleStyle())
                            .labelsHidden()
                        }
                        .padding(.vertical, 4)
                        
                        // Conditional warning for Arc
                        if browser == "Arc" {
                            Text("Arc has built-in URL copy shortcut. Enabling may cause conflicts.")
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.leading, 36)
                        }
                        
                        if browser != orderedBrowsers().last! {
                            Divider()
                        }
                    }
                }
                
                Text("When your keyboard shortcut is pressed, the URL will be copied from any enabled browser that's currently active.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }
            .padding()
        }
    }
}

// MARK: - Shortcut Settings Card
struct ShortcutSettingsCard: View {
    @ObservedObject var viewModel: SettingsViewModel
    
    @State private var isRecording = false
    @State private var keyMonitor = KeyEventMonitor()
    
    // Reținem vechile shortcutKeyCode / shortcutModifiers pentru revert
    @State private var oldKeyCode: UInt16 = 0
    @State private var oldModifiers: NSEvent.ModifierFlags = []
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                Label("Keyboard Shortcut", systemImage: "keyboard")
                    .font(.headline)
                
                Divider()
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Configure the keyboard shortcut that will copy the URL from your browser.")
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("Current Shortcut:")
                            .font(.body)
                        
                        Spacer()
                        
                        Button(action: {
                            if !isRecording {
                                // Începem "recording" => stocăm vechile valori
                                oldKeyCode = viewModel.shortcutKeyCode
                                oldModifiers = NSEvent.ModifierFlags(rawValue: UInt(viewModel.shortcutModifiers))
                            }
                            isRecording.toggle()
                        }) {
                            Text(isRecording ? "Recording..." : viewModel.shortcutDisplayString)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .frame(minWidth: 120)
                                .background(isRecording ? Color.red.opacity(0.2) : Color.blue.opacity(0.1))
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(isRecording ? Color.red : Color.blue, lineWidth: 1)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .onAppear {
                            NotificationCenter.default.addObserver(
                                forName: Notification.Name("KeyEventReceived"),
                                object: nil,
                                queue: .main
                            ) { notification in
                                guard isRecording,
                                      let event = notification.object as? NSEvent,
                                      event.type == .keyDown else { return }
                                
                                // Dacă se apasă Escape, anulăm înregistrarea și revenim la shortcut-ul anterior
                                if event.keyCode == UInt16(kVK_Escape) {
                                    print("Recording canceled. Reverting to old shortcut.")
                                    viewModel.recordShortcut(keyCode: oldKeyCode, modifiers: oldModifiers)
                                    isRecording = false
                                    return
                                }
                                
                                // Obținem modificatoarele din eveniment
                                let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
                                
                                // Verificăm dacă nu a fost apăsată nicio tastă modificatoare
                                if mods.isEmpty {
                                    print("Invalid shortcut: must include at least one modifier key")
                                    // Revert la shortcut-ul anterior și oprește înregistrarea
                                    viewModel.recordShortcut(keyCode: oldKeyCode, modifiers: oldModifiers)
                                    isRecording = false
                                    return
                                }
                                
                                // Dacă e o tastă validă (non-modifier), înregistrăm shortcut-ul
                                viewModel.recordShortcut(keyCode: event.keyCode, modifiers: mods)
                                isRecording = false
                            }
                        }
                    }
                    
                    if isRecording {
                        Text("Press a key combination... (Esc to cancel)")
                            .foregroundColor(.red)
                            .font(.callout)
                    }
                    
                    Text("This shortcut will copy the URL from your current browser tab when pressed.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
            }
            .padding()
        }
    }
}

// MARK: - Advanced Settings Card
struct AdvancedSettingsCard: View {
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // 1) Debug options card
            CardView {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Debugging", systemImage: "ladybug")
                        .font(.headline)
                    
                    Divider()
                    
                    HStack {
                        Label("Enable Debug Logging", systemImage: "doc.text")
                            .font(.body)
                        
                        Spacer()
                        
                        Toggle("", isOn: $viewModel.debugLoggingEnabled)
                            .toggleStyle(SwitchToggleStyle())
                            .labelsHidden()
                            .onChange(of: viewModel.debugLoggingEnabled) { newValue in
                                viewModel.setDebugLogging(enabled: newValue)
                            }
                    }
                    
                    Button(action: {
                        viewModel.saveDebugFile()
                    }) {
                        Label("Save Debug File", systemImage: "arrow.down.doc")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(CardButtonStyle())
                    .disabled(!viewModel.debugLoggingEnabled)
                }
                .padding()
            }
            
            // 2) Clipboard options
            CardView {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Clipboard Behavior", systemImage: "doc.on.clipboard")
                        .font(.headline)
                    
                    Divider()
                    
                    // Inlocuim SegmentedPicker cu un dropdown
                    Picker("After copying URL:", selection: Binding(
                        get: { viewModel.urlCopyBehavior },
                        set: { viewModel.setURLCopyBehavior($0) }
                    )) {
                        Text("Show Notification").tag(URLCopyBehavior.showNotification)
                        Text("Silent Copy").tag(URLCopyBehavior.silentCopy)
                        Text("Play Sound").tag(URLCopyBehavior.playSound)
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    HStack {
                        Label("Format URLs when copying", systemImage: "character.textbox")
                            .font(.body)
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { viewModel.formatURLWhenCopying },
                            set: { viewModel.setURLFormatting(enabled: $0) }
                        ))
                        .toggleStyle(SwitchToggleStyle())
                        .labelsHidden()
                    }
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

// MARK: - Appearance Settings Card
struct AppearanceSettingsCard: View {
    @ObservedObject var viewModel: SettingsViewModel
    let availableIcons = ["EXTL", "LINK"]
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Label("Appearance", systemImage: "paintbrush")
                    .font(.headline)
                Divider()
                    .font(.body)
                Picker("Menubar Icon", selection: $viewModel.selectedMenubarIcon) {
                    ForEach(availableIcons, id: \.self) { iconName in
                        HStack {
                            if let icon = NSImage(named: iconName) {
                                Image(nsImage: icon)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 16, height: 16)
                            }
                            Text(iconName)
                        }
                        .tag(iconName)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            .padding()
        }
    }
}

// MARK: - Card View Style
struct CardView<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            // Aici alegem culori diferite pentru Light vs. Dark
            .padding()
            .background(
                colorScheme == .dark
                    ? Color(red: 0.15, green: 0.15, blue: 0.15) // un gri-închis
                    : Color(white: 0.97)                       // un gri-deschis
            )
            .cornerRadius(10)
            // Umbră mai puternică în modul Dark, mai discretă în Light
            .shadow(
                color: colorScheme == .dark
                    ? Color.black.opacity(0.2)
                    : Color.black.opacity(0.05),
                radius: 3, x: 0, y: 1
            )
    }
}

// MARK: - Button Style
struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 8)
            .foregroundColor(configuration.isPressed ? .gray : .primary)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(configuration.isPressed ? 
                          Color.gray.opacity(0.2) : 
                          Color.gray.opacity(0.1))
            )
    }
}
