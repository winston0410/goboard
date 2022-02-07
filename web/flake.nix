{

  inputs = {
    naersk.url = "github:nmattia/naersk/master";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs = { self, nixpkgs, utils, naersk, rust-overlay }:
    utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs { inherit system overlays; };
        naersk-lib = pkgs.callPackage naersk { };
      in {

        defaultPackage = naersk-lib.buildPackage ./.;

        defaultApp = utils.lib.mkApp { drv = self.defaultPackage."${system}"; };

        devShell = with pkgs;
          mkShell {
            nativeBuildInputs = [
              pkgconfig
              clang
              lld # To use lld linker
            ];
            buildInputs = [
              cargo
              ((rust-bin.selectLatestNightlyWith
                (toolchain: toolchain.default)).override {
                  targets = [ "wasm32-unknown-unknown" ];
                })
              wasm-pack
              rustfmt
              pre-commit
              rustPackages.clippy
              alsa-lib
              udev
              vulkan-loader
              xorg.libX11
              x11
              xorg.libXrandr
              xorg.libXcursor
              xorg.libXi
              #NOTE For building with wasm-pack
              openssl_3_0
            ];
            shellHook = ''
              export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${
                pkgs.lib.makeLibraryPath [ udev alsaLib vulkan-loader ]
              }"'';
            RUST_SRC_PATH = rustPlatform.rustLibSrc;
          };

      });

}
