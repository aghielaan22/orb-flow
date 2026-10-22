# 🌌 ORB FLOW // Vaporwave Gravity Puzzle

> A high-fidelity cyberpunk/vaporwave arcade-puzzle game developed for the **UMPSA x HUAWEI Competition**. Draw lines to guide an energy orb through pulsating gravity fields, hazardous zones, and complex security terminals.

---

## ✨ Key Features & Technical Highlights

* **Procedural Vaporwave Visuals**: Fully dynamic, code-driven visual presentation featuring wireframe background mountains, a classic synthwave grid with scrolling motion, and a multi-layered neon sunset.
* **Tactical Draw-to-Start Mechanics**: Pacing designed for deep puzzle-solving. The physics simulation remains frozen until the player completes and releases their first drawn line, allowing for calculated planning.
* **Pulsating Gravity Wells**: Dynamic nodes that rhythmically oscillate between push and pull forces, accompanied by real-time visual state indicators and scaling rings.
* **Screen-Shake & Impact Juice**: Implemented a global camera-shake system triggered by high-velocity wall bounces, hazard impacts, and terminal victories.
* **Terminal Select System**: A fully integrated level-selection menu allowing players to directly access any of the 6 core tactical terminals.
* **Procedural Audio Synthesis**: Lightweight, on-the-fly audio generation via `AudioStreamWAV` for drawing, bouncing, hazards, and victory cues without external asset dependencies.
* **HMS SDK Integration Hooks**: Architecture prepared for Huawei Mobile Services (HMS) Game Service leaderboards and achievement overlays for Huawei AppGallery deployment.

---

## 🎮 Controls & Developer Testing Shortcuts

### Gameplay Controls
* **Draw**: Click and drag (Mouse / Touch) to draw physical guiding lines.
* **Pause**: Press `ESC` or click the pause icon to access system controls.

### Developer Testing Cheats (Active in-game)
* **[ 1 - 6 ]**: Instantly jump to any of the 6 terminals.
* **[ N ]**: Instant win / skip current terminal.
* **[ R ]**: Quick restart current terminal.

---

## 🛠️ Built With
* **Engine**: Godot 4.x (GDScript)
* **Target Platform**: Cross-platform (PC / Huawei Mobile via Android Export)