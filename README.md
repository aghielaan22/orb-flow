# 🌌 Orb Flow

> A programmatic, asset-free cyberpunk/vaporwave arcade experience. Guide your energy orb through tactical physics-puzzles, retro space shooter terminals, twisted security hangmans, neon color switches, and laser grid circuit breakers.

![Godot Engine](https://img.shields.io/badge/Engine-Godot%204.x-blue?style=flat-square&logo=godotengine)
![Platform](https://img.shields.io/badge/Platform-PC%20%2F%20Android-lightgrey?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)

---

## 📱 Quick Play (Android APK)

Want to play immediately on your mobile device? 

1. Go to the **[Releases Section](https://github.com/aghielaan22/orb-flow/releases)** on this repository.
2. Download the latest `.apk` release build.
3. Open the downloaded file on your Android device to install and play!

---

## ✨ Features & Highlights

- **Multi-Mode Arcade & Terminal Action**: Seamlessly transition between tactical physics puzzle drawing (`main.gd`), retro arcade space shooter defense lines (`space_shooter.gd`), Cyber Hangman time-bomb decryption matrices (`cyber_hangman.gd`), Neon Color Switches (`neon_color_switch.gd`), and Data Unblock sliding puzzle terminals (`unblock_puzzle_game.gd`).

- **Mobile-First Virtual Arcade Controls**: Ergonomic, static touch-screen UI buttons, horizontal thumb steering sliders, and custom action layouts optimized specifically for mobile hardware.

- **Dynamic Terminal Routing**: Fully integrated navigation across all 10 mainframe terminals with dedicated level intro popups, score synchronization (`ScoreManager`), and persistent high-score leaderboards.

- **Programmatic Vaporwave Aesthetics**: Fully code-driven wireframe matrix background effects, scrolling synthwave grid lines, and vector neon graphics (`Line2D`) with zero external image asset dependencies.

- **High-Impact Polish**: Reactive visual feedback including procedural hit-spark particle explosions, screen shake/flash mechanics, generous ink juice meters, and dynamic audio feedback via procedural audio stream generators.

---

## 🎮 Controls

| Action | PC Control | Mobile Control |
| :--- | :--- | :--- |
| **Steer / Move / Type** | `A` / `D`, Arrow Keys, or Keyboard | On-Screen Virtual Buttons / Horizontal Thumb Slider |
| **Fire / Confirm / Hint** | `Spacebar` / Mouse Clicks | On-Screen Action Buttons (`FIRE`) |
| **Pause Game** | `ESC` or `P` Key | Top-Right Pause (`❚❚`) Button |
| **Quick Restart** | `R` Key | Pause Menu / Game Over Overlay |
| **Level Skip / Cheat** | `1`-`10` Keys, `N` Key | Terminal Selector / Dev Panel |

---

## 🛠️ Getting Started

### Prerequisites
- [Godot Engine 4.x](https://godotengine.org/) installed on your machine.

### Running Locally
1. Clone the repository:
   ```bash
   git clone [https://github.com/aghielaan22/orb-flow.git](https://github.com/aghielaan22/orb-flow.git)
   
2. Open Godot Engine, click Import, and select the project.godot file from your cloned directory.

3.Press F5 (or click the Play button) to run the project.

orb-flow/
├── scenes/          # Main gameplay, shooter, and UI scene files (.tscn)
├── scripts/         # Core GDScript controllers (space_shooter.gd, main.gd, hangman.gd, etc.)
├── assets/          # Procedural shaders and custom audio streams
└── project.godot    # Godot project configuration
