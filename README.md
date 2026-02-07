<div align="center">

<!-- App Logo -->
<img src="assets/logo.png" alt="Tory Logo" width="200" height="200">


### *The Intelligent Torrent Discovery Engine*

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg?cacheSeconds=2592000)
![Flutter](https://img.shields.io/badge/Flutter_3.8-02569B?style=flat&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart_3.8-0175C2?style=flat&logo=dart&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-43853D?style=flat&logo=node.js&logoColor=white)
![Shorebird](https://img.shields.io/badge/Shorebird-OTA_Updates-blue?style=flat)
[![Backend](https://img.shields.io/badge/Backend-tory--server-orange?style=flat)](https://github.com/nirmaleeswar30/tory-server)
![License](https://img.shields.io/badge/license-MIT-green.svg)

*One tap. Best torrent. Every time.*

[🚀 Quick Start](#-quick-start) • [📱 Features](#-features) • [🏗️ Architecture](#️-architecture) • [⚙️ Configuration](#️-configuration)

</div>

---

## 🌟 Overview

Tory is an intelligent torrent discovery app built with Flutter. It aggregates results from **17+ torrent indexers** via its own [tory-server](https://github.com/nirmaleeswar30/tory-server) backend, scores them using a multi-factor algorithm, and surfaces the best results through a polished dark UI. Discover movies via **TMDB**, anime via **AniList + Jikan**, and browse episodes with full season/episode pickers — all with one tap to magnet link.

## 📱 Features

### 🔍 Intelligent Search Engine
- **17 Torrent Sources** — 1337x, YTS, NyaaSi, PirateBay, TorrentGalaxy, EZTV, RARBG, KickAss, and more
- **Multi-Factor Scoring** — Seeders (40%), S/L ratio (25%), file size (15%), recency (10%), source reliability (10%)
- **SubsPlease / Erai-raws Bonus** — +5 score for known quality anime release groups
- **Dual Search** — Runs two query formats in parallel (scene S01E02 + SubsPlease style), merges & deduplicates results

### 🎬 Media Discovery
- **TMDB Integration** — Trending, popular, and top-rated movies & TV shows with poster art
- **AniList Integration** — Trending, popular, and latest airing anime via GraphQL API
- **Jikan / MAL** — Episode details with thumbnails, titles, air dates, scores, filler/recap tags
- **Season & Episode Pickers** — Two-step UI: bottom sheet with episode range cards → full-screen episode browser

### 🎌 Anime-Optimized Search
- **Season Extraction** — Detects season numbers from titles ("2nd Season", "Part 3", Roman numerals)
- **Short Title Detection** — Strips subtitles after colons for SubsPlease-style queries
- **Smart Query Format** — S1: `Title - 03`, S2+: `Title S2 - 03` (matching real fansub naming)

### 🎨 UI / UX
- **Deep Navy Dark Theme** — Custom `AppTheme` with crimson accents throughout
- **Shimmer Loading** — Skeleton placeholders while content loads
- **Score Badges** — Color-coded quality indicators on every torrent card
- **Source Chips** — Quick-switch between indexers with emoji icons
- **Sort Filters** — Best Match, Most Seeders, Smallest, Newest, Largest, Latest
- **Scroll-to-Top** — Auto-scrolls when switching sort modes

### 🔄 OTA Updates (Shorebird)
- **Code Push** — Hot-patch the app without a store release
- **Patch Version Display** — About screen shows current patch number
- **Bundletool Script** — Included `build_universal_apk.ps1` to convert AAB → APK

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Flutter App (Dart)                       │
│                                                                 │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌───────────────┐  │
│  │  Home     │  │  Search  │  │ Episodes │  │   Settings    │  │
│  │  Screen   │  │  Screen  │  │  Screen  │  │   Screen      │  │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └───────────────┘  │
│       │              │              │                            │
│  ┌────┴──────────────┴──────────────┴────┐                     │
│  │           Provider (State Mgmt)       │                     │
│  │  SearchProvider · SettingsProvider     │                     │
│  └────┬──────────────┬──────────────┬────┘                     │
│       │              │              │                            │
│  ┌────┴────┐   ┌─────┴────┐  ┌─────┴──────┐                   │
│  │ API     │   │  TMDB    │  │  AniList   │                    │
│  │ Service │   │  Service │  │  Service   │                    │
│  └────┬────┘   └─────┬────┘  └─────┬──────┘                   │
└───────┼──────────────┼──────────────┼──────────────────────────┘
        │              │              │
        ▼              ▼              ▼
  ┌──────────┐  ┌───────────┐  ┌──────────────┐  ┌────────────┐
  │tory-     │  │ TMDB API  │  │AniList GQL   │  │ Jikan API  │
  │server    │  │   v3      │  │              │  │  (MAL)     │
  │:8080     │  │           │  │              │  │            │
  └──────────┘  └───────────┘  └──────────────┘  └────────────┘
```

### Project Structure
```
tory/
├── lib/
│   ├── main.dart                    # Entry point
│   ├── app.dart                     # MaterialApp setup
│   ├── core/
│   │   ├── constants.dart           # Sources, API keys, categories
│   │   └── theme.dart               # AppTheme (deep navy + crimson)
│   ├── models/
│   │   ├── torrent.dart             # Torrent data model + scoring
│   │   ├── tmdb_media.dart          # TMDB movie/TV model
│   │   └── anilist_media.dart       # AniList model + season extraction
│   ├── services/
│   │   ├── api_service.dart         # Torrents-Api HTTP client
│   │   ├── tmdb_service.dart        # TMDB API v3
│   │   ├── anilist_service.dart     # AniList GraphQL
│   │   └── storage_service.dart     # SharedPreferences wrapper
│   ├── providers/
│   │   ├── search_provider.dart     # Search state + dual-search + sorting
│   │   └── settings_provider.dart   # API URL, TMDB key, default source
│   ├── screens/
│   │   ├── splash_screen.dart       # Animated splash
│   │   ├── home_screen.dart         # TMDB + AniList discovery sections
│   │   ├── search_screen.dart       # Search UI with source/sort chips
│   │   ├── episode_screen.dart      # TMDB episode browser
│   │   ├── anime_episode_screen.dart# Anime episode browser (Jikan)
│   │   ├── favorites_screen.dart    # Saved items
│   │   └── settings_screen.dart     # Config + About (version/patch)
│   └── widgets/
│       ├── torrent_card.dart        # Torrent result card
│       ├── torrent_detail_sheet.dart # Bottom sheet details
│       ├── media_card.dart          # TMDB media card
│       ├── anime_card.dart          # AniList anime card
│       ├── episode_picker_sheet.dart # TMDB season picker sheet
│       ├── anime_episode_sheet.dart # Anime episode range sheet
│       ├── score_badge.dart         # Color-coded score indicator
│       ├── source_chip.dart         # Source selector chip
│       └── shimmer_loader.dart      # Skeleton loading effect
├── assets/
│   └── logo.png
├── shorebird.yaml                   # Shorebird app config
├── build_universal_apk.ps1          # AAB → universal APK script
└── pubspec.yaml
```

## 🚀 Quick Start

### Prerequisites
- **Flutter SDK** 3.8+
- **Node.js** (LTS) for the backend
- **Shorebird CLI** (optional, for OTA updates)
- **TMDB API Key** — [get one here](https://www.themoviedb.org/settings/api)

### 1. Backend Setup

```bash
# Clone and start the tory-server backend
git clone https://github.com/nirmaleeswar30/tory-server.git
cd tory-server
npm install
npm start
# Runs on http://localhost:8080
```

### 2. Flutter App Setup

```bash
cd Tory
flutter pub get
flutter run
```

### 3. Configure in App
Open **Settings** in the app to set:
- **API Base URL** — defaults to `https://tory-server.vercel.app` (or set your own)
- **TMDB API Key** — your v3 API key
- **Default Source** — preferred torrent indexer

## ⚙️ Configuration

### Torrent Sources (17)

| Source | Emoji | Reliability | Best For |
|--------|-------|-------------|----------|
| YTS | 🎬 | 95% | Movies (small size) |
| 1337x | 🔥 | 90% | Everything |
| NyaaSi | 🎌 | 90% | Anime |
| RARBG | ⚡ | 90% | Movies & TV |
| TorrentGalaxy | 🌌 | 85% | General |
| EZTV | 📺 | 85% | TV Shows |
| PirateBay | 🏴‍☠️ | 80% | General |
| KickAss | 💥 | 75% | General |
| BitSearch | 🔎 | 75% | General |
| ETTV | 📡 | 75% | TV |
| Torlock | 🔒 | 70% | General |
| Zooqle | 🔍 | 70% | General |
| GloTorrents | 🌍 | 70% | General |
| MagnetDL | 🧲 | 70% | General |
| TorrentProject | 📋 | 70% | General |
| LimeTorrent | 🍋 | 65% | General |
| TorrentFunk | 🎵 | 65% | General |

### Scoring Algorithm
```
Score = Seeders (40%) + S/L Ratio (25%) + Size (15%) + Recency (10%) + Source (10%)
       + SubsPlease/Erai-raws bonus (+5)
```

### API Endpoints
| Service | URL | Purpose |
|---------|-----|---------|
| tory-server | `https://tory-server.vercel.app/api/{source}/{query}` | Torrent search |
| TMDB | `https://api.themoviedb.org/3/` | Movie & TV metadata |
| AniList | `https://graphql.anilist.co` | Anime discovery |
| Jikan | `https://api.jikan.moe/v4/` | Episode details (MAL) |

## 🔄 Shorebird OTA Updates

```bash
# Create a release
shorebird release android

# Convert AAB to universal APK
.\build_universal_apk.ps1

# Push a patch (after code changes)
shorebird patch android
```

Patch number is displayed in **Settings → About**.

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| UI | Flutter 3.8 / Dart 3.8 |
| State | Provider |
| Storage | SharedPreferences |
| OTA | Shorebird Code Push |
| Backend | Node.js ([tory-server](https://github.com/nirmaleeswar30/tory-server)) |
| Movie Data | TMDB API v3 |
| Anime Data | AniList GraphQL + Jikan v4 |

## ⚠️ Disclaimer

**Educational Purpose Only.** This project is intended for educational and research purposes. Users are responsible for complying with all applicable laws and regulations in their jurisdiction. The developers do not endorse or encourage the downloading of copyrighted material without proper authorization.

---

<div align="center">

**Built with ❤️ using Flutter & Dart**

</div>