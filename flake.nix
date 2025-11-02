{
  description = "Typing speed test with practice mode in GUI, TUI and CLI";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };
  outputs = {
    self,
    nixpkgs,
  }: let
    supportedSystems = ["x86_64-linux"];
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    pkgsFor = nixpkgs.legacyPackages;
  in {
    packages = forAllSystems (system: {
      # Default: light build without GUI (CLI + TUI only)
      default = pkgsFor.${system}.callPackage ./default.nix {
        buildFeatures = ["light"];
      };

      # Light build: CLI + TUI only (same as default)
      light = pkgsFor.${system}.callPackage ./default.nix {
        buildFeatures = ["light"];
      };

      # Full build: CLI + TUI + GUI
      full = pkgsFor.${system}.callPackage ./default.nix {
        buildFeatures = ["default"];
      };

      # CLI only
      cli-only = pkgsFor.${system}.callPackage ./default.nix {
        buildFeatures = ["cli"];
      };

      # TUI only
      tui-only = pkgsFor.${system}.callPackage ./default.nix {
        buildFeatures = ["tui"];
      };
    });
    devShells = forAllSystems (system: {
      default = pkgsFor.${system}.callPackage ./shell.nix {};
    });
  };
}
