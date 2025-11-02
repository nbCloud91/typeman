{
  pkgs ? import <nixpkgs> {},
  # Build features: "light" = CLI+TUI only, "default" = CLI+TUI+GUI
  # Or specify custom features like ["cli" "tui"]
  buildFeatures ? ["light"]
}: let
  manifest = (pkgs.lib.importTOML ./Cargo.toml).package;

  # Check if GUI feature is requested
  hasGui = builtins.elem "gui" buildFeatures || builtins.elem "default" buildFeatures;
in
  pkgs.rustPlatform.buildRustPackage rec {
    pname = manifest.name;
    version = manifest.version;
    cargoLock.lockFile = ./Cargo.lock;
    src = pkgs.lib.cleanSource ./.;

    # Configure cargo features
    inherit buildFeatures;

    # Only include GUI dependencies if GUI feature is enabled
    buildInputs = with pkgs; [
      fontconfig
      alsa-lib
    ] ++ pkgs.lib.optionals hasGui [
      libx11
      libxkbcommon
    ];

    nativeBuildInputs = with pkgs; [pkg-config];

    meta = with pkgs.lib; {
      description = manifest.description;
      homepage = manifest.repository;
      license = licenses.mit;
      mainProgram = "typeman";
    };
  }
