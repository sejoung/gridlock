<p align="center">
  <img src="assets/icon/icon.svg" alt="Gridlock" width="128" height="128">
</p>

<h1 align="center">Gridlock</h1>

<p align="center">
  A sliding puzzle game where you navigate cars out of a gridlocked parking lot.<br>
  Inspired by the classic <a href="https://en.wikipedia.org/wiki/Rush_Hour_(puzzle)">Rush Hour</a> board game.
</p>

Built with [Love2D](https://love2d.org) — runs on macOS, Windows, and Web.

## Gameplay

Move cars by dragging them along their axis. Horizontal cars slide left/right, vertical cars slide up/down. Clear a path for the **red car** to reach the exit on the right side of the board.

**Rules:**
- Cars can only move along their orientation (horizontal or vertical)
- Cars cannot pass through each other
- Move the red goal car to the exit to clear the level

## Play

### Web

Play directly in your browser (no install required):

> **[Play Gridlock](https://sejoung.github.io/gridlock/)**

### Desktop

Download the latest release from [Releases](https://github.com/sejoung/gridlock/releases):

| Platform | File | How to run |
|----------|------|------------|
| macOS | `gridlock-macos.zip` | Extract and open `Gridlock.app` |
| Windows | `gridlock-windows.zip` | Extract and run `gridlock.exe` |
| Universal | `gridlock.love` | Requires [Love2D](https://love2d.org) installed |

### From Source

```bash
# Install Love2D
brew install love      # macOS
# or download from https://love2d.org

# Clone and run
git clone https://github.com/sejoung/gridlock.git
cd gridlock
love .
```

## Controls

| Input | Action |
|-------|--------|
| Mouse drag | Move a car |
| `U` | Undo last move |
| `R` | Reset level |
| `Esc` | Quit |

## Features

- 10 hand-crafted levels with pixel art car sprites
- Undo / Reset with move counter
- Smooth move animations and shake feedback on invalid moves
- Pulsing exit indicator
- Procedural sound effects
- Save system (tracks cleared levels and best move counts)
- Level select screen with clear status

## Level Generator

A browser-based tool for creating and analyzing levels:

```bash
open tools/generator.html
```

- **Generate** levels by difficulty (Easy / Medium / Hard / Mixed)
- **Analyze** existing `.lua` level files — BFS solver finds minimum moves and detects overlaps
- Visual board preview and `.lua` file export

Difficulty is determined by the minimum number of moves to solve (BFS):

| Difficulty | Min Moves |
|------------|-----------|
| Easy | 1 - 8 |
| Medium | 9 - 16 |
| Hard | 17+ |

## Project Structure

```
gridlock/
├── main.lua              # Entry point
├── conf.lua              # Love2D config
├── src/
│   ├── game.lua          # Game state management
│   ├── board.lua         # Grid, collision, clear detection
│   ├── car.lua           # Car rendering and logic
│   ├── car_types.lua     # Car type definitions (len, sprite)
│   ├── input.lua         # Mouse drag input handling
│   ├── level.lua         # Level file loader
│   ├── save.lua          # Save/load cleared data
│   ├── ui.lua            # UI screens (title, level select, HUD, clear)
│   ├── anim.lua          # Move/shake animations
│   └── sound.lua         # Procedural sound effects
├── assets/
│   └── cars/             # Pixel art car sprites
├── levels/
│   ├── level1.lua        # Level data files
│   └── ...
└── tools/
    ├── generator.html    # Web-based level generator/analyzer
    ├── solver.lua        # BFS puzzle solver
    └── generator.lua     # Random level generator
```

## Level Format

Levels are plain Lua tables. Add new levels by creating `levels/levelN.lua`:

```lua
return {
    id = 1,
    exit = { side = "right", row = 3 },
    cars = {
        { id = "goal", x = 1, y = 3, dir = "H", type = "sport_red" },
        { id = "c1",   x = 3, y = 1, dir = "V", type = "trailer" },
        { id = "c2",   x = 5, y = 2, dir = "V", type = "sedan_blue" },
    }
}
```

Available car types are defined in `src/car_types.lua`. Length is determined by the type (`trailer` = 3 cells, everything else = 2 cells).

## Building

Builds are automated via GitHub Actions. Push a version tag to trigger:

```bash
git tag v1.0.0
git push origin --tags
```

This produces:
- `.love` file (universal)
- macOS app bundle (`.app`)
- Windows executable (`.exe`)
- Web build (deployed to GitHub Pages)

## Tech Stack

- **Engine:** [Love2D](https://love2d.org) 11.4
- **Language:** Lua
- **Art:** 2D top-down pixel art
- **Level Tool:** HTML/JS with BFS solver
- **CI/CD:** GitHub Actions
- **Hosting:** GitHub Pages (web build)

## License

[Apache License 2.0](LICENSE)
