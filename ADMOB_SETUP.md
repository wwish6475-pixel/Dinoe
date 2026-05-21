# Dino Rush — AdMob Setup Guide

## Ad Unit IDs (Teri details)
| Ad Type    | Unit ID                                      |
|------------|----------------------------------------------|
| App ID     | ca-app-pub-2417109156263886~2434312983       |
| Banner     | ca-app-pub-2417109156263886/1048694682       |
| App Open   | ca-app-pub-2417109156263886/7761827135       |

---

## Step 1 — GodotAdMob Plugin Download karo

1. Yahan jao: https://github.com/poingstudios/godot-admob-android/releases
2. Latest release se **`GodotAdMob-release.zip`** download karo (Godot 4 ke liye)
3. Zip extract karo — andar `admob-plugin.gdap` aur `GodotAdMob.release.aar` milega

---

## Step 2 — Plugin files project mein daalo

Project ke andar yeh folder structure banana hai:

```
dino_rush/
├── android/
│   └── plugins/
│       ├── GodotAdMob.gdap        ← plugin config
│       └── GodotAdMob.release.aar ← plugin binary (downloaded .aar)
```

**Important:** Downloaded `.aar` file ko `android/plugins/` folder mein copy karo.

---

## Step 3 — AndroidManifest mein App ID daalo

Godot Editor mein:
1. **Project → Export → Android** open karo
2. **"Custom AndroidManifest"** enable karo (pehli baar auto-generate hoga)
3. File milegi: `android/build/AndroidManifest.xml`
4. `<application>` tag ke andar yeh add karo:

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-2417109156263886~2434312983"/>
```

---

## Step 4 — Godot Export Settings

1. **Project → Export → Android**
2. **"Use Custom Build"** → Enable ✓
3. **Plugins** section mein **"GodotAdMob"** tick karo ✓
4. Min SDK: **21** ya upar
5. **"Internet"** permission enable karo ✓

---

## Step 5 — Test Mode (IMPORTANT!)

`scripts/AdMobManager.gd` mein line hai:
```gdscript
const USE_TEST_ADS := true
```

**Development/testing ke waqt:** `true` rakhna  
**Release ke waqt:** `false` kar dena

Test ads se Google account ban nahi hota. Real ads se testing ki toh ban risk hai!

---

## Ad Behaviour (Kya kab dikhega)

| Event              | Ad                         |
|--------------------|----------------------------|
| Game launch        | App Open Ad + Banner       |
| Game Over          | App Open Ad (0.5s delay)   |
| Har waqt           | Banner (screen ke neeche)  |

---

## Agar Plugin Kaam Na Kare

Editor mein ads nahi chalenge — yeh sirf Android build pe kaam karta hai.
Console mein yeh message normal hai:
```
[AdMob] Plugin NOT found. Running without ads (Editor/iOS/unsupported).
```

---

## Files Added/Modified

| File | Change |
|------|--------|
| `scripts/AdMobManager.gd` | **NEW** — AdMob autoload singleton |
| `scripts/Main.gd` | Banner + OpenApp calls added |
| `project.godot` | AdMobManager autoload registered |
| `android/plugins/GodotAdMob.gdap` | **NEW** — Plugin config |
