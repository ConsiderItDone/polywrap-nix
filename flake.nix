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
    monorepo = {
      url = "github:polywrap/monorepo?ref=origin-dev";
      flake = false;
    };
  };

  outputs = inputs@{ self, nixpkgs, monorepo, ... }:
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
          overlays = [ inputs.rust-overlay.overlays.default ];
        };
        yarnLock = monorepo + "/yarn.lock";
        msgpack-js = pkgs.mkYarnPackage rec {
          name = "msgpack-js";
          version = "0.1.1";
          src = monorepo + "/packages/js/msgpack";
          inherit yarnLock;
          preConfigure = ''
            substituteInPlace tsconfig.json --replace "../../../tsconfig" "${monorepo}/tsconfig.json"
          '';
          buildPhase = "yarn build";
        };
        asyncify-js = pkgs.mkYarnPackage rec {
          name = "asyncify-js";
          version = "0.1.1";
          src = monorepo + "/packages/js/asyncify";
          inherit yarnLock;
          preConfigure = ''
            substituteInPlace tsconfig.json --replace "../../../tsconfig" "${monorepo}/tsconfig.json"
          '';
          buildPhase = "yarn build";
        };
        tracing-js = pkgs.mkYarnPackage rec {
          name = "tracing-js";
          version = "0.1.1";
          src = monorepo + "/packages/js/tracing";
          inherit yarnLock;
          preConfigure = ''
            substituteInPlace tsconfig.json --replace "../../../tsconfig" "${monorepo}/tsconfig.json"
          '';
          buildPhase = "yarn build";
        };
        os-js = pkgs.mkYarnPackage rec {
          name = "os-js";
          version = "0.1.1";
          src = monorepo + "/packages/js/os";
          inherit yarnLock;
          preConfigure = ''
            substituteInPlace tsconfig.json --replace "../../../tsconfig" "${monorepo}/tsconfig.json"
          '';
          buildPhase = "yarn build";
        };
        wasm-as = pkgs.mkYarnPackage rec {
          name = "wasm-as";
          version = "0.1.1";
          src = monorepo + "/packages/wasm/as";
          inherit yarnLock;
          preConfigure = ''
            substituteInPlace tsconfig.json --replace "../../../tsconfig" "${monorepo}/tsconfig.json"
          '';
          buildPhase = "yarn build";
        };
        test-cases = pkgs.mkYarnPackage rec {
          name = "test-cases";
          version = "0.1.1";
          src = monorepo + "/packages/test-cases";
          inherit yarnLock;
          workspaceDependencies = [ os-js ];
        };
        polywrap-manifest-schemas = pkgs.mkYarnPackage rec {
          name = "polywrap-manifest-schemas";
          version = "0.1.1";
          src = monorepo + "/packages/manifests/polywrap";
          inherit yarnLock;
        };
        wrap-manifest-schemas = pkgs.mkYarnPackage rec {
          name = "wrap-manifest-schemas";
          version = "0.1.1";
          src = monorepo + "/packages/manifests/wrap";
          inherit yarnLock;
        };
        polywrap-manifest-types-js = pkgs.mkYarnPackage rec {
          name = "polywrap-manifest-types-js";
          version = "0.1.1";
          src = monorepo + "/packages/js/manifests/polywrap";
          inherit yarnLock;
          packageJSON = pkgs.stdenv.mkDerivation {
            name = "polywrap-manifest-types-js-package-json";
            inherit src;
            buildPhase = ''
              sed -i -e '/^  "devDependencies/a\' -e '    "@types/mustache": "4.0.1",' package.json
              sed -i -e '/^  "devDependencies/a\' -e '    "@types/semver": "7.3.8",' package.json
            '';
            installPhase = "cp package.json $out";
          };
          preConfigure = ''
            substituteInPlace tsconfig.json --replace "../../../../tsconfig" "${monorepo}/tsconfig.json"
          '';
          workspaceDependencies = [ os-js polywrap-manifest-schemas ];
          buildPhase = "yarn build";
        };
        wrap-manifest-types-js = pkgs.mkYarnPackage rec {
          name = "wrap-manifest-types-js";
          version = "0.1.1";
          src = monorepo + "/packages/js/manifests/wrap";
          inherit yarnLock;
          packageJSON = pkgs.stdenv.mkDerivation {
            name = "schema-parse-package-json";
            inherit src;
            buildPhase = ''
              sed -i -e '/^  "devDependencies/a\' -e '    "@types/mustache": "4.0.1",' package.json
              sed -i -e '/^  "devDependencies/a\' -e '    "@types/semver": "7.3.8",' package.json
            '';
            installPhase = "cp package.json $out";
          };
          preConfigure = ''
            substituteInPlace tsconfig.json --replace "../../../../tsconfig" "${monorepo}/tsconfig.json"
          '';
          workspaceDependencies = [ os-js msgpack-js wrap-manifest-schemas ];
          buildPhase = "yarn build";
        };
        schema-parse = pkgs.mkYarnPackage rec {
          name = "schema-parse";
          version = "0.1.1";
          src = monorepo + "/packages/schema/parse";
          inherit yarnLock;
          preConfigure = ''
            substituteInPlace tsconfig.json --replace "../../../tsconfig" "${monorepo}/tsconfig.json"
          '';
          workspaceDependencies = [ test-cases ];
          buildPhase = "yarn build";
        };
        schema-bind = pkgs.mkYarnPackage rec {
          name = "schema-bind";
          version = "0.1.1";
          src = monorepo + "/packages/schema/bind";
          inherit yarnLock;
          preConfigure = ''
            substituteInPlace tsconfig.json --replace "../../../tsconfig" "${monorepo}/tsconfig.json"
          '';
          workspaceDependencies = [ os-js schema-parse test-cases ];
          buildPhase = "yarn build";
        };
        schema-compose = pkgs.mkYarnPackage rec {
          name = "schema-compose";
          version = "0.1.1";
          src = monorepo + "/packages/schema/compose";
          inherit yarnLock;
          preConfigure = ''
            substituteInPlace tsconfig.json --replace "../../../tsconfig" "${monorepo}/tsconfig.json"
          '';
          workspaceDependencies = [ schema-parse test-cases ];
          buildPhase = "yarn build";
        };
        core-js = pkgs.mkYarnPackage rec {
          name = "core-js";
          version = "0.1.1";
          src = monorepo + "/packages/js/core";
          inherit yarnLock;
          packageJSON = pkgs.stdenv.mkDerivation {
            name = "core-js-package-json";
            inherit src;
            buildPhase = ''
              sed -i -e '/^  "devDependencies/a\' -e '    "@types/mustache": "4.0.1",' package.json
            '';
            installPhase = "cp package.json $out";
          };
          preConfigure = ''
            substituteInPlace tsconfig.json --replace "../../../tsconfig" "${monorepo}/tsconfig.json"
          '';
          workspaceDependencies = [ os-js tracing-js wrap-manifest-types-js ];
          buildPhase = "yarn build";
        };
        package-validation = pkgs.mkYarnPackage rec {
          name = "package-validation";
          version = "0.1.1";
          src = monorepo + "/packages/js/validation";
          inherit yarnLock;
          preConfigure = ''
            substituteInPlace tsconfig.json --replace "../../../tsconfig" "${monorepo}/tsconfig.json"
          '';
          workspaceDependencies =
            [ os-js msgpack-js schema-compose wrap-manifest-types-js ];
          buildPhase = "yarn build";
        };
        polywrap-bootstrap = pkgs.mkYarnPackage rec {
          name = "polywrap-bootstrap";
          version = "0.1.1";
          src = ./bootstrap;
        };
        polywrap-bootstrap-bin = polywrap-bootstrap
          + "/libexec/polywrap-bootstrap/node_modules/polywrap/bin/polywrap";
        ipfs-interface = pkgs.mkYarnPackage rec {
          name = "ipfs-interface";
          version = "0.1.1";
          src = monorepo + "/packages/interfaces/ipfs";
          inherit yarnLock;
          extraBuildInputs = [ pkgs.docker ];
          packageJSON = pkgs.stdenv.mkDerivation {
            name = "ipfs-interface-package-json";
            inherit src;
            buildPhase = ''
              sed -i '/^    "polywrap/d' package.json
            '';
            installPhase = "cp package.json $out";
          };
          preConfigure = ''
            substituteInPlace package.json \
              --replace "../../../dependencies/node_modules/polywrap/bin/polywrap" \
                        "${polywrap-bootstrap-bin}"
          '';
          buildPhase = "yarn build";
        };
        ipfs-interface-schema = ipfs-interface
          + "/libexec/@polywrap/ipfs-interface/deps/@polywrap/ipfs-interface/build/schema.graphql";
        logger-interface = pkgs.mkYarnPackage rec {
          name = "logger-interface";
          version = "0.1.1";
          src = monorepo + "/packages/interfaces/logger";
          inherit yarnLock;
          packageJSON = pkgs.stdenv.mkDerivation {
            name = "logger-interface-package-json";
            inherit src;
            buildPhase = ''
              sed -i '/^    "polywrap/d' package.json
            '';
            installPhase = "cp package.json $out";
          };
          extraBuildInputs = [ pkgs.docker ];
          preConfigure = ''
            substituteInPlace package.json \
              --replace "../../../dependencies/node_modules/polywrap/bin/polywrap" \
                        "${polywrap-bootstrap-bin}"
          '';
          buildPhase = "yarn build";
        };
        logger-interface-schema = logger-interface
          + "/libexec/@polywrap/logger-interface/deps/@polywrap/logger-interface/src/schema.graphql";
        file-system-interface = pkgs.mkYarnPackage rec {
          name = "file-system-interface";
          version = "0.1.1";
          src = monorepo + "/packages/interfaces/file-system";
          inherit yarnLock;
          packageJSON = pkgs.stdenv.mkDerivation {
            name = "file-system-interface-package-json";
            inherit src;
            buildPhase = ''
              sed -i '/^    "polywrap/d' package.json
            '';
            installPhase = "cp package.json $out";
          };
          extraBuildInputs = [ pkgs.docker ];
          preConfigure = ''
            substituteInPlace package.json \
              --replace "../../../dependencies/node_modules/polywrap/bin/polywrap" \
                        "${polywrap-bootstrap-bin}"
          '';
          buildPhase = "yarn build";
        };
        file-system-interface-schema = file-system-interface
          + "/libexec/@polywrap/file-system-interface/deps/@polywrap/file-system-interface/build/schema.graphql";
        uri-resolver-interface = pkgs.mkYarnPackage rec {
          name = "uri-resolver-interface";
          version = "0.1.1";
          src = monorepo + "/packages/interfaces/uri-resolver";
          inherit yarnLock;
          packageJSON = pkgs.stdenv.mkDerivation {
            name = "uri-resolver-interface-package-json";
            inherit src;
            buildPhase = ''
              sed -i '/^    "polywrap/d' package.json
            '';
            installPhase = "cp package.json $out";
          };
          extraBuildInputs = [ pkgs.docker ];
          preConfigure = ''
            substituteInPlace package.json \
              --replace "../../../dependencies/node_modules/polywrap/bin/polywrap" \
                        "${polywrap-bootstrap-bin}"
          '';
          buildPhase = "yarn build";
        };
        uri-resolver-interface-schema = uri-resolver-interface
          + "/libexec/@polywrap/uri-resolver-interface/deps/@polywrap/uri-resolver-interface/src/schema.graphql";
        ipfs-plugin-js = pkgs.mkYarnPackage rec {
          name = "ipfs-plugin-js";
          version = "0.1.1";
          src = monorepo + "/packages/js/plugins/ipfs";
          inherit yarnLock;
          packageJSON = pkgs.stdenv.mkDerivation {
            name = "fs-plugin-js-package-json";
            inherit src;
            buildPhase = ''
              sed -i '/^    "@polywrap\/test-env-js/d' package.json
            '';
            installPhase = "cp package.json $out";
          };
          preConfigure = ''
            substituteInPlace polywrap.plugin.yaml \
              --replace "../../../interfaces/ipfs/build/schema.graphql" \
                      "${ipfs-interface-schema}"
            substituteInPlace package.json \
              --replace "../../../../dependencies/node_modules/polywrap/bin/polywrap" \
                        "${polywrap-bootstrap-bin}"
            substituteInPlace tsconfig.json \
              --replace "../../../../tsconfig" "${monorepo}/tsconfig.json"
          '';
          workspaceDependencies = [ core-js ];
          buildPhase = "yarn build";
        };
        ethereum-plugin-js = pkgs.mkYarnPackage rec {
          name = "ethereum-plugin-js";
          version = "0.1.1";
          src = monorepo + "/packages/js/plugins/ethereum";
          inherit yarnLock;
          packageJSON = pkgs.stdenv.mkDerivation {
            name = "fs-plugin-js-package-json";
            inherit src;
            buildPhase = ''
              sed -i '/^    "@polywrap\/client-js/d' package.json
              sed -i '/^    "@polywrap\/ens-resolver-plugin-js/d' package.json
              sed -i '/^    "@polywrap\/ipfs-plugin-js/d' package.json
              sed -i '/^    "@polywrap\/test-env-js/d' package.json
            '';
            installPhase = "cp package.json $out";
          };
          preConfigure = ''
            substituteInPlace package.json \
              --replace "../../../../dependencies/node_modules/polywrap/bin/polywrap" \
                        "${polywrap-bootstrap-bin}"
            substituteInPlace tsconfig.json \
              --replace "../../../../tsconfig" "${monorepo}/tsconfig.json"
          '';
          workspaceDependencies = [ core-js ];
          buildPhase = "yarn build";
        };
        fs-plugin-js = pkgs.mkYarnPackage rec {
          name = "fs-plugin-js";
          version = "0.1.1";
          src = monorepo + "/packages/js/plugins/file-system";
          inherit yarnLock;
          packageJSON = pkgs.stdenv.mkDerivation {
            name = "fs-plugin-js-package-json";
            inherit src;
            buildPhase = ''
              sed -i '/^    "@polywrap\/client-js/d' package.json
              sed -i '/^    "@polywrap\/ens-resolver-plugin-js/d' package.json
              sed -i '/^    "@polywrap\/ethereum-plugin-js/d' package.json
              sed -i '/^    "@polywrap\/ipfs-plugin-js/d' package.json
              sed -i '/^    "@polywrap\/test-env-js/d' package.json
            '';
            installPhase = "cp package.json $out";
          };
          preConfigure = ''
            substituteInPlace polywrap.plugin.yaml \
              --replace "../../../interfaces/file-system/build/schema.graphql" \
                        "${file-system-interface-schema}"
            substituteInPlace package.json \
              --replace "../../../../dependencies/node_modules/polywrap/bin/polywrap" \
                        "${polywrap-bootstrap-bin}"
            substituteInPlace tsconfig.json \
              --replace "../../../../tsconfig" "${monorepo}/tsconfig.json"
          '';
          workspaceDependencies = [ core-js test-cases ];
          buildPhase = "yarn build";
        };
        http-plugin-js = pkgs.mkYarnPackage rec {
          name = "http-plugin-js";
          version = "0.1.1";
          src = monorepo + "/packages/js/plugins/http";
          inherit yarnLock;
          packageJSON = pkgs.stdenv.mkDerivation {
            name = "http-plugin-js-package-json";
            inherit src;
            buildPhase = ''
              sed -i '/^    "@polywrap\/client-js/d' package.json
              sed -i '/^    "@polywrap\/ens-resolver-plugin-js/d' package.json
              sed -i '/^    "@polywrap\/ipfs-plugin-js/d' package.json
              sed -i '/^    "@polywrap\/test-env-js/d' package.json
            '';
            installPhase = "cp package.json $out";
          };
          preConfigure = ''
            substituteInPlace package.json \
              --replace "../../../../dependencies/node_modules/polywrap/bin/polywrap" \
                        "${polywrap-bootstrap-bin}"
            substituteInPlace tsconfig.json \
              --replace "../../../../tsconfig" "${monorepo}/tsconfig.json"
          '';
          workspaceDependencies = [ core-js ];
          buildPhase = "yarn build";
        };
        graph-node-plugin-js = pkgs.mkYarnPackage rec {
          name = "graph-node-plugin-js";
          version = "0.1.1";
          src = monorepo + "/packages/js/plugins/graph-node";
          inherit yarnLock;
          packageJSON = pkgs.stdenv.mkDerivation {
            name = "graph-node-plugin-js-package-json";
            inherit src;
            buildPhase = ''
              sed -i '/^    "@polywrap\/client-js/d' package.json
            '';
            installPhase = "cp package.json $out";
          };
          preConfigure = ''
            substituteInPlace package.json \
              --replace "../../../../dependencies/node_modules/polywrap/bin/polywrap" \
                        "${polywrap-bootstrap-bin}"
            substituteInPlace tsconfig.json \
              --replace "../../../../tsconfig" "${monorepo}/tsconfig.json"
          '';
          workspaceDependencies = [ core-js http-plugin-js ];
          buildPhase = "yarn build";
        };
        logger-plugin-js = pkgs.mkYarnPackage rec {
          name = "logger-plugin-js";
          version = "0.1.1";
          src = monorepo + "/packages/js/plugins/logger";
          inherit yarnLock;
          packageJSON = pkgs.stdenv.mkDerivation {
            name = "logger-plugin-js-package-json";
            inherit src;
            buildPhase = ''
              sed -i '/^    "@polywrap\/client-js/d' package.json
            '';
            installPhase = "cp package.json $out";
          };
          preConfigure = ''
            substituteInPlace polywrap.plugin.yaml \
              --replace "../../../interfaces/logger/src/schema.graphql" \
                        "${logger-interface-schema}"
            substituteInPlace package.json \
              --replace "../../../../dependencies/node_modules/polywrap/bin/polywrap" \
                        "${polywrap-bootstrap-bin}"
            substituteInPlace tsconfig.json \
              --replace "../../../../tsconfig" "${monorepo}/tsconfig.json"
          '';
          workspaceDependencies = [ core-js ];
          buildPhase = "yarn build";
        };
        sha3-plugin-js = pkgs.mkYarnPackage rec {
          name = "sha3-plugin-js";
          version = "0.1.1";
          src = monorepo + "/packages/js/plugins/sha3";
          inherit yarnLock;
          preConfigure = ''
            substituteInPlace package.json \
              --replace "../../../../dependencies/node_modules/polywrap/bin/polywrap" \
                        "${polywrap-bootstrap-bin}"
            substituteInPlace tsconfig.json \
              --replace "../../../../tsconfig" "${monorepo}/tsconfig.json"
          '';
          workspaceDependencies = [ core-js ];
          buildPhase = "yarn build";
        };
        uts46-plugin-js = pkgs.mkYarnPackage rec {
          name = "uts46-plugin-js";
          version = "0.1.1";
          src = monorepo + "/packages/js/plugins/uts46";
          inherit yarnLock;
          preConfigure = ''
            substituteInPlace package.json \
              --replace "../../../../dependencies/node_modules/polywrap/bin/polywrap" \
                        "${polywrap-bootstrap-bin}"
            substituteInPlace tsconfig.json \
              --replace "../../../../tsconfig" "${monorepo}/tsconfig.json"
          '';
          workspaceDependencies = [ core-js ];
          buildPhase = "yarn build";
        };
        ens-resolver-plugin-js = pkgs.mkYarnPackage rec {
          name = "ens-resolver-plugin-js";
          version = "0.1.1";
          src = monorepo + "/packages/js/plugins/uri-resolvers/ens-resolver";
          inherit yarnLock;
          preConfigure = ''
            substituteInPlace polywrap.plugin.yaml \
              --replace "../../../../interfaces/uri-resolver/src/schema.graphql" \
                        "${uri-resolver-interface-schema}"
            substituteInPlace package.json \
              --replace "../../../../../dependencies/node_modules/polywrap/bin/polywrap" \
                        "${polywrap-bootstrap-bin}"
            substituteInPlace tsconfig.json \
              --replace "../../../../../tsconfig" "${monorepo}/tsconfig.json"
          '';
          workspaceDependencies = [ core-js ];
          buildPhase = "yarn build";
        };
        ipfs-resolver-plugin-js = pkgs.mkYarnPackage rec {
          name = "ipfs-resolver-plugin-js";
          version = "0.1.1";
          src = monorepo + "/packages/js/plugins/uri-resolvers/ipfs-resolver";
          inherit yarnLock;
          preConfigure = ''
            substituteInPlace polywrap.plugin.yaml \
              --replace "../../../../interfaces/uri-resolver/src/schema.graphql" \
                        "${uri-resolver-interface-schema}"
            substituteInPlace polywrap.plugin.yaml \
              --replace "../../../../interfaces/ipfs/build/schema.graphql" \
                      "${ipfs-interface-schema}"
            substituteInPlace package.json \
              --replace "../../../../../dependencies/node_modules/polywrap/bin/polywrap" \
                        "${polywrap-bootstrap-bin}"
            substituteInPlace tsconfig.json \
              --replace "../../../../../tsconfig" "${monorepo}/tsconfig.json"
          '';
          workspaceDependencies = [ core-js ];
          buildPhase = "yarn build";
        };
        fs-resolver-plugin-js = pkgs.mkYarnPackage rec {
          name = "fs-resolver-plugin-js";
          version = "0.1.1";
          src = monorepo
            + "/packages/js/plugins/uri-resolvers/file-system-resolver";
          inherit yarnLock;
          packageJSON = pkgs.stdenv.mkDerivation {
            name = "fs-resolver-plugin-js-package-json";
            inherit src;
            buildPhase = ''
              sed -i '/^    "polywrap/d' package.json
            '';
            installPhase = "cp package.json $out";
          };
          preConfigure = ''
            substituteInPlace polywrap.plugin.yaml \
              --replace "../../../../interfaces/uri-resolver/src/schema.graphql" \
                        "${uri-resolver-interface-schema}"
            substituteInPlace polywrap.plugin.yaml \
              --replace "../../../../interfaces/file-system/build/schema.graphql" \
                        "${file-system-interface-schema}"
            substituteInPlace package.json \
              --replace "../../../../../dependencies/node_modules/polywrap/bin/polywrap" \
                        "${polywrap-bootstrap-bin}"
            substituteInPlace tsconfig.json \
              --replace "../../../../../tsconfig" "${monorepo}/tsconfig.json"
          '';
          workspaceDependencies = [ core-js ];
          buildPhase = "yarn build";
        };
        client-js = pkgs.mkYarnPackage rec {
          name = "client-js";
          version = "0.1.1";
          src = monorepo + "/packages/js/client";
          inherit yarnLock;
          packageJSON = pkgs.stdenv.mkDerivation {
            name = "client-js-package-json";
            inherit src;
            buildPhase = ''
              sed -i '/^    "@polywrap\/test-env-js/d' package.json
              sed -i '/^    "polywrap/d' package.json
            '';
            installPhase = "cp package.json $out";
          };
          preConfigure = ''
            substituteInPlace tsconfig.json \
              --replace "../../../tsconfig" "${monorepo}/tsconfig.json"
          '';
          workspaceDependencies = [
            asyncify-js
            core-js
            ens-resolver-plugin-js
            ethereum-plugin-js
            fs-plugin-js
            fs-resolver-plugin-js
            graph-node-plugin-js
            http-plugin-js
            ipfs-plugin-js
            ipfs-resolver-plugin-js
            logger-plugin-js
            msgpack-js
            os-js
            schema-parse
            sha3-plugin-js
            test-cases
            tracing-js
            uts46-plugin-js
            wrap-manifest-types-js
          ];
          buildPhase = "yarn build";
        };
        react = pkgs.mkYarnPackage rec {
          name = "react";
          version = "0.1.1";
          src = monorepo + "/packages/js/react";
          inherit yarnLock;
          packageJSON = pkgs.stdenv.mkDerivation {
            name = "react-package-json";
            inherit src;
            buildPhase = ''
              sed -i '/^    "@polywrap\/test-env-js/d' package.json
              sed -i '/^    "polywrap/d' package.json
            '';
            installPhase = "cp package.json $out";
          };
          preConfigure = ''
            substituteInPlace tsconfig.json \
              --replace "../../../tsconfig" "${monorepo}/tsconfig.json"
          '';
          workspaceDependencies = [
            client-js
            core-js
            ens-resolver-plugin-js
            ethereum-plugin-js
            ipfs-plugin-js
            test-cases
            tracing-js
          ];
          buildPhase = "yarn build";
        };
        test-env-js = pkgs.mkYarnPackage rec {
          name = "test-env-js";
          version = "0.1.1";
          src = monorepo + "/packages/js/test-env";
          inherit yarnLock;
          packageJSON = pkgs.stdenv.mkDerivation {
            name = "test-env-js-package-json";
            inherit src;
            buildPhase = ''
              sed -i -e '/^  "devDependencies/a\' -e '    "@types/js-yaml": "3.11.1",' package.json
            '';
            installPhase = "cp package.json $out";
          };
          preConfigure = ''
            substituteInPlace tsconfig.json \
              --replace "../../../tsconfig" "${monorepo}/tsconfig.json"
          '';
          workspaceDependencies =
            [ client-js core-js ethereum-plugin-js polywrap-manifest-types-js ];
          buildPhase = "yarn build";
        };
        polywrap = pkgs.mkYarnPackage rec {
          name = "polywrap";
          version = "0.1.1";
          src = monorepo + "/packages/cli";
          inherit yarnLock;
          packageJSON = pkgs.stdenv.mkDerivation {
            name = "polywrap-package-json";
            inherit src;
            buildPhase = ''
              sed -i -e '/^  "devDependencies/a\' -e '    "@types/js-yaml": "3.11.1",' package.json
              sed -i -e '/^  "devDependencies/a\' -e '    "@types/mustache": "4.0.1",' package.json
            '';
            installPhase = "cp package.json $out";
          };
          preConfigure = ''
            substituteInPlace tsconfig.json \
              --replace "../../tsconfig" "${monorepo}/tsconfig.json"
          '';
          workspaceDependencies = [
            asyncify-js
            client-js
            core-js
            ens-resolver-plugin-js
            ethereum-plugin-js
            ipfs-plugin-js
            msgpack-js
            os-js
            polywrap-manifest-types-js
            schema-bind
            schema-compose
            schema-parse
            test-env-js
            wrap-manifest-types-js
          ];
          buildPhase = "yarn build";
        };
        # templates-app-typescript-node = pkgs.mkYarnPackage rec {
        #   name = "templates-app-typescript-node";
        #   version = "0.1.1";
        #   src = monorepo + "/packages/templates/app/typescript-node";
        #   inherit yarnLock;
        #   workspaceDependencies = [ client-js polywrap ];
        #   buildPhase = "yarn build";
        # };
        # templates-app-typescript-react = pkgs.mkYarnPackage rec {
        #   name = "templates-app-typescript-react";
        #   version = "0.1.1";
        #   src = monorepo + "/packages/templates/app/typescript-react";
        #   inherit yarnLock;
        #   workspaceDependencies = [ client-js react polywrap ];
        #   buildPhase = "yarn build";
        # };
        # templates-plugin-typescript = pkgs.mkYarnPackage rec {
        #   name = "templates-plugin-typescript";
        #   version = "0.1.1";
        #   src = monorepo + "/packages/templates/plugin/typescript";
        #   inherit yarnLock;
        #   workspaceDependencies = [ core-js client-js polywrap ];
        #   buildPhase = "yarn build";
        # };
        # templates-wrapper-interface = pkgs.mkYarnPackage rec {
        #   name = "templates-wrapper-interface";
        #   version = "0.1.1";
        #   src = monorepo + "/packages/templates/wasm/interface";
        #   inherit yarnLock;
        #   workspaceDependencies = [ polywrap ];
        #   buildPhase = "yarn build";
        # };
        # templates-wasm-as = pkgs.mkYarnPackage rec {
        #   name = "templates-wasm-as";
        #   version = "0.1.1";
        #   src = monorepo + "/packages/templates/wasm/assemblyscript";
        #   inherit yarnLock;
        #   workspaceDependencies = [ polywrap ];
        #   buildPhase = "yarn build";
        # };
        # polywrap-wasm-rs = pkgs.rustPlatform.buildRustPackage rec {
        #   pname = "polywrap-wasm-rs";
        #   version = "0.1.1";
        #   src = monorepo + "/wasm/rs";
        #   meta = with pkgs.stdenv.lib; {
        #     description = "";
        #     homepage = "";
        #     license = licenses.mit;
        #     maintainers = [ ];
        #   };
        # };
        # template-wasm-rs = pkgs.rustPlatform.buildRustPackage rec {
        #   pname = "template-wasm-rs";
        #   version = "0.1.1";
        #   src = monorepo + "/templates/wasm/rust";
        #   meta = with pkgs.stdenv.lib; {
        #     description = "";
        #     homepage = "";
        #     license = licenses.mit;
        #     maintainers = [ ];
        #   };
        # };
        log = { };
        consoleLog = pkgs.stdenv.mkDerivation {
          name = "console-log" + builtins.trace "${builtins.toJSON log}" "";
          src = pkgs.hello;
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

            cargo2nix
          ];
        };
        packages = {
          inherit msgpack-js asyncify-js tracing-js os-js test-cases wasm-as
            polywrap-manifest-schemas polywrap-manifest-types-js
            wrap-manifest-types-js wrap-manifest-schemas schema-parse
            schema-bind schema-compose core-js package-validation
            polywrap-bootstrap ipfs-interface logger-interface
            file-system-interface uri-resolver-interface ipfs-plugin-js
            ethereum-plugin-js fs-plugin-js http-plugin-js graph-node-plugin-js
            logger-plugin-js sha3-plugin-js uts46-plugin-js
            ens-resolver-plugin-js ipfs-resolver-plugin-js fs-resolver-plugin-js
            client-js react test-env-js polywrap
            # templates-app-typescript-node
            # templates-app-typescript-react templates-plugin-typescript
            # templates-wrapper-interface templates-wasm-as
            # template-wasm-rs # polywrap-wasm-rs
          ;
        };
      });
}

