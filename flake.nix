{
  description = "assistant";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      nixpkgs,
      rust-overlay,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ (import rust-overlay) ];
        };
        llvmPackages = pkgs.llvmPackages_latest;
        rustToolchain = pkgs.rust-bin.nightly.latest.default.override {
          extensions = [
            "rust-src"
            "rust-analyzer"
            "clippy"
            "llvm-tools-preview"
          ];
        };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            rustToolchain
            pkgs.pkg-config
            pkgs.cargo-fuzz
            llvmPackages.llvm
            pkgs.cargo-binutils
            pkgs.sea-orm-cli
            pkgs.vulkan-loader
            pkgs.vulkan-tools
          ];
          ASAN_SYMBOLIZER_PATH = "${llvmPackages.llvm}/bin/llvm-symbolizer";
          # wgpu dlopens libvulkan.so.1 (from vulkan-loader above) at runtime,
          # which in turn reads ICD manifests to find the actual driver. On
          # NixOS those manifests live under /run/opengl-driver — point the
          # loader at the Intel one and add the matching driver libs to
          # LD_LIBRARY_PATH so dlopen resolves.
          LD_LIBRARY_PATH = "/run/opengl-driver/lib:${pkgs.vulkan-loader}/lib";
        };
      }
    );
}
