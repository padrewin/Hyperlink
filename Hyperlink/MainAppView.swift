//
//  MainAppView.swift
//  Hyperlink
//
//  Created by padrewin on 26.02.2025.
//

import SwiftUI
import Cocoa
import Carbon

// MARK: - WindowAccessor
/// Attaches to the NSWindow hosting the SwiftUI view. When the window is added,
/// it sets its delegate, and calls makeKeyAndOrderFront to bring it to the front.
/// When the window becomes key, it ensures the app’s activation policy is set to regular.
struct WindowAccessor: NSViewRepresentable {
    var onWindowClose: () -> Void

    class Coordinator: NSObject, NSWindowDelegate {
        var onWindowClose: () -> Void
        init(onWindowClose: @escaping () -> Void) {
            self.onWindowClose = onWindowClose
        }
        
        func windowDidBecomeKey(_ notification: Notification) {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
            if let window = notification.object as? NSWindow {
                window.makeKeyAndOrderFront(nil)
            }
        }
        
        func windowWillClose(_ notification: Notification) {
            onWindowClose()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onWindowClose: onWindowClose)
    }
    
    func makeNSView(context: Context) -> NSView {
        let nsView = NSView()
        DispatchQueue.main.async {
            if let window = nsView.window {
                window.delegate = context.coordinator
                window.makeKeyAndOrderFront(nil)
            }
        }
        return nsView
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}

// MARK: - MainAppView
struct MainAppView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @State private var selectedTab = "general"
    @State private var isAudioWarmedUp = false
    
    private var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    // Detect Light/Dark Mode via Environment
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            VisualEffectView(material: colorScheme == .dark ? .hudWindow : .menu,
                             blendingMode: .behindWindow)
                .edgesIgnoringSafeArea(.all)
            
