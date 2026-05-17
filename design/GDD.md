# PlaneGame — Game Design Document

## 1. Overview

**Title:** PlaneGame
**Genre:** Casual / Physics / Launcher
**Platform:** iOS (iPhone + iPad)
**Inspiration:** Epic Plane Evolution (Voodoo)
**Target Audience:** Casual mobile gamers, ages 8+

### Core Loop
Launch plane → Fly and collect coins → Crash or land → Spend coins on upgrades → Fly further → Repeat

## 2. Gameplay

### 2.1 Slingshot Launch
The player begins each flight by pulling back a slingshot. The further the pull, the more power. The angle of the pull determines the launch trajectory.

- **Input:** Touch-drag backward from the slingshot
- **Feedback:** Elastic band stretches, power percentage shown, trajectory dots preview the arc
- **Parameters:**
  - Max pull distance: 180pt
  - Min pull distance: 20pt (below this, launch cancels)
  - Launch power: 400–1800 units
  - Launch angle: 15°–80°

### 2.2 Flight Physics
Once airborne, the plane is subject to:

| Force | Description |
|-------|-------------|
| **Gravity** | Constant downward (4.8 m/s²) |
| **Thrust** | Forward force along plane heading (upgradeable) |
| **Lift** | Perpendicular to velocity, proportional to speed (upgradeable) |
| **Drag** | Opposes velocity, proportional to speed (reducible via upgrades) |

The player controls the plane's pitch by touching and dragging vertically. Stalling occurs above 45° angle of attack, reducing lift.

### 2.3 Coin Collection
Coins spawn in clusters along the flight path:
- Cluster size: 3–7 coins
- Spacing: ~220pt between clusters
- Coins float up and down with a shimmer animation
- Coin magnet: Pulls nearby coins toward the plane (radius upgradeable)

### 2.4 Obstacles
Obstacles are environment-specific and spawn after 600m:

| Environment | Obstacles |
|-------------|-----------|
| Countryside | Trees, barns, birds, windmills |
| Mountains | Peaks, birds, clouds, pine trees |
| City | Buildings, cranes, birds, antennas |

- Birds fly and oscillate
- Clouds are passable (no damage)
- All others cause a crash (unless shielded)

### 2.5 Power-ups
Three power-up types spawn randomly during flight:

| Power-up | Effect | Duration |
|----------|--------|----------|
| Speed Boost | 2x thrust | 3s |
| Shield | Absorbs one hit | 5s |
| Coin Magnet | 2x magnet radius | 6s |

Spawn chance: 12% per check interval, minimum 500m apart.

### 2.6 Landing / Crash
- **Smooth landing:** Speed < 150, angle < 15° from horizontal → Bonus 50 coins
- **Crash:** Speed > 250 or obstacle hit → Screen shake, dust particles, crash sound

## 3. Progression

### 3.1 Upgrade System
Three upgrade categories, each with 10 levels:

| Upgrade | Effect per Level | Base Cost | Cost Growth |
|---------|-----------------|-----------|-------------|
| Engine | +35 thrust | 50 coins | ×1.65 |
| Wings | +22 lift, +30 magnet radius | 50 coins | ×1.65 |
| Fuselage | -0.025 drag, -0.06 mass | 50 coins | ×1.65 |

### 3.2 Plane Evolution
As total upgrade levels increase, the plane visually transforms:

| Stage | Total Levels Required | Visual |
|-------|----------------------|--------|
| Propeller | 0 | Small red plane with spinning prop |
| Turbo Prop | 8 | Larger blue plane |
| Jet | 18 | Sleek green jet |
| Rocket | 27 | Golden rocket shape |

### 3.3 XP & Levels
- 0.5 XP per meter flown
- 2.0 XP per coin collected
- Level-up formula: 100 × 1.4^(level-1) XP per level

