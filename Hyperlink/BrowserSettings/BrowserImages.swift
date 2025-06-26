import SwiftUI

struct BrowserImages {
    // Generic browser logo creator
    @ViewBuilder
    static func logoFor(_ browser: String) -> some View {
        let name = browser.lowercased()
        let color: Color = colorFor(browser)
        
        switch name {
        case "safari":
            Image(systemName: "safari")
                .font(.system(size: 16))
                .foregroundColor(.blue)
            
        case "chrome":
            Circle()
                .fill(Color.green)
                .frame(width: 20, height: 20)
            
        case "firefox":
            Image(systemName: "flame.fill")
                .font(.system(size: 16))
                .foregroundColor(.orange)
            
        case "edge":
            Text("E")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.blue)
                .frame(width: 20, height: 20)
                .background(Circle().fill(Color.blue.opacity(0.2)))
            
        case "brave":
            Text("B")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.orange)
                .frame(width: 20, height: 20)
                .background(Circle().fill(Color.orange.opacity(0.2)))
            
        case "opera":
            Text("O")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.red)
                .frame(width: 20, height: 20)
                .background(Circle().fill(Color.red.opacity(0.2)))
            
        case "arc":
            Text("A")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.purple)
                .frame(width: 20, height: 20)
                .background(Circle().fill(Color.purple.opacity(0.2)))
            
        case "vivaldi":
            Text("V")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.red)
                .frame(width: 20, height: 20)
                .background(Circle().fill(Color.red.opacity(0.2)))
            
        case "zen":
            Text("Z")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.teal)
                .frame(width: 20, height: 20)
                .background(Circle().fill(Color.teal.opacity(0.2)))
            
        case "sigmaos":
            if let image = NSImage(named: "sigmaos-logo") {
                Image(nsImage: image)
                    .resizable()
                    .frame(width: 20, height: 20)
            } else {
                Text("S")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.gray)
                    .frame(width: 20, height: 20)
                    .background(Circle().fill(Color.gray.opacity(0.2)))
            }
            
        default:
            Text(String(browser.prefix(1)))
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(color)
                .frame(width: 20, height: 20)
                .background(Circle().fill(color.opacity(0.2)))
        }
    }
    
    // Helper to get a color for a browser
    static func colorFor(_ browser: String) -> Color {
        let name = browser.lowercased()
        switch name {
        case "safari": return .blue
        case "chrome": return .green
        case "firefox": return .orange
        case "edge": return Color(red: 0.0, green: 0.5, blue: 0.8)
        case "opera": return .red
        case "brave": return .orange
        case "arc": return .purple
        case "vivaldi": return .red
        case "zen": return .teal
        case "sigmaos": return .gray
        default: return .gray
        }
    }
}

// Define browser icon views for each supported browser
struct SafariIcon: View {
    var body: some View {
        Image(systemName: "safari")
            .font(.system(size: 18))
            .foregroundColor(.blue)
    }
}

struct ChromeIcon: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.green)
                .frame(width: 20, height: 20)
        }
    }
}

struct FirefoxIcon: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.orange.opacity(0.2))
                .frame(width: 20, height: 20)
            Image(systemName: "flame.fill")
                .font(.system(size: 12))
                .foregroundColor(.orange)
        }
    }
}

struct EdgeIcon: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 20, height: 20)
            Text("E")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.blue)
        }
    }
}

struct OperaIcon: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.red.opacity(0.2))
                .frame(width: 20, height: 20)
            Text("O")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.red)
        }
    }
}

struct BraveIcon: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.orange.opacity(0.2))
                .frame(width: 20, height: 20)
            Text("B")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.orange)
        }
    }
}

struct ArcIcon: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.purple.opacity(0.2))
                .frame(width: 20, height: 20)
            Text("A")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.purple)
        }
    }
}

struct VivaldiIcon: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.red.opacity(0.2))
                .frame(width: 20, height: 20)
            Text("V")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.red)
        }
    }
}

struct ZenIcon: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.teal.opacity(0.2))
                .frame(width: 20, height: 20)
            Text("Z")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.teal)
        }
    }
}
