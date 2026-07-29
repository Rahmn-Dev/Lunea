# Lunea 
<img width="1920" height="1440" alt="565shots_so" src="https://github.com/user-attachments/assets/df31a621-3bc1-49f9-8d55-392e0d710af2" />

**Lunea** is a modern and elegant desktop YouTube client designed specifically for **macOS**. Built using **SwiftUI**, Lunea delivers a seamless browsing and viewing experience with a *Glassmorphism / visionOS* style interface, smooth gradient animations, and a comfortable split-screen layout designed for multitasking.

---
##  Key Features

-  **Dynamic Themes**: Stunning custom theme options (Midnight Red, Cyber Blue, Emerald Forest, and a clean desktop-style YouTube Light Mode).
-  **Desktop Split-Screen Player**: A modern playback layout featuring the video on the left and detailed information (Title, Channel, Like/Subscribe buttons, and Description) in a clean, scrollable right sidebar.
-  **Mini-Player / PiP (Picture-in-Picture)**: A floating mode that automatically snaps to the bottom-right corner, letting you keep watching while browsing other menus.
-  **Fast Search & Categories**: Instant video search and navigation through popular categories (Music, Gaming, Tech, News, etc.).
-  **Lightweight & Native**: High performance, responsive, and fully integrated with the macOS ecosystem using the official YouTube Data API v3.

---

##  Tech Stack

- **Language**: Swift
- **UI Framework**: SwiftUI (macOS App)
- **Networking**: URLSession, Combine, Async/Await
- **Video Engine**: WKWebView (YouTube Embed API)

---

##  System Requirements

- macOS (macOS Ventura or newer recommended)
- **Xcode** 15.0 or later
- **YouTube Data API v3 Key** (free to obtain via the [Google Cloud Console](https://console.cloud.google.com/))

---

##  Getting Started

1. **Clone or Open the Project**
   Open the **Lunea** project folder using **Xcode**.

2. **Configure the API Key**
   - On the first launch, a sheet/pop-up will appear to enter your **YouTube API Key**.
   - Alternatively, configure it directly inside `YouTubeService.swift`:
     ```swift
     static var apiKey: String = "YOUR_API_KEY_HERE"
     ```

3. **Build & Run**
   - Press **`Cmd + R`** in Xcode to build and run the app on your Mac.

---

## <img width="1920" height="1440" alt="512shots_so" src="https://github.com/user-attachments/assets/148c7c23-76f7-4536-9dcf-87264ed74f34" />
## <img width="1920" height="1080" alt="81_1x_shots_so" src="https://github.com/user-attachments/assets/4798481d-dfa8-4333-b865-b3c28afb9671" />
##
 Project Structure

```text
Lunea/
│
├── ContentView.swift        # Root layout, tab navigation, and main window structure
├── SidebarView.swift        # Left navigation sidebar, window controls, & theme picker
├── PlayerView.swift         # WKWebView Player, Mini-Player, & Split-Screen Details
├── VideoView.swift          # Video cards (VideoCard, HeroFeaturedCard, SearchResultCard)
└── YouTubeService.swift     # API Service, YouTube data models, & AppState (ViewModel)
