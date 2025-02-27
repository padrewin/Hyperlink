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
    var shouldFormatURLs: Bool = false
    
    // Audio player for sound notifications
    private var audioPlayer: AVAudioPlayer?
    
    // Load sound file
    private func loadSound() {
        guard audioPlayer == nil else { return }
        
        // Try to find the sound file in the bundle
        if let soundURL = Bundle.main.url(forResource: "copy-sound", withExtension: "mp3") {
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
    private func playSound() {
        loadSound()
        
        if let player = audioPlayer {
            player.currentTime = 0
            player.play()
        } else {
            // Fallback to system sound
            NSSound.beep()
        }
    }
    
    // Show notification
    private func showNotification(for url: String) {
        if #available(macOS 10.14, *) {
            let center = UNUserNotificationCenter.current()
            let content = UNMutableNotificationContent()
            content.title = "URL Copied"
            content.body = url
            
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            center.add(request)
        } else {
            let notification = NSUserNotification()
            notification.title = "URL Copied"
            notification.informativeText = url
            NSUserNotificationCenter.default.deliver(notification)
        }
    }
    
    // Format URL if needed
    private func formatURL(_ url: String) -> String {
        if shouldFormatURLs {
            // Remove protocol if present
            var formattedURL = url
            let protocols = ["https://", "http://", "ftp://", "file://"]
            for prefix in protocols {
                if formattedURL.hasPrefix(prefix) {
                    formattedURL = String(formattedURL.dropFirst(prefix.count))
                    break
                }
            }
            
            // Remove trailing slash
            if formattedURL.hasSuffix("/") {
                formattedURL = String(formattedURL.dropLast())
            }
            
            // Remove www. prefix
            if formattedURL.hasPrefix("www.") {
                formattedURL = String(formattedURL.dropFirst(4))
            }
            
            return formattedURL
        } else {
            return url
        }
    }
    
    // Copy URL to clipboard with appropriate notification
    func copyURLToClipboard(_ url: String) {
        // Format URL if needed
        let urlToCopy = formatURL(url)
        
        // Copy to clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(urlToCopy, forType: .string)
        
        // Notify based on style
        switch notificationStyle {
        case .showNotification:
            showNotification(for: urlToCopy)
        case .silent:
            // Do nothing
            break
        case .playSound:
            playSound()
        case .soundAndNotification:
            playSound()
            showNotification(for: urlToCopy)
        }
        
        print("URL copied to clipboard: \(urlToCopy)")
    }
    
    // Save preferences
    func savePreferences() {
        UserDefaults.standard.set(notificationStyle.rawValue, forKey: "ClipboardNotificationStyle")
        UserDefaults.standard.set(shouldFormatURLs, forKey: "ClipboardFormatURLs")
    }
    
    // Load preferences
    func loadPreferences() {
        if let styleRawValue = UserDefaults.standard.object(forKey: "ClipboardNotificationStyle") as? Int,
           let style = ClipboardNotificationStyle(rawValue: styleRawValue) {
            notificationStyle = style
        }
        
        shouldFormatURLs = UserDefaults.standard.bool(forKey: "ClipboardFormatURLs")
    }
    
    // Initialize
    private init() {
        loadPreferences()
        loadSound()
    }
}