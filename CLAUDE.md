# PlaneGame - Claude Context

## Project Overview
iOS SpriteKit game inspired by "Epic Plane Evolution" by Voodoo. Physics-based slingshot flight game with upgrade progression.

## Tech Stack
- **Language:** Swift 5.9+
- **Framework:** SpriteKit (2D game rendering, physics)
- **Target:** iOS 16.0+, Universal (iPhone + iPad)
- **Architecture:** Scene-based with ECS-lite (Nodes, Systems, Managers)
- **UI:** SpriteKit scenes (not UIKit/SwiftUI for game screens), SwiftUI app entry point
- **Persistence:** UserDefaults with Codable models
- **IAP:** StoreKit 2 (async/await API)
- **Ads:** AdMob placeholder (not yet integrated)

## Directory Structure
```
PlaneGame/
├── PlaneGame.xcodeproj/     # Xcode project
├── PlaneGame/               # Main app target
│   ├── App/                 # App entry point, GameViewController
│   ├── Scenes/              # SpriteKit scenes (Menu, Game, Upgrade, Shop)
│   ├── Nodes/               # Game entities (Plane, Slingshot, Obstacles, Coins, Environment)
│   ├── Systems/             # Game logic (Physics, Upgrades, Coins, Progression)
│   ├── Models/              # Data models (Codable, persisted)
│   ├── Managers/            # Singletons (Game, Audio, Haptics, Ads, IAP)
│   ├── Utils/               # Extensions, math helpers, constants
│   ├── Config/              # GameConfig.swift — ALL tunable values
│   └── Resources/           # Assets.xcassets, sounds/, particles/
├── design/                  # Game design document
└── CLAUDE.md                # This file
```

## Key Patterns

### No Magic Numbers
ALL game-tunable values live in `Config/GameConfig.swift`. Nested enums organize by domain (Plane, Slingshot, Coins, etc.). Reference these constants everywhere.

### Scene Navigation
`GameManager.shared` handles all scene transitions via `presentScene(_:in:)`. Scenes should never directly create/present other scenes.

### Data Flow
`PlayerProgress` is the single source of truth for player state. It's Codable and persisted to UserDefaults. `ProgressionSystem` and `UpgradeSystem` wrap it with game logic.

### Physics
`PhysicsSystem` is the `SKPhysicsContactDelegate`. It dispatches collision events via closures to `GameScene`. Category bitmasks are in `GameConfig.PhysicsCategory`.

### Node Architecture
Each game entity is an `SKNode` subclass that builds its own visual children (using `SKShapeNode` — no texture assets required). Plane evolves visually based on upgrade level.

## Common Tasks

### Adding a new obstacle type
1. Add case to `ObstacleKind` enum in `EnvironmentModel.swift`
2. Add builder method in `ObstacleNode.swift`
3. Add to relevant environment's `obstacleTypes` array in `EnvironmentModel`

### Adding a new upgrade
1. Add case to `UpgradeType` in `Constants.swift`
2. Add level storage to `PlaneModel`
3. Add stat computation to `PlaneModel` computed properties
4. Add cost/per-level config to `GameConfig.Upgrades`
5. Update `UpgradeSystem` and `UpgradeScene`

### Tuning game feel
Edit values in `GameConfig.swift`. Key sections:
- `Plane` — thrust, lift, drag, mass, pitch sensitivity
- `Slingshot` — pull distance, launch power range, angle limits
- `World` — gravity

### Adding sound/music
1. Drop audio files into `Resources/sounds/`
2. Reference the filename (without extension) in `GameConfig.Audio`
3. `AudioManager` will auto-load on init

## Build & Run
Open `PlaneGame.xcodeproj` in Xcode 15+, select an iOS 16+ simulator or device, and build (Cmd+R).
