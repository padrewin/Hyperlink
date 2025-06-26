//
//  BrowserIconLoader.swift
//  Hyperlink
//
//  Created by padrewin on 26.02.2025.
//


import SwiftUI

struct BrowserIconLoader {
    // Use this to directly load an image from the asset catalog
    static func loadIconFromAsset(named imageName: String) -> NSImage? {
        let image = NSImage(named: imageName)
        return image
    }
    
    // Creates a SwiftUI Image from an NSImage if possible, otherwise uses fallback
    @ViewBuilder
    static func createBrowserIcon(for browser: String) -> some View {
        let logoName = browser.lowercased() + "-logo"
        
        if let nsImage = loadIconFromAsset(named: logoName) {
            Image(nsImage: nsImage)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
        } else {
            createFallbackIcon(for: browser)
        }
    }
    
    // Creates a fallback icon when image asset isn't available
    @ViewBuilder
    static func createFallbackIcon(for browser: String) -> some View {
        let color = browserColor(for: browser)
        
        ZStack {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 24, height: 24)
            
            if browser.lowercased() == "safari" {
                Image(systemName: "safari")
                    .font(.system(size: 12))
                    .foregroundColor(color)
            } else {
                Text(String(browser.prefix(1)))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(color)
            }
        }
    }
    
    // Color helper
    static func browserColor(for browser: String) -> Color {
        switch browser.lowercased() {
        case "safari": return .blue
        case "chrome": return .green
        case "firefox": return .orange
        case "edge": return Color(red: 0.0, green: 0.5, blue: 0.8)
        case "opera": return .red
        case "brave": return .orange
        case "arc": return .purple
        case "vivaldi": return .red
        case "zen": return .teal
        case "sigmaos": return .orange
        default: return .gray
        }
    }
}
