![GitHub Downloads (all assets, all releases)](https://img.shields.io/github/downloads/padrewin/Hyperlink/total?logo=files&logoColor=white&label=Downloads&color=green)
![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/padrewin/Hyperlink/xcode-build.yml?logo=GitHub&label=GitHub%20Build)

# Hyperlink

Hyperlink is a macOS menubar app that effortlessly grabs the URL from your active browser tab and copies it to your clipboard. With customizable behaviors, keyboard shortcuts, and a sleek preferences window, Hyperlink streamlines your workflow for quickly accessing web addresses.

<details>
  <summary>Image Gallery</summary>

https://github.com/user-attachments/assets/e94077d7-8b0b-453b-8c21-656d2c580738

![hyperlink-notification](https://github.com/user-attachments/assets/a76ce18f-da6f-4a6a-afe4-5473e14c6c61)
![hyperlink-settings](https://github.com/user-attachments/assets/67b42f55-3258-4c64-95fc-9999ad630687)
![hyperlink-browsers](https://github.com/user-attachments/assets/0e725d63-8d81-47a4-9ddf-9691218cfec9)
</details>

## Features

- **Menubar-Only App:**  
  Runs as a menubar app with no Dock icon, keeping your workspace clean and distraction-free.

- **URL Grabbing:**  
  Automatically detects your active browser (Safari, Chrome, Firefox, Opera, and more) and copies the current tab’s URL to your clipboard.

- **Customizable Copy Behavior:**  
  Choose from multiple behaviors when copying a URL:
  - **Show Notification:** A system notification appears with the copied URL.
  - **Silent Copy:** No visual feedback is shown.
  - **Play Sound:** A sound is played to indicate the URL was copied.

- **Keyboard Shortcuts:**  
  Record and use a custom keyboard shortcut to trigger URL grabbing. The app enforces a minimum combination of at least one modifier key (e.g. Command, Shift, etc.) to prevent accidental activations.
  - Recommending using `⇧⌘C`. (this is the default Arc's Copy URL shortcut, I got used to that lol)

- **Update Checker:**  
  Automatically checks for new releases on GitHub. If an update is available, Hyperlink notifies you and provides a link to download the latest version.

- **Debugging & Diagnostics:**  
  Enable debug logging and easily copy diagnostic information for troubleshooting.

- **Appearance Customization:**  
  Choose between multiple menubar icons (e.g. “EXTL” and “LINK”) from the Appearance settings. The selected icon updates in real-time in the menubar.

- **Clean & Modern UI:**  
  A preferences window with multiple tabs (General, Browsers, Shortcut, Advanced, Appearance) for a structured, easy-to-navigate configuration experience.

## Installation

### Build from Source

1. **Clone the Repository:**

   ```bash
   git clone https://github.com/padrewin/Hyperlink.git
   cd Hyperlink
