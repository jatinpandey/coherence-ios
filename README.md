# Coherence iOS

Native SwiftUI breathing/coherence trainer for iPhone. Configurable patterns, pulsing orb, haptics, pitch-glide tones, and a daily streak.

## Run

```bash
open Coherence.xcodeproj
```

Pick an iPhone simulator (or your device, after setting Signing → Team) and ⌘R.

- Minimum: iOS 17
- Universal (iPhone primary, iPad supported)
- No external dependencies — pure SwiftUI + AVFoundation + UIKit haptics

## Structure

```
Coherence/
  CoherenceApp.swift        @main entry
  ContentView.swift         home screen, top bar, stats, run button
  BreathOrb.swift           pulsing accent ring + glow
  SettingsView.swift        sheet — presets, custom pattern, duration, toggles
  Models.swift              Phase, Pattern, Preset, presets
  BreathEngine.swift        @MainActor phase loop, animation, haptics
  Streak.swift              UserDefaults-backed daily streak
  ToneEngine.swift          AVAudioEngine sine-wave pitch-glide tones
  Assets.xcassets/          AccentColor, AppIcon
```

## Notes

- Bundle id `com.coherence.breath` — change in target → Signing & Capabilities for device deploys.
- A companion React Native (Expo) prototype lives at <https://github.com/jatinpandey/coherence>.
