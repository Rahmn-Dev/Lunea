<p align="center">
  <img
    width="128"
    height="128"
    alt="Lunea App Icon"
    src="https://github.com/user-attachments/assets/01f824c7-38f4-4254-9fe4-fc49e05fad01"
  />
</p>

<h1 align="center">Lunea</h1>

<p align="center">
  <strong>A modern YouTube client, designed natively for macOS.</strong>
</p>

<p align="center">
  Browse, discover, and watch YouTube through a focused desktop experience built with SwiftUI.
</p>

<p align="center">
  <a href="https://dribbble.com/shots/27609236-Lunea-Modern-macOS-YouTube-Client">
    View on Dribbble
  </a>
</p>

<br>

<p align="center">
<img width="1920" height="1440" alt="lunea" src="https://github.com/user-attachments/assets/60671f8c-fc84-4eb6-9d4c-403d093ef914" />

</p>

## Overview

**Lunea** is a native macOS YouTube client built with **Swift** and **SwiftUI**.

It reimagines the YouTube desktop experience around a dedicated macOS interface, combining video discovery, search, playback, customizable themes, and multitasking features in a focused desktop application.

## Highlights

- **Native macOS Experience** — Built with Swift and SwiftUI specifically for macOS.
- **Split-Screen Player** — Watch videos while keeping the title, channel, description, and other video information accessible alongside the player.
- **Mini Player** — Continue watching in a compact floating player while browsing other content.
- **Dynamic Themes** — Switch between Midnight Red, Cyber Blue, Emerald Forest, and Light themes.
- **Search & Categories** — Search videos and browse categories including Music, Gaming, Tech, and News.
- **YouTube Integration** — Video discovery and metadata powered by YouTube Data API v3.
- **Embedded Playback** — Video playback through YouTube's embedded player using WKWebView.

<br>

<p align="center">
<img width="1920" height="1080" alt="257_1x_shots_so" src="https://github.com/user-attachments/assets/0edc2fb9-af4b-44a6-b1bc-e6e8fe4ed687" />

</p>

## Tech Stack

| | Technology |
|---|---|
| **Language** | Swift |
| **UI** | SwiftUI |
| **Networking** | URLSession |
| **Concurrency** | Combine, Swift Concurrency / async-await |
| **Video** | WKWebView + YouTube Embed |
| **Data** | YouTube Data API v3 |

## Getting Started

### Requirements

- macOS Ventura or newer
- Xcode 15.0+
- YouTube Data API v3 key

### 1. Clone the Repository

```bash
git clone YOUR_REPOSITORY_URL
cd Lunea
```

Open the project in **Xcode**.

### 2. Configure the API Key

On first launch, Lunea provides a configuration interface for entering your **YouTube Data API v3 key**.

Alternatively, configure it in `YouTubeService.swift`:

```swift
static var apiKey: String = "YOUR_API_KEY_HERE"
```

> Keep API keys private and never commit personal credentials to the repository.

### 3. Build & Run

Select the Lunea scheme in Xcode and press:

```text
⌘ R
```

## Project Structure

```text
Lunea/
│
├── ContentView.swift
│   └── Root layout, navigation, and main window
│
├── SidebarView.swift
│   └── Sidebar navigation, window controls, and themes
│
├── PlayerView.swift
│   └── WKWebView player, mini player, and video details
│
├── VideoView.swift
│   └── Video cards, featured content, and search results
│
└── YouTubeService.swift
    └── YouTube API client, data models, and application state
```

## Design

Lunea explores a translucent, layered interface designed around desktop viewing and multitasking on macOS.

<p align="center">
  <a href="https://dribbble.com/shots/27609236-Lunea-Modern-macOS-YouTube-Client">
    <strong>View Lunea on Dribbble →</strong>
  </a>
</p>
