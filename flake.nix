{
  description = "CasparCG Server";
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (top@{ config, withSystem, moduleWithSystem, ... }: {
      imports = [
        flake-parts.flakeModules.easyOverlay
      ];
      systems = ["x86_64-linux"];
      perSystem = { system, config, pkgs, ... }:
        let
          cef = pkgs.libcef.overrideAttrs (oldAttrs: {
            version = "131.4.1";
            __intentionallyOverridingVersion = true;
            gitRevision = "437feba";
            chromiumVersion = "131.0.6778.265";
            srcHash = { x86_64-linux = "sha256-vTBHBJWFwbebzqGFGHEYH0uenLygWoOJW6kLcFSnQIM="; }.${system};
          });
        in
        {
          packages.default = config.packages.casparcg-server;
          packages.casparcg-server = pkgs.stdenv.mkDerivation rec {
            pname = "casparcg-server";
            version = "2.4.3-stable";
            src = pkgs.fetchFromGitHub {
              owner = "CasparCG";
              repo = "server";
              rev = "ffd41657cae9283df14a3cfa5e5b3c1153e26553";
              hash = "sha256-/bBd8J+joxETjcemoxpW9UYm4ozJj0dzgLGQFvNK39U=";
            };

            sourceRoot = "${src.name}/src";

            nativeBuildInputs = with pkgs; [
              cmake
              ninja
              pkg-config
            ];

            buildInputs = with pkgs; [
              boost
              ffmpeg
              libGL
              glew
              tbb_2022
              openal
              sfml_2
              xorg.libX11
              simde
              zlib
              icu
            ] ++ [ cef ];

            cmakeFlags = [
              "-DUSE_STATIC_BOOST=0"
              "-DUSE_SYSTEM_FFMPEG=1"
              "-DENABLE_HTML=1"
              "-DUSE_SYSTEM_CEF=1"
              "-DCEF_ROOT=${cef}"
            ];

            postInstall = ''
              mkdir -p $out/bin/Resources/
              cp -r ${cef}/share/cef/* $out/bin/Resources/
            '';

            patches = [
              ./cmake-cef.patch
            ];
          };
        };
        flake.nixosConfigurations.test = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            top.self.nixosModules.default
            ./test-config.nix
          ];
        };
        flake.nixosModules.default = {config, lib, pkgs, ...}:
          with lib;
          let
            cfg = config.services.casparcg-server;
          in
          {
            options.services.casparcg-server = {
              enable = mkEnableOption "Enable CasparCG Server";
              package = mkOption {
                type = types.package;
                default = top.self.packages.${pkgs.system}.casparcg-server;
                description = "The CasparCG Server package to use.";
              };
              config = mkOption {
                type = types.str;
                default = "";
                description = "Configuration for CasparCG Server.";
              };
            };
            config = mkIf cfg.enable {
              systemd.services.casparcg-server = {
                description = "CasparCG Server";
                after = [ "network.target" ];
                wantedBy = [ "multi-user.target" ];
                environment = {
                  EGL_PLATFORM = "surfaceless";
                };
                serviceConfig = {
                  ExecStart = "${cfg.package}/bin/casparcg /etc/casparcg.config";
                  Restart = "always";
                  RestartSec = 5;
                };
              };
              environment.etc."casparcg.config".text = cfg.config;
            };
          };
      });
}
