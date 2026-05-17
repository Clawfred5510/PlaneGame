# PlaneGame

A physics-based slingshot flight game for iOS, built with Swift and SpriteKit. Inspired by "Epic Plane Evolution" by Voodoo.

## Features

- **Slingshot launch mechanic** — Pull back to aim, release to launch
- **Physics-based flight** — Gravity, lift, drag, thrust simulation
- **Upgrade system** — Engine, wings, fuselage with 10 levels each
- **Plane evolution** — Visual transformation from propeller to rocket
- **3 environments** — Countryside, mountains, city (unlocked by distance)
- **Power-ups** — Speed boost, shield, coin magnet
- **Coin collection** — Clustered coins with magnet attraction
- **Obstacle variety** — Trees, buildings, birds, mountains, cranes
- **Parallax scrolling** — 4-layer background with environment-specific visuals
- **Daily challenges** — Distance and coin targets for bonus rewards
- **Progression** — XP levels, personal best tracking, environment unlocks
- **Haptic feedback** — Launch, collect, crash events
- **In-app purchases** — Gem packs, ad removal, VIP pass (StoreKit 2)
- **Ad integration** — AdMob placeholder ready for implementation

## Requirements

- Xcode 15.0+
- iOS 16.0+
- Swift 5.9+

## Setup

1. Clone the repository
2. Open `PlaneGame.xcodeproj` in Xcode
3. Select your target device or simulator (iPhone/iPad)
4. Build and run (Cmd+R)

No external dependencies or CocoaPods required. The game uses procedurally generated graphics (SKShapeNode) so no texture assets are needed to run.

## Project Structure

```
PlaneGame/
├── App/          — SwiftUI app entry, GameViewController
├── Scenes/       — Menu, Game, Upgrade, Shop scenes
├── Nodes/        — Plane, Slingshot, Obstacles, Coins, Environment
├── Systems/      — Physics, Upgrades, Coins, Progression
├── Models/       — PlaneModel, UpgradeModel, PlayerProgress
├── Managers/     — Game, Audio, Haptics, Ads, IAP managers
├── Utils/        — Extensions, math helpers, constants/enums
├── Config/       — GameConfig with all tunable values
└── Resources/    — Asset catalog, sound/particle placeholders
```

## Architecture

- **Scene-based** — Each screen is an SKScene managed by GameManager
- **Config-driven** — All game values in GameConfig.swift (no magic numbers)
- **Codable persistence** — PlayerProgress saved to UserDefaults
- **Singleton managers** — GameManager, AudioManager, HapticsManager, etc.
- **Procedural visuals** — All graphics built from SKShapeNode (no textures needed)

## Controls

- **Slingshot**: Touch and drag backward to aim, release to launch
- **In-flight**: Touch and drag up/down to control pitch
- **Menus**: Tap buttons to navigate

## Adding Assets

The game runs with procedural graphics by default. To add real textures:

1. Add images to `Resources/Assets.xcassets`
2. Replace `SKShapeNode` usage in node classes with `SKSpriteNode(imageNamed:)`
3. Add sound files (.wav/.mp3) to `Resources/sounds/`
4. Reference filenames in `GameConfig.Audio`

## License

Private project. All rights reserved.
