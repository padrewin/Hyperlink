//
//  UpdateChecker.swift
//  Hyperlink
//
//  Created by padrewin on 26.02.2025.
//


import Foundation
import SwiftUI

class UpdateChecker: ObservableObject {
    @Published var isCheckingForUpdates = false
    @Published var latestVersion: String?
    @Published var updateAvailable = false
    @Published var updateURL: URL?
    @Published var errorMessage: String?
    
    private let repoOwner = "padrewin"
    private let repoName = "Hyperlink"
    private let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"

    func checkForUpdates(completion: ((Bool, String?) -> Void)? = nil) {
        isCheckingForUpdates = true
        errorMessage = nil
        
        print("Checking for updates... Current version: \(currentVersion)")
        
        let urlString = "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases/latest"
        guard let url = URL(string: urlString) else {
            handleError("Invalid URL")
            completion?(false, "Invalid URL")
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isCheckingForUpdates = false
                
                if let error = error {
                    self.handleError("Network error: \(error.localizedDescription)")
                    completion?(false, "Network error: \(error.localizedDescription)")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    self.handleError("Server error")
                    completion?(false, "Server error")
                    return
                }
                
                guard let data = data else {
                    self.handleError("No data received")
                    completion?(false, "No data received")
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let tagName = json["tag_name"] as? String,
                       let htmlURL = json["html_url"] as? String,
                       let url = URL(string: htmlURL) {
                        
                        // Remove 'v' prefix if present
                        let versionString = tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName
                        self.latestVersion = versionString
                        self.updateURL = url
                        
                        if self.compareVersions(self.currentVersion, versionString) {
                            self.updateAvailable = true
                            completion?(true, versionString)
                        } else {
                            self.updateAvailable = false
                            completion?(false, nil)
                        }
                    } else {
                        self.handleError("Invalid response format")
                        completion?(false, "Invalid response format")
                    }
                } catch {
                    self.handleError("JSON parsing error: \(error.localizedDescription)")
                    completion?(false, "JSON parsing error: \(error.localizedDescription)")
                }
            }
        }
        
        task.resume()
    }
    
    private func compareVersions(_ currentVersion: String, _ latestVersion: String) -> Bool {
        let currentComponents = currentVersion.split(separator: ".").compactMap { Int($0) }
        let latestComponents = latestVersion.split(separator: ".").compactMap { Int($0) }
        
        // Ensure we have at least 3 components (major.minor.patch)
        let currentPadded = currentComponents + Array(repeating: 0, count: max(0, 3 - currentComponents.count))
        let latestPadded = latestComponents + Array(repeating: 0, count: max(0, 3 - latestComponents.count))
        
        // Compare version components
        for i in 0..<min(currentPadded.count, latestPadded.count) {
            if latestPadded[i] > currentPadded[i] {
                return true
            } else if latestPadded[i] < currentPadded[i] {
                return false
            }
        }
        
        // If all shared components are equal, check if latest has more components
        return latestPadded.count > currentPadded.count
    }
    
    private func handleError(_ message: String) {
        errorMessage = message
        print("Update check error: \(message)")
    }
    
    func openUpdateURL() {
        if let url = updateURL {
            NSWorkspace.shared.open(url)
        }
    }
}

struct UpdateAvailableView: View {
    let currentVersion: String
    let latestVersion: String
    let onUpdate: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "arrow.down.app")
                .font(.system(size: 32))
                .foregroundColor(.blue)
            
            Text("Update Available")
                .font(.headline)
            
            Text("A new version of Hyperlink is available")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Text("Current version: \(currentVersion)")
                Spacer()
                Text("Latest version: \(latestVersion)")
            }
            .font(.caption)
            .padding(.horizontal)
            
            HStack(spacing: 20) {
                Button("Later") {
                    onDismiss()
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Button("Update Now") {
                    onUpdate()
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(.top, 10)
        }
        .padding()
        .frame(width: 300)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 10)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.1))
            .foregroundColor(.primary)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}
