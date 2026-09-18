# Steal a Crystal

An original Roblox steal/collection game built as a **Rojo** project. Pick up crystals in the wilds, store them on your personal base, sell for Coins, upgrade at the Shop — and steal from other players (or the demo NPC base in Play Solo).

> Not affiliated with any existing “Steal a …” titles. Original systems, names, and art direction.

## Pitch

Crystals rain across a shared wild zone. Every player owns a **Crystal Base** with pedestal slots and a gold **Sell Pad**. Carry capacity starts at 1 and upgrades to 3. Steal with a ProximityPrompt; owners can touch thieves near their base to force a kid-friendly drop. Soft tutorial on first join. DataStore with in-memory fallback so Studio works without API Services.

## Requirements

- [Rojo](https://rojo.space/) 7.x (`cargo install rojo` or download release)
- Roblox Studio with the [Rojo plugin](https://www.roblox.com/library/13916111004/Rojo-7)
- Optional: enable **Studio Access to API Services** only if you want live DataStore tests

## Sync into Studio

```bash
cd steal-a-crystal
rojo serve
```

1. Open Roblox Studio → new **Baseplate** (or empty place).
2. Plugins → **Rojo** → **Connect** → `localhost:34872` (default).
3. Click **Play** (F5). The server builds the world automatically — no manual map required.

### One-shot build (optional)

```bash
rojo build -o StealACrystal.rbxlx
```

Open the `.rbxlx` in Studio and Play.

## Playtest checklist

1. You spawn at your personal base (ring of plots around the wilds).
2. Walk to **Crystal Wilds** → ProximityPrompt **Pick Up**.
3. Return to your base → **Place Crystals** on the floor prompt (or remote).
4. Use the gold **Sell Pad** → Coins appear in leaderstats.
5. Visit the purple **Shop** booth → buy Swift Boots / Pouch / Luck / Base Shield.
6. Find the **Crystal Keeper** NPC base → **Steal** the Rare crystal.
7. As a second player (or mentally): owner touch near base drops carried crystals.

**Keys:** `G` drop carried · `B` toggle shop UI

## Publish notes

1. Create a place on Roblox Creator Dashboard / Game Settings.
2. `rojo build -o place.rbxlx`, upload, or use a CI sync workflow.
3. Enable **DataStore** for the experience if you want persistence (code already `pcall`s and falls back in Studio).
4. Set spawn / filtering (FilteringEnabled is assumed). Game generates geometry at runtime.
5. Add icons, thumbnails, and a store page blurb from the pitch above.
6. Test with 2+ clients for steal + owner-drop.

## Project layout

```
steal-a-crystal/
  default.project.json
  README.md
  DESIGN.md
  src/
    ReplicatedStorage/Shared/   Config, Remotes
    ServerScriptService/        Main + Services
    StarterPlayer/.../          Client + Controllers
```

## Kom igång (svenska)

1. Installera Rojo och Studio-pluginen.
2. Kör `rojo serve` i den här mappen.
3. Öppna en Baseplate i Studio → anslut Rojo-pluginen.
4. Tryck Play. Världen, baser, shop och kristaller skapas automatiskt.
5. Testa loopen: plocka upp → placera → sälj → uppgradera → stjäl från NPC-basen.

Lycka till — och bygg gärna vidare med nya rarities i `Config.lua`!

## License

Code provided for Rami’s project use. Roblox TOS applies to any published experience.
