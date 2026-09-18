# Steal a Crystal — Design & Systems

## Core loop

```
Spawn at personal base
    → gather crystals in Wild Zone (ProximityPrompt)
    → carry to base → Place on pedestals
    → Sell Pad → Coins
    → Shop upgrades (speed / carry / luck / base lock)
    → Steal from other bases (or NPC demo)
    → Owner touch near base → thief drops (kid-friendly)
```

## Architecture

| Module | Role |
|--------|------|
| `Config` | All tunables: rarities, shop, plots, wild spawn, steal rules |
| `Remotes` | Creates RemoteEvents; server `init()`, client `get()` |
| `WorldBuilder` | Ground, wild pad, shop booth, lighting; clears default Baseplate |
| `BaseService` | Ring of plots, pedestals, sell pad, place/remove/sell, NPC base |
| `CrystalService` | Wild spawn, pickup, carry visuals, place, steal, drop, owner-touch |
| `EconomyService` | leaderstats Coins/Crystals, spend, walk speed / carry / luck |
| `ShopService` | Catalog + validated purchases near shop |
| `DataService` | DataStore `pcall` + memory fallback, autosave |
| `UIController` | HUD, toasts, shop panel |
| `TutorialController` | First-join soft tutorial |
| `CarryController` | Local carry count for HUD |

**Authority:** All economy, inventory, steal, and place logic runs on the server. Remotes re-check distance, ownership, capacity, lock state, and costs.

## World generation

On boot, `Main.server.lua` builds:

1. Large ground + glowing **Crystal Wilds** pad
2. Up to `Config.Base.maxPlots` bases on a ring (`ringRadius`)
3. Shop booth south of wilds
4. NPC plot on the last index with one Rare crystal
5. Lobby `SpawnLocation` (players are teleported to their plot on character spawn)

Blank Baseplate is enough — default baseplate/spawn are removed.

## Crystals & rarities

Defined in `Config.Rarities`: Common / Rare / Epic / Legendary with `value`, `color`, `size`, `spawnWeight`, `glow`.

Luck upgrades bias the weighted roll toward rarer tiers when maintaining wild population (uses max luck among online players × 0.5).

## Steal rules

- Steal via `StealPrompt` on stored pedestal crystals.
- Blocked if: own base, base locked (`BaseLock` upgrade after place), carry full, too far.
- Owner `HumanoidRootPart.Touched` near **their** plot forces thief drop; crystals respawn as wild nearby.

## Shop items

| Id | Effect |
|----|--------|
| WalkSpeed1/2 | Humanoid.WalkSpeed 20 / 24 |
| Carry2/3 | Capacity 2 / 3 |
| Luck1/2 | spawn weight bias |
| BaseLock | brief shield after placing |

Tiered items require previous id (`requires` field).

## Extending

### Add a rarity

1. Add entry to `Config.Rarities` + `Config.RarityOrder`.
2. No other code changes — spawn, mesh color, sell value follow Config.

### Add a shop upgrade

1. Add to `Config.Shop.items` with `effect` table.
2. Extend `EconomyService.getWalkSpeed` / `getCarryCapacity` / `getLuckBonus` (or add a new getter) to read the upgrade.
3. Client shop UI rebuilds from server catalog automatically.

### More plots

Raise `Config.Base.maxPlots` and optionally `ringRadius` / `plotSpacing`.

### Persistence fields

Extend `DataService.PlayerData` + merge logic in `load()`. Bump store name (`StealACrystal_v2`) if you break compatibility.

### Custom map

Replace or skip `WorldBuilder.build()` pieces; keep folder names `GameWorld/Crystals`, `GameWorld/Bases`, `GameWorld/Shop` expected by services — or update those WaitForChild paths.

## Anti-exploit notes

- Never trust client for coins, rarity, or “I stole X”.
- ProximityPrompt `Triggered` still re-validates distance and state.
- Shop spend uses `trySpend` after prerequisite checks.
- Carry is server-side table keyed by `UserId`; visuals are cosmetic.

## Known limitations

- Carry weld uses `WeldConstraint` (good enough; slight visual lag on laggy clients).
- NPC does not pathfind or chase — static demo figure.
- No combat; steal is prompt + touch-drop only.
- Single shared luck influence on wild spawns (not per-player spawn tables).
- Plot count hard-capped; excess players get no plot (warn in output).

## Tuning cheatsheet

Edit `src/ReplicatedStorage/Shared/Config.lua`:

- Faster economy → lower shop `cost`, higher rarity `value`
- More action → lower `WildZone.respawn` / raise `maxCrystals`
- Kinder PvP → raise `Base.lockDuration` or disable `Steal.dropOnOwnerTouch`