            HStack(spacing: 0) {
                // MARK: - Sidebar
                VStack(alignment: .leading, spacing: 10) {
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
                        Text("Version \(currentVersion)")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
                    
                    Divider()
                        .padding(.horizontal, 12)
                    
                    SidebarNavItem(icon: "general_icon", label: "General", tag: "general", selectedTab: $selectedTab)
                    SidebarNavItem(icon: "browsers_icon", label: "Browsers", tag: "browsers", selectedTab: $selectedTab)
                    SidebarNavItem(icon: "shortcut_icon", label: "Shortcut", tag: "shortcut", selectedTab: $selectedTab)
                    SidebarNavItem(icon: "advanced_icon", label: "Advanced", tag: "advanced", selectedTab: $selectedTab)
                    SidebarNavItem(icon: "appearance_icon", label: "Appearance", tag: "appearance", selectedTab: $selectedTab)
                    
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
                                if let ghIcon = NSImage(named: "GitHubIcon") {
                                    Image(nsImage: ghIcon)
                                        .resizable()
                                        .scaledToFit()
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
                    .padding(.leading, 20)
                    .padding(.trailing, 40)
                    .padding(.bottom, 20)
                }
                .frame(width: 220)
                .padding(.top, 1)
                
                // MARK: - Main Content Area
                VStack(spacing: 0) {
                    HStack {
                        if let icon = NSImage(named: selectedTab + "_icon") {
                            Image(nsImage: icon)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                        }
                        Text(tabTitle)
                            .font(.title2)
                            .fontWeight(.medium)
                        Spacer()
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
        // Ensure the Dock icon is shown when the view appears.
        .onAppear {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
        }
        
        // Attach our WindowAccessor to handle window events.
        .background(WindowAccessor {
            // When the window is closed, hide the Dock icon.
            NSApp.setActivationPolicy(.accessory)
        })
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

// MARK: - Visual Effect View for Vibrancy
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
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
            HStack(spacing: 6) {  // Further reduced to 6
                if let customIcon = NSImage(named: icon) {
                    Image(nsImage: customIcon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
                
                Text(label)
                    .font(.system(size: 16, weight: .medium))
                Spacer()
            }
            .padding(.vertical, 4)  // Reduced to 4
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(selectedTab == tag ? Color.gray.opacity(0.2) : Color.clear)
            )
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
            
            // Help & Support card
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
                            ...
                            """
                            
                            let pasteboard = NSPasteboard.general
                            pasteboard.clearContents()
                            pasteboard.setString(diagnosticInfo, forType: .string)
                            
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
                            viewModel.resetToDefaults()
                        }) {
                            Label("Reset Settings", systemImage: "arrow.counterclockwise")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(CardButtonStyle())
                    }
                    
                    Button(action: {
                        viewModel.checkForUpdates { updateAvailable in
                            DispatchQueue.main.async {
                                if updateAvailable {
                                    let alert = NSAlert()
                                    alert.messageText = "Update Available"
                                    alert.informativeText = "A new version of Hyperlink is available. Would you like to download it?"
                                    alert.alertStyle = .informational
                                    alert.addButton(withTitle: "Download")
                                    alert.addButton(withTitle: "Cancel")
                                    let response = alert.runModal()
                                    if response == .alertFirstButtonReturn {
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
                        }
                    }) {
                        Label("Check for Updates", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(CardButtonStyle())
                }
                .padding()
            }
        }
    }
}

// MARK: - Browsers Settings Card
struct BrowsersSettingsCard: View {
    @ObservedObject var viewModel: SettingsViewModel
    private let browserOrder = ["Safari", "Chrome", "Arc", "Edge", "Brave", "Firefox", "Opera", "Vivaldi", "Zen", "SigmaOS"]
    
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
                            
                            // Browser name + optional Arc tooltip
                            HStack(alignment: .center, spacing: 6) {
                                Text(browser)
                                    .frame(minWidth: 20, alignment: .leading)
                                if browser == "Arc" {
                                    InfoTooltip(
                                        text: "Arc has a built-in URL copy shortcut. \nEnabling this may cause conflicts.",
                                        hoverDelay: 0.02
                                    )
                                } else if browser == "Firefox" {
                                    InfoTooltip(
                                        text: "This will work only if \"devtools.policy.disabled\" is set to true in Mozilla to disable dev tools. \nOr using other shortcut than ⇧⌘C.",
                                        hoverDelay: 0.02
                                    )
                                }
                            }
                            
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

            // 2) Clipboard Behavior card
            CardView {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Clipboard Behavior", systemImage: "doc.on.clipboard")
                        .font(.headline)
                    
                    Divider()
                    
                    HStack {
                        Label("Show Notification", systemImage: "bell")
                            .font(.body)
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { viewModel.urlCopyBehavior.contains(.showNotification) },
                            set: { viewModel.toggleBehavior(.showNotification, enabled: $0) }
                        ))
                        .toggleStyle(SwitchToggleStyle())
                        .labelsHidden()
                    }

                    HStack {
                        Label("Play Sound", systemImage: "speaker.wave.2")
                            .font(.body)
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { viewModel.urlCopyBehavior.contains(.playSound) },
                            set: { viewModel.toggleBehavior(.playSound, enabled: $0) }
                        ))
                        .toggleStyle(SwitchToggleStyle())
                        .labelsHidden()
                    }

                    HStack(alignment: .center, spacing: 6) {
                        Label("Silent Copy", systemImage: "speaker.slash")
                            .font(.body)
                        
                        InfoTooltip(
                            text: "Enabling this option will stop any visual or audio feedback when copying.",
                            hoverDelay: 0.02  // apare aproape instant
                        )
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { viewModel.urlCopyBehavior.contains(.silentCopy) },
                            set: { viewModel.toggleBehavior(.silentCopy, enabled: $0) }
                        ))
                        .toggleStyle(SwitchToggleStyle())
                        .labelsHidden()
                    }
                }
                .padding()
            }

            // 3) Sound Preferences card
            Group {
                CardView {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Sound Preferences", systemImage: "speaker.wave.2")
                            .font(.headline)
 
                        Divider()
 
                        ForEach([
                            ("copy-sound", "Copy", "pencil"),
                            ("scissors", "Scissors", "scissors"),
                            ("page-chime", "Page Chime", "music.note")
                        ], id: \.0) { (key, label, icon) in
                            HStack {
                                Label(label, systemImage: icon)
                                    .font(.body)
 
                                Button(action: {
                                    ClipboardManager.shared.selectedSoundName = key
                                    ClipboardManager.shared.playSound()
                                }) {
                                    Image(systemName: "play.circle.fill")
                                        .foregroundColor(.accentColor)
                                }
                                .buttonStyle(PlainButtonStyle())
 
                                Spacer()
 
                                Toggle("", isOn: Binding(
                                    get: { viewModel.selectedSoundName == key },
                                    set: { newValue in
                                        if newValue {
                                            viewModel.selectedSoundName = key
                                            ClipboardManager.shared.selectedSoundName = key
                                            ClipboardManager.shared.savePreferences()
                                        }
                                    }
                                ))
                                .toggleStyle(SwitchToggleStyle())
                                .labelsHidden()
                            }
                        }
                    }
                    .padding()
                }
            }
            .disabled(viewModel.urlCopyBehavior.contains(.silentCopy))
            .opacity(viewModel.urlCopyBehavior.contains(.silentCopy) ? 0.4 : 1.0)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

struct InfoTooltip: View {
    let text: String
    /// Intervalul de timp (în secunde) după care apare tooltip-ul
    var hoverDelay: Double = 0.02
    
    @State private var isHovering = false
    @State private var scheduledShow = false
    
    var body: some View {
        // Pictograma sau elementul peste care faci hover
        Image(systemName: "questionmark.circle")
            .onHover { inside in
                if inside {
                    // Programăm afișarea popover-ului după `hoverDelay`
                    scheduledShow = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + hoverDelay) {
                        // Dacă încă suntem pe hover după 0.02s, afișăm popover-ul
                        if scheduledShow {
                            isHovering = true
                        }
                    }
                } else {
                    // Dacă ieșim cu mouse-ul, ascundem popover-ul imediat
                    scheduledShow = false
                    isHovering = false
                }
            }
            // Poți afișa textul într-un popover
            .popover(isPresented: $isHovering, arrowEdge: .top) {
                Text(text)
                    .padding(8)
            }
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

// MARK: CardView
struct CardView<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .background(
                ZStack {
                    // Sophisticated gradient for dark mode
                    LinearGradient(
                        gradient: Gradient(colors: colorScheme == .dark
                            ? [
                                Color(white: 0.2).opacity(0.6),
                                Color(white: 0.15).opacity(0.4)
                            ]
                            : [
                                Color.white.opacity(0.6),
                                Color.white.opacity(0.4)
                            ]
                        ),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            )
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        colorScheme == .dark
                            ? Color.white.opacity(0.1)
                            : Color.white.opacity(0.3),
                        lineWidth: 0.5
                    )
            )
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.2 : 0.05),
                radius: 1,
                x: 0,
                y: 0.5
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

