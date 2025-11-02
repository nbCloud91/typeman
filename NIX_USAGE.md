# Nix Usage Guide for TypeMan

This fork adds comprehensive Nix support for building TypeMan with flexible feature configurations.

## Quick Start

### Build Without GUI (Recommended)

```bash
# Default build: CLI + TUI only (no heavy GUI dependencies)
nix build github:nbCloud91/typeman

# Run directly
nix run github:nbCloud91/typeman
```

### Build Options

The flake provides multiple package outputs for different use cases:

```bash
# Light build: CLI + TUI only (same as default)
nix build github:nbCloud91/typeman#light
nix run github:nbCloud91/typeman#light

# Full build: CLI + TUI + GUI (includes all features)
nix build github:nbCloud91/typeman#full
nix run github:nbCloud91/typeman#full

# CLI only (minimal)
nix build github:nbCloud91/typeman#cli-only
nix run github:nbCloud91/typeman#cli-only

# TUI only
nix build github:nbCloud91/typeman#tui-only
nix run github:nbCloud91/typeman#tui-only
```

## Feature Comparison

| Build | Features | Dependencies | Use Case |
|-------|----------|--------------|----------|
| `default` / `light` | CLI + TUI | fontconfig, alsa-lib | Recommended for most users |
| `full` | CLI + TUI + GUI | + libx11, libxkbcommon | Full graphical experience |
| `cli-only` | CLI only | fontconfig, alsa-lib | Minimal terminal-only |
| `tui-only` | TUI only | fontconfig, alsa-lib | Terminal UI only |

## Installation

### Add to NixOS Configuration

Add to `environment.systemPackages`:

```nix
# System configuration
environment.systemPackages = [
  # Light build (default)
  (pkgs.callPackage (builtins.fetchGit {
    url = "https://github.com/nbCloud91/typeman";
    ref = "master";
  }) { buildFeatures = ["light"]; })
];
```

### Add to Home Manager

```nix
# home.nix
home.packages = [
  # Light build (default)
  (pkgs.callPackage (builtins.fetchGit {
    url = "https://github.com/nbCloud91/typeman";
    ref = "master";
  } + "/default.nix") { buildFeatures = ["light"]; })

  # Or full build with GUI
  (pkgs.callPackage (builtins.fetchGit {
    url = "https://github.com/nbCloud91/typeman";
    ref = "master";
  } + "/default.nix") { buildFeatures = ["default"]; })
];
```

### Using Flakes

```nix
# flake.nix
{
  inputs = {
    typeman.url = "github:nbCloud91/typeman";
  };

  outputs = { self, nixpkgs, typeman }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        {
          environment.systemPackages = [
            typeman.packages.x86_64-linux.default  # or .light, .full, etc.
          ];
        }
      ];
    };
  };
}
```

## Development

Enter development shell:

```bash
nix develop github:nbCloud91/typeman
```

## Custom Feature Configuration

You can also call the package directly with custom features:

```nix
pkgs.callPackage ./default.nix {
  buildFeatures = ["cli" "tui"];  # Mix and match features
}
```

## Available Cargo Features

From `Cargo.toml`:
- `cli` - Command-line interface
- `tui` - Terminal user interface (ratatui)
- `gui` - Graphical user interface (macroquad, egui)
- `light` - Convenience feature = `cli` + `tui`
- `default` - All features = `cli` + `tui` + `gui`

## Why Fork?

This fork adds:
1. **Flexible feature configuration** - Build only what you need
2. **Default to light build** - Most users don't need the GUI
3. **Multiple package outputs** - Easy access to different configurations
4. **Conditional dependencies** - GUI deps only included when needed
5. **Better metadata** - Proper package description and licensing

## Upstream

Original project: https://github.com/mzums/typeman
