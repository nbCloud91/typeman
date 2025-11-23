# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TypeMan is a Rust-based typing speed test application with three interface modes: CLI, TUI (terminal UI with ratatui), and GUI (graphical UI with macroquad/egui). This fork adds comprehensive Nix support with flexible feature flags to enable lightweight builds without GUI dependencies.

**Upstream**: https://github.com/mzums/typeman (main branch)

## Build Commands

### Standard Cargo Builds

```bash
# Full build (all features: CLI + TUI + GUI)
cargo build
cargo run

# Light build (CLI + TUI only, no GUI dependencies)
cargo build --no-default-features --features light
cargo run --no-default-features --features light

# Individual modes
cargo build --no-default-features --features cli
cargo build --no-default-features --features tui
cargo build --no-default-features --features gui
```

### Nix Builds

The flake provides multiple package outputs optimized for different use cases:

```bash
# Default/Light build (CLI + TUI, recommended)
nix build
nix run

# Full build with GUI
nix build .#full
nix run .#full

# Individual modes
nix build .#cli-only
nix build .#tui-only

# Development shell
nix develop
```

### Running Different Modes

```bash
# TUI mode (default)
typeman
typeman --tui

# GUI mode
typeman --gui

# CLI mode examples
typeman --cli                              # 30s test, 500 most common words
typeman --cli -w=50 -n=500 -p -d          # 50 words with punctuation & digits
typeman --cli -t=60                        # 60 second timed test
typeman --cli -c ./text.txt                # Custom text file
typeman --cli -q                           # Random quote
typeman --cli -l                           # List practice levels
typeman --cli -l=1                         # Practice specific level
typeman --cli --wiki                       # Wikipedia mode
```

## Architecture Overview

### Feature Flag System

The codebase uses Cargo features to enable/disable UI modes at compile time:

- **`cli`**: Command-line interface (requires: crossterm, ratatui)
- **`tui`**: Terminal UI with ratatui (requires: crossterm, ratatui)
- **`gui`**: Graphical UI with macroquad/egui (requires: macroquad, eframe, egui_plot, egui-macroquad)
- **`light`**: Convenience feature = `cli` + `tui`
- **`default`**: All features = `cli` + `tui` + `gui`

All code is conditionally compiled based on these features using `#[cfg(feature = "...")]` attributes. The main.rs includes compile-time checks to ensure at least one mode is enabled.

### Module Structure

```
src/
├── main.rs              # Entry point, CLI argument parsing, mode dispatch
├── lib.rs               # Module declarations and shared Cli struct
├── ui/
│   ├── cli/            # CLI mode implementation
│   ├── tui/            # TUI mode (ratatui)
│   └── gui/            # GUI mode (macroquad)
├── config.rs           # AppConfig persistence (~/.config/typeman/config.json)
├── leaderboard.rs      # Leaderboard with caching, file locking, validation
├── language.rs         # Multi-language support (English, Indonesian)
├── color_scheme.rs     # Theme system
├── practice.rs         # Practice level data and logic
└── utils.rs            # Shared utilities for text generation, WPM calculation
```

### Configuration System

- **Config file**: `~/.config/typeman/config.json` (automatically created)
- **Leaderboard**: `~/.config/typeman/leaderboard.json` (file-locked with fs2)
- **AppConfig struct**: Persists UI preferences (language, theme, test settings, etc.)
- Configs are loaded at startup and saved when modified through GUI/TUI settings

### Leaderboard Implementation

The leaderboard system includes:
- **File locking** (fs2) to prevent race conditions during concurrent writes
- **In-memory caching** with 30-second TTL and file modification time tracking
- **Validation** for all entry fields (WPM 0-300, accuracy 0-100%, duration 0-86400s, etc.)
- Entries are stored with timestamp, test type, mode, language, and results

### Test Modes

1. **Word Mode**: Type N words from top M most common words (with optional punctuation/digits)
2. **Time Mode**: Type random words for N seconds
3. **Quote Mode**: Type a random quote
4. **Practice Mode**: Progressive difficulty levels for specific character combinations
5. **Wikipedia Mode**: Type Wikipedia snippets
6. **Custom File**: Type contents of a user-provided text file

## Nix-Specific Architecture

### Fork Modifications

The upstream repository already includes Nix support (flake.nix, default.nix, shell.nix), but this fork extends it with flexible feature configuration. See `git diff upstream/main` for exact changes.

**Changes made:**

1. **`default.nix`** modifications (our fork):
   - Added `buildFeatures` parameter (defaults to `["light"]`)
   - Added `hasGui` detection logic: checks if "gui" or "default" is in buildFeatures
   - Made GUI dependencies conditional: `pkgs.lib.optionals hasGui [libx11 libxkbcommon]`
   - Added `inherit buildFeatures` to pass features to cargo
   - Added package metadata (description, homepage, license, mainProgram) read from Cargo.toml
   - Merged upstream's `writableTmpDirAsHomeHook` to enable tests during builds

2. **`flake.nix`** modifications (our fork):
   - Changed default output from `{}` to `{ buildFeatures = ["light"]; }`
   - Added four new package outputs: light, full, cli-only, tui-only
   - All outputs call default.nix with different buildFeatures

3. **`NIX_USAGE.md`**: New comprehensive documentation (145 lines)

4. **`shell.nix`**: No changes (upstream already had it)

**Key improvement**: Upstream always built with all features and included GUI dependencies. This fork enables:
- Building light versions (CLI/TUI only) by default
- Conditional GUI dependencies only when needed
- Easy access to different feature combinations via flake outputs

To compare with upstream: `git diff upstream/main -- flake.nix default.nix`

### Keeping Fork Synced with Upstream

The upstream repository is at https://github.com/mzums/typeman (main branch). To sync:

```bash
# Add upstream remote if not already added
git remote add upstream https://github.com/mzums/typeman.git

# Fetch upstream changes
git fetch upstream

# Merge upstream main into your branch
git merge upstream/main

# Or rebase to maintain clean history
git rebase upstream/main
```

**Important**: After syncing, verify that Nix-specific files (default.nix, flake.nix, shell.nix, NIX_USAGE.md) are not overwritten or conflicted.

## Development Notes

### Adding New Features

When adding features that require conditional compilation:
- Use `#[cfg(feature = "...")]` attributes consistently
- Update both main.rs and lib.rs module declarations
- Ensure feature dependencies are properly declared in Cargo.toml

### Language Support

Multi-language word lists are embedded in the binary via `include_str!()` macros. To add a new language:
1. Add word list files to `src/language_lists/`
2. Update `src/language.rs` enum and match statements
3. Update CLI `--lang` argument options

### Testing

No automated test suite is currently present. Manual testing workflow:
1. Build with desired features
2. Run each mode (CLI/TUI/GUI) and verify functionality
3. Test config persistence and leaderboard entry validation
4. For Nix builds, test each flake output

### Platform-Specific Dependencies

- **Linux**: Requires fontconfig, alsa-lib (+ libx11, libxkbcommon for GUI)
- **macOS**: May require `--target x86_64-apple-darwin`
- **Windows**: Uses USERPROFILE instead of HOME for config directory
