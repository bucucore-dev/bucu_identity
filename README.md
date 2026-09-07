# bucu_identity

> Complete Character Creator, 3D Civil Registry & Onboarding System for BucuCore (Compatible with QBCore, ESX, QBox & Standalone).

---

## 🌟 Overview

`bucu_identity` delivers a next-generation onboarding and character registration experience. Inspired by modern GTA V roleplay systems but redesigned with ultra-clean dark glassmorphism, 4-step wizard workflow, and full 3D in-game ped preview.

## 📦 Features
- **4-Step Modern Registration**:
  1. Identity Form (First & Last Name, DOB, Nationality, Gender)
  2. Heritage & DNA (Parents blend, skin tone blend)
  3. Facial Features & Hair (Nose, jaw, chin, cheeks, hair & facial hair styling)
  4. Outfits & Finish (Starter outfits, summary confirmation)
- **Live 3D Preview**: In-interior ped rendering with 4 camera modes (Full, Torso, Head, Legs) and 360° ped rotation.
- **Cross-Framework Bridge**:
  - `bucu_core`: Native character storage and event pipeline.
  - `qb-core` & `qbx_core`: Player creation, metadata setup, starter inventory.
  - `es_extended`: User registration, identifier binding.
  - `standalone`: License-based fallback.
- **Starter Pack Integration**: Auto-provisions cash, bank balance, and starter items (ID Card, Phone, Bread, Water Bottle).
- **Multicharacter Ready**: Directly connects with `bucu_multicharacter` empty slot clicks with automatic graceful fallback.

## ⚙️ Installation
Add to your `server.cfg`:
```cfg
ensure bucu_multicharacter
ensure bucu_identity
ensure bucu_appearance
ensure bucu_clothing
```

## 📜 License
Part of the BUCU Framework. Licensed under the MIT License.
