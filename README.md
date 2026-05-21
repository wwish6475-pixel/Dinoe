# 🦕 Dino Rush — Godot 4 + AdMob

A fun endless runner built with **Godot 4**, featuring environment changes, coins, lives, and Google AdMob integration for Android.

---

## 📸 Features

- 🦕 Custom Blue Dino sprite
- 🌙 **NIGHT** — Mountains + Stars + Moon
- ☀️ **DAY** — Pyramids + Sun + Blue sky
- 🌅 **EVENING** — Taj Mahal + Orange sunset
- Smooth environment crossfade transitions
- Cactus + Pterodactyl obstacles
- Gold coins collect karo (+100 score)
- 3 lives system
- Double jump with gold glow
- Sound effects
- 📱 Google AdMob — Banner + App Open Ads

---

## 🎮 Controls

| Action      | Key                            |
|-------------|--------------------------------|
| Jump        | SPACE / UP Arrow / Screen Tap  |
| Double Jump | Phir se SPACE / UP             |
| Duck        | DOWN Arrow                     |

---

## 🚀 How to Open in Godot

1. **Godot 4.2+** download karo: https://godotengine.org/download
2. Godot open karo → `Import` click karo
3. Is folder ke andar `project.godot` file select karo
4. `Import & Edit` press karo
5. Play button dabao **(F5)** ✅

---

## 📁 Project Structure

```
dino_rush/
├── project.godot              ← Main project file
├── assets/
│   ├── dino.png               ← Dino sprite
│   ├── jump.wav
│   ├── score.wav
│   └── hit.wav
├── scenes/
│   └── Main.tscn              ← Main scene
├── scripts/
│   ├── Main.gd                ← Game logic
│   ├── Dino.gd                ← Dino physics
│   └── AdMobManager.gd        ← AdMob singleton
└── android/
    └── plugins/
        └── GodotAdMob.gdap    ← Plugin config (remote)
```

---

## 📱 Android + AdMob Setup

### Ad Unit IDs

| Ad Type  | Unit ID                                    |
|----------|--------------------------------------------|
| App ID   | `ca-app-pub-2417109156263886~2434312983`   |
| Banner   | `ca-app-pub-2417109156263886/1048694682`   |
| App Open | `ca-app-pub-2417109156263886/7761827135`   |

### Quick Steps

1. **GodotAdMob Plugin download karo:**  
   👉 https://github.com/poingstudios/godot-admob-android/releases  
   Latest `GodotAdMob-release.zip` lo aur `.aar` file `android/plugins/` mein daalo

2. **AndroidManifest mein App ID daalo** (`Project → Export → Android → Custom AndroidManifest`):
   ```xml
   <meta-data
       android:name="com.google.android.gms.ads.APPLICATION_ID"
       android:value="ca-app-pub-2417109156263886~2434312983"/>
   ```

3. **Export settings:**
   - Use Custom Build ✓
   - Plugin: GodotAdMob ✓
   - Min SDK: 21+
   - Internet permission ✓

4. **Release se pehle test mode band karo:**  
   `scripts/AdMobManager.gd` mein:
   ```gdscript
   const USE_TEST_ADS := false  # ← production ke liye
   ```

> Full setup guide: [`ADMOB_SETUP.md`](ADMOB_SETUP.md)

---

## 📦 Export (Android APK)

1. `Project → Export` open karo
2. Android preset add karo
3. Debug/Release APK export karo

---

## 🛠️ Tech Stack

- **Engine:** Godot 4.2+
- **Language:** GDScript
- **Ads:** Google AdMob via [GodotAdMob plugin](https://github.com/poingstudios/godot-admob-android)
- **Renderer:** GL Compatibility (mobile-friendly)

---

Made with ❤️ using Godot 4
