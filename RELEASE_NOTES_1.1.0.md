# Lunea v1.1.0

Lunea's first major interface update brings a faster, more polished way to discover and watch YouTube on macOS.

## What's new

- A completely redesigned, responsive Home experience with a cinematic hero carousel, Quick Picks, category filters, and a consistent three-column recommendation grid.
- A refined video player with persistent playback and mini-player support, so a video can continue while you browse.
- A modern Search experience with filters, pagination, caching, and clearer handling when YouTube rate-limits requests.
- Lightweight animated gradient themes and smoother scrolling throughout the app.
- US-focused Home recommendations and English interface copy.
- A premium Lunea identity across the title bar and navigation.
- Safer YouTube API key storage in the macOS Keychain.
- Numerous fixes for window resizing, overlapping content, hover states, carousel controls, and loading additional results.

## Requirements

- macOS 26.5 or later
- Apple Silicon Mac
- A YouTube Data API v3 key (entered on first launch)

## Installation

Open the DMG, drag **Lunea** into **Applications**, then launch it from the Applications folder.

This build is not notarized. On first launch, macOS may require you to Control-click **Lunea**, choose **Open**, and confirm.

## YouTube quota note

YouTube Data API search requests use significantly more quota than ordinary video-list requests. Lunea caches searches and avoids repeated automatic retries, but the daily quota still belongs to the configured Google Cloud project.
