# 🌌 Orb Flow

> A vaporwave-aesthetic arcade-puzzle game. Guide your energy orb through tactical gravity fields and security terminals by drawing physical guidance lines.

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

## ✨ Features

- **Tactical Draw-to-Start Mechanics**: Pacing focused on strategy—physics remain frozen until your first drawn line is completed.
- **Vaporwave Presentation**: Custom code-driven wireframe mountains, scrolling synthwave grid, and multi-layered neon sunset visuals.
- **Dynamic Gravity Wells**: Oscillating push/pull nodes that alter trajectory in real-time.
- **Arcade Juice & Feedback**: Dynamic camera screen-shake on high-velocity wall impacts, hazards, and goal clears.
- **Terminal Select**: Integrated level selection architecture across 6 unique security terminals.

---

## 🎮 Controls

| Action | Control (PC) |
| :--- | :--- |
| **Draw Guide Line** | Left-Click & Drag |
| **Pause Game** | `ESC` Key |
| **Quick Restart** | `R` Key |
| **Jump / Skip Level** | `1` - `6` / `N` Key *(Developer Cheats)* |

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
├── scenes/          # Main gameplay and UI scene files (.tscn)
├── scripts/         # Core GDScript controllers and logic
├── assets/          # Procedural shaders, audio, and visual elements
└── project.godot    # Godot project configuration

### How to Update it via Git Bash

1. Replace the contents of `README.md` in your project folder with the text above.
2. Run these commands in your Git Bash terminal to push the update:

```bash
git add README.md
git commit -m "docs: update README with Android APK download link"
git push origin main
