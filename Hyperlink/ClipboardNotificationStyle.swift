//
//  ClipboardNotificationStyle.swift
//  Hyperlink
//
//  Created by padrewin on 26.02.2025.
//


import Cocoa
import AVFoundation
import UserNotifications

enum ClipboardNotificationStyle: Int, CaseIterable {
    case showNotification = 0
    case silent = 1
    case playSound = 2
    case soundAndNotification = 3
    
    var displayName: String {
        switch self {
        case .showNotification: return "Show Notification"
        case .silent: return "Silent Copy"
        case .playSound: return "Play Sound"
        case .soundAndNotification: return "Sound & Notification"
        }
    }
}

class ClipboardManager {
    // Shared instance
    static let shared = ClipboardManager()
    
    // Current notification style
    var notificationStyle: ClipboardNotificationStyle = .showNotification
    var selectedSoundName: String = "copy-sound" // default value
    
    // Audio player for sound notifications
    private var audioPlayer: AVAudioPlayer?
    
    // Load sound file
    private func loadSound() {
        audioPlayer = nil
        
        // Try to find the sound file in the bundle
        if let soundURL = Bundle.main.url(forResource: selectedSoundName, withExtension: "caf") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.prepareToPlay()
            } catch {
                print("Error loading sound: \(error.localizedDescription)")
            }
        } else {
            // Fallback to system sound if file not found
            print("Sound file not found in bundle, using system sound")
        }
    }
    
    // Play the notification sound
    func playSound() {
        DispatchQueue.global(qos: .userInitiated).async {
            // Load the sound on a background thread
            self.audioPlayer = nil
            self.loadSound()

            // Switch back to main thread to actually play
            DispatchQueue.main.async {
                if let player = self.audioPlayer {
                    player.currentTime = 0
                    player.play()
                } else {
                    // Fallback to system sound
                    NSSound.beep()
                }
            }
        }
    }
    
    // Show notification
    private func showNotification(for url: String) {
        if #available(macOS 10.14, *) {
            let center = UNUserNotificationCenter.current()
            let content = UNMutableNotificationContent()
            content.title = "Hyperlink"
            content.body = url
            
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            center.add(request)
        } else {
            let notification = NSUserNotification()
            notification.title = "Hyperlink"
            notification.informativeText = url
            NSUserNotificationCenter.default.deliver(notification)
        }
    }
    
    // Copy URL to clipboard with appropriate notification
    func copyURLToClipboard(_ url: String, playSound: Bool, showNotification: Bool) {
        // Format URL if needed
        let urlToCopy = url
        
        // Copy to clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(urlToCopy, forType: .string)

        if playSound {
            self.playSound()
        }
        if showNotification {
            self.showNotification(for: urlToCopy)
        }
        
        print("URL copied to clipboard: \(urlToCopy)")
    }
    
    // Save preferences
    func savePreferences() {
        UserDefaults.standard.set(notificationStyle.rawValue, forKey: "ClipboardNotificationStyle")
        UserDefaults.standard.set(selectedSoundName, forKey: "ClipboardSoundName")
    }
    
    // Load preferences
    func loadPreferences() {
        if let styleRawValue = UserDefaults.standard.object(forKey: "ClipboardNotificationStyle") as? Int,
           let style = ClipboardNotificationStyle(rawValue: styleRawValue) {
            notificationStyle = style
        }
        if let savedSound = UserDefaults.standard.string(forKey: "ClipboardSoundName") {
            selectedSoundName = savedSound
        }
    }
    
    // Initialize
    private init() {
        loadPreferences()
        loadSound()
    }
}
