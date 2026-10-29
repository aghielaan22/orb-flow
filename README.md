# 🌌 Orb Flow

> A programmatic, asset-free cyberpunk/vaporwave dual-mode arcade experience. Guide your energy orb through tactical physics-puzzles and high-octane space shooter terminals.

![Godot Engine](https://img.shields.io/badge/Engine-Godot%204.x-blue?style=flat-square&logo=godotengine)
![Platform](https://img.shields.io/badge/Platform-PC%20%2F%20Android-lightgrey?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)

---

## 📱 Quick Play (Android APK)

Want to play immediately on your mobile device? 

1. Go to the **[Releases Section](https://github.com/aghielaan22/orb-flow/releases)** on this repository.
2. Download the latest `orb-flow-v1.0.0.apk`.
3. Open the downloaded file on your Android device to install and play!

---

## ✨ Features & Highlights

- **Dual-Mode Arcade Action**: Seamlessly switch between tactical physics puzzle drawing and arcade space shooter combat.
- **Programmatic Vaporwave Aesthetics**: Fully code-driven wireframe mountains, scrolling synthwave grid floors, vector neon graphics, and procedurally generated suns with zero external image asset dependencies.
- **Dynamic Moving Hazards**: Real-time code-driven obstacle spawning and sweep patterns that test precision timing and reflexes.
- **Tactile Screen Polish**: High-impact procedural screen-flash overlays and reactive visual feedback for star collection, hazard impacts, and level victories.
- **Procedural Sound Engine (`play_cyber_sfx`)**: Built-in algorithmic sine-wave audio generator delivering custom, crisp sound profiles for UI clicks, line drawing, physics bounces, and danger warnings.
- **Persistent Local Leaderboard (`leaderboard.gd`)**: Functional high-score tracker featuring secure local file storage, dynamic score sorting, and cyberpunk terminal UI styling styled for Huawei Game Service integration.

---

## 🎮 Controls

| Action | Control (PC) |
| :--- | :--- |
| **Draw Guide Line / Interact** | Left-Click & Drag |
| **Pause Game** | `ESC` Key |
| **Quick Restart** | `R` Key |
| **Developer Cheats / Level Skip** | `1` - `6` / `N` Key |

---

## 🛠️ Getting Started

### Prerequisites
- [Godot Engine 4.x](https://godotengine.org/) installed on your machine.

### Running Locally
1. Clone the repository:
   ```bash
   git clone [https://github.com/aghielaan22/orb-flow.git](https://github.com/aghielaan22/orb-flow.git)

2. Open Godot Engine, click Import, and select the project.godot file from the cloned directory.

3. Press F5 (or click the Play button) to run the project.

orb-flow/
├── scenes/          # Main gameplay, shooter, and UI scene files (.tscn)
├── scripts/         # Core GDScript controllers (main.gd, leaderboard.gd, etc.)
├── assets/          # Procedural shaders, audio streams, and visual themes
└── project.godot    # Godot project configuration

---

### How to push this update to GitHub:
1. Replace the entire content of your local `README.md` file with the code block above and save it.
2. Run these commands in your Git Bash terminal:
   ```bash
   git add README.md
   git commit -m "docs: update README with dual-mode features, polish, and leaderboard info"
   git push origin main
