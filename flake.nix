{
  description = "polywrap";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-nodejs.url =
      "github:nixos/nixpkgs?rev=6d02a514db95d3179f001a5a204595f17b89cb32";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs = { nixpkgs.follows = "nixpkgs"; };
    };
  };

  outputs = inputs@{ self, nixpkgs, ... }:
    let
      eachSystem = systems: f:
        let
          op = attrs: system:
            let
              ret = f system;
              op = attrs: key:
                let
                  appendSystem = key: system: ret: { ${system} = ret.${key}; };
                in attrs // {
                  ${key} = (attrs.${key} or { })
                    // (appendSystem key system ret);
                };
            in builtins.foldl' op attrs (builtins.attrNames ret);
        in builtins.foldl' op { } systems;
      defaultSystems = [
        "aarch64-linux"
        "aarch64-darwin"
        "i686-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
    in eachSystem defaultSystems (system:
      let
        pkgs-nodejs = import inputs.nixpkgs-nodejs { inherit system; };
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ inputs.rust-overlay.overlay ];
        };
      in {
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            # v16.13.0
            pkgs-nodejs.nodejs

            yarn
            docker-compose
            cargo

            # rust coverage
            grcov
            cargo-binutils
            (rust-bin.selectLatestNightlyWith (toolchain:
              toolchain.default.override {
                extensions = [ "llvm-tools-preview" ];
              }))
            pkg-config
            openssl
          ];
        };
      });
}

