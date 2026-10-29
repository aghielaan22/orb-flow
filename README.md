# 🌌 Orb Flow

> A programmatic, asset-free cyberpunk/vaporwave arcade experience. Guide your energy orb through tactical physics-puzzles and high-octane retro space shooter terminals.

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

- **Dual-Mode Arcade Action**: Seamlessly transition between tactical physics puzzle drawing and traditional retro arcade space shooter stages (`space_shooter.gd`).
- **Mobile-First Virtual Arcade Controls**: Ergonomic, static touch-screen UI buttons for Left/Right steering and a dedicated Fire action, optimized specifically for mobile hardware.
- **Defense Red Line Mechanics**: Protect your base against incoming enemy ships and hazards crossing the critical defense threshold, tracking escaped units dynamically.
- **Programmatic Vaporwave Aesthetics**: Fully code-driven wireframe matrix background effects, scrolling synthwave grid lines, and vector neon graphics with zero external image asset dependencies.
- **High-Impact Polish**: Reactive visual feedback including procedural hit-spark particle explosions (`spawn_hit_spark`) for destroyed enemies, hazards, and player ships.

---

## 🎮 Controls

| Action | PC Control | Mobile Control |
| :--- | :--- | :--- |
| **Steer Left / Right** | `A` / `D` or Arrow Keys | On-Screen `◄` / `►` Buttons |
| **Fire Projectile** | `Spacebar` | On-Screen `FIRE` Button |
| **Pause Game** | `ESC` or `P` Key | Top-Right Pause (`❚❚`) Button |
| **Quick Restart** | `R` Key | Pause Menu / Game Over Overlay |
| **Level Skip / Cheat** | `N` Key | N/A |

---

## 🛠️ Getting Started

### Prerequisites
- [Godot Engine 4.x](https://godotengine.org/) installed on your machine.

### Running Locally
1. Clone the repository:
   ```bash
   git clone [https://github.com/aghielaan22/orb-flow.git](https://github.com/aghielaan22/orb-flow.git)

2. Open Godot Engine, click Import, and select the project.godot file from your cloned directory.

3. Press F5 (or click the Play button) to run the project.

orb-flow/
├── scenes/          # Main gameplay, shooter, and UI scene files (.tscn)
├── scripts/         # Core GDScript controllers (space_shooter.gd, main.gd, etc.)
├── assets/          # Procedural shaders and custom audio streams
└── project.godot    # Godot project configuration
