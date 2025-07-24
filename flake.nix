{
  description = "CasparCG Server";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      allSystems = [
        "x86_64-linux"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs allSystems (system: f rec {
        pkgs = import nixpkgs { inherit system; };
        cef = pkgs.libcef.overrideAttrs (oldAttrs: {
          version = "131.4.1";
          __intentionallyOverridingVersion = true;
          gitRevision = "437feba";
          chromiumVersion = "131.0.6778.265";
          srcHash = { x86_64-linux = "sha256-vTBHBJWFwbebzqGFGHEYH0uenLygWoOJW6kLcFSnQIM="; }.${system};
        });
      });
    in
    {
      debug = forAllSystems ({ cef, ... }: {
        cefPath = cef.outPath;
      });
      packages = forAllSystems ({ pkgs, cef }: {
        default = pkgs.stdenv.mkDerivation rec {
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

          patches = [
             ./cmake-cef.patch
          ];
        };
      });
    };
}
       