### 3.4 Environments
| Environment | Unlock Distance | Visual Theme |
|-------------|----------------|--------------|
| Countryside | 0m (default) | Green fields, blue sky |
| Mountains | 2,000m | Rocky peaks, indigo sky |
| City | 5,000m | Orange sunset, skyscrapers |

Each environment has unique parallax layers, ground color, and obstacle set.

### 3.5 Daily Challenges
One daily challenge available per day:
- Target: 1,500m distance OR 50 coins collected
- Reward: 200 coins
- Resets at midnight local time

## 4. Monetization

### 4.1 In-App Purchases (StoreKit 2)
| Product | ID | Type |
|---------|-----|------|
| Remove Ads | com.planegame.removeads | Non-consumable |
| 100 Gems | com.planegame.gems.small | Consumable |
| 500 Gems | com.planegame.gems.medium | Consumable |
| 1500 Gems | com.planegame.gems.large | Consumable |
| VIP Pass | com.planegame.vip | Non-consumable |

### 4.2 Advertising (AdMob)
- Banner ad on menu screen
- Interstitial ad every 3rd flight
- Rewarded video for 2x coin bonus on results screen

## 5. UI Screens

### 5.1 Main Menu
- Game title
- Plane preview with current stage label
- Coin counter
- Level indicator
- Best distance
- PLAY button (primary)
- UPGRADES button
- DAILY CHALLENGE button (when available)
- Settings gear icon

### 5.2 Game HUD
- Distance meter (top-left)
- Coin counter (top-right)
- Altitude indicator
- Speed bar
- Boost indicator (when active)

### 5.3 Results Screen
- Flight outcome (Smooth Landing / Flight Over)
- "NEW BEST!" badge when applicable
- Distance, coins, bonus, XP breakdown
- XP progress bar with level
- RETRY / UPGRADE / MENU buttons

### 5.4 Upgrade Screen
- Coin balance
- Plane preview (large, animated)
- Stage label
- Thrust / Lift / Aerodynamics stat bars
- 3 upgrade cards with level dots, cost, purchase button
- PLAY / BACK navigation
- Evolution banner on stage change

### 5.5 Settings Overlay
- Sound toggle
- Music toggle
- Haptics toggle
- Close button

## 6. Technical

### 6.1 Rendering
All graphics are procedurally generated using `SKShapeNode`. No texture atlas required. This enables:
- Zero asset dependencies for development
- Easy replacement with artist textures later
- Small app bundle size

### 6.2 Physics
SpriteKit's built-in physics engine with custom force application each frame:
- Category bitmasks for collision filtering
- Contact delegate for event dispatching
- Custom gravity, lift, drag, thrust calculations

### 6.3 Camera
- Smooth follow with configurable lead-ahead
- Independent X/Y smoothing rates
- Screen shake on crash (randomized offsets)

### 6.4 Persistence
`PlayerProgress` Codable struct serialized to UserDefaults. Contains all player state: coins, upgrades, unlocks, settings, daily challenge status.

### 6.5 Performance Targets
- 60 FPS on iPhone 12+
- Object pooling for coins (future optimization)
- Culling of offscreen obstacles

## 7. Audio

All audio is placeholder-based (filenames referenced, no-op if files missing):

| Event | Sound | File |
|-------|-------|------|
| Launch | Whoosh | launch_whoosh |
| Coin collect | Ding | coin_ding |
| Crash | Boom | crash_boom |
| Boost | Whoosh | boost_whoosh |
| Button tap | Click | button_tap |
| Upgrade | Chime | upgrade_chime |
| Ambient | Wind | ambient_wind |
| Background | Music | bg_music |

## 8. Future Roadmap (v1.1+)

- [ ] Texture-based graphics (artist assets)
- [ ] Additional environments (Ocean, Space, Desert)
- [ ] Pilot character customization
- [ ] Leaderboards via GameKit
- [ ] Achievement system
- [ ] Object pooling for performance
- [ ] Tutorial overlay for first-time players
- [ ] Social sharing of best distances
- [ ] Seasonal events with limited-time challenges
- [ ] Cloud save with iCloud
