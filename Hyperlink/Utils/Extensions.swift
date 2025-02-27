import SwiftUI
import Cocoa
import Carbon

// Add extensions and helpers here
extension NSEvent {
    // Handle key event monitoring
    static func addLocalMonitor() -> Any {
        return NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            // Post notification for the key event
            NotificationCenter.default.post(name: Notification.Name("KeyEventReceived"), object: event)
            return event
        }!
    }
}

// Key event monitor class
class KeyEventMonitor {
    private var localMonitor: Any?
    
    init() {
        start()
    }
    
    func start() {
        if localMonitor == nil {
            localMonitor = NSEvent.addLocalMonitor()
        }
    }
    
    func stop() {
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }
    
    deinit {
        stop()
    }
}

// Extension to format key codes
extension UInt16 {
    func toKeyString() -> String {
        switch Int(self) {
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
        default: return "Key(\(self))"
        }
    }
}

// Extension to format modifier flags
extension NSEvent.ModifierFlags {
    func toSymbolString() -> String {
        var result = ""
        if contains(.control) { result += "⌃" }
        if contains(.option) { result += "⌥" }
        if contains(.shift) { result += "⇧" }
        if contains(.command) { result += "⌘" }
        return result
    }
}

// Helper function to identify modifier keys
func isModifierKeyCode(_ keyCode: UInt16) -> Bool {
    return keyCode == UInt16(kVK_Command) ||
           keyCode == UInt16(kVK_RightCommand) ||
           keyCode == UInt16(kVK_Option) ||
           keyCode == UInt16(kVK_RightOption) ||
           keyCode == UInt16(kVK_Control) ||
           keyCode == UInt16(kVK_RightControl) ||
           keyCode == UInt16(kVK_Shift) ||
           keyCode == UInt16(kVK_RightShift)
}

// Extension for visual styling
extension Color {
    static let controlBackground = Color(NSColor.controlBackgroundColor)
    static let secondaryLabelColor = Color(NSColor.secondaryLabelColor)
    static let textBackgroundColor = Color(NSColor.textBackgroundColor)
}

// Extension for window styling
extension NSWindow {
    func configureAsPreferencesWindow(title: String, width: CGFloat, height: CGFloat) {
        self.title = title
        self.styleMask = [.titled, .closable, .miniaturizable]
        self.titlebarAppearsTransparent = false
        self.isReleasedWhenClosed = false
        self.center()
        
        // Set fixed size
        self.minSize = NSSize(width: width, height: height)
        self.maxSize = NSSize(width: width, height: height)
        
        // Center on screen
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let windowRect = self.frame
            let x = screenRect.midX - windowRect.width / 2
            let y = screenRect.midY - windowRect.height / 2
            self.setFrameOrigin(NSPoint(x: x, y: y))
        }
    }
}
