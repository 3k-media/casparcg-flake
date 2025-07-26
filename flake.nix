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
        {
          overlayAttrs = {
              inherit (config.packages) casparcg-server;
          };
          packages.casparcg-cef = pkgs.cef-binary.overrideAttrs (oldAttrs: {
            version = "131.4.1";
            __intentionallyOverridingVersion = true;
            gitRevision = "437feba";
            chromiumVersion = "131.0.6778.265";
            srcHash = { x86_64-linux = "sha256-vTBHBJWFwbebzqGFGHEYH0uenLygWoOJW6kLcFSnQIM="; }.${system};
            installPhase = ''
                runHook preInstall

                mkdir -p $out/lib
                cp libcef_dll_wrapper/libcef_dll_wrapper.a $out/lib/
                cp ../${oldAttrs.buildType}/libcef.so $out/lib/
                cp ../${oldAttrs.buildType}/libEGL.so $out/lib/
                cp ../${oldAttrs.buildType}/libGLESv2.so $out/lib/
                cp ../${oldAttrs.buildType}/libvk_swiftshader.so $out/lib/
                cp ../${oldAttrs.buildType}/libvulkan.so.1 $out/lib/
                cp ../${oldAttrs.buildType}/chrome-sandbox $out/lib/
                cp ../${oldAttrs.buildType}/*.bin ../${oldAttrs.buildType}/*.json $out/lib/
                cp -r ../Resources/* $out/lib/
                cp -r ../include $out/

                runHook postInstall
            '';
          });
          packages.default = config.packages.casparcg-server;
          packages.casparcg-server = pkgs.stdenv.mkDerivation rec {
            pname = "casparcg-server";
            version = "2.5.0";
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
              autoPatchelfHook
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
            ] ++ [ config.packages.casparcg-cef ];

            runtimeDependencies = with pkgs; [
                ndi-6
                blackmagic-desktop-video
            ];

            cmakeFlags = [
              "-DUSE_STATIC_BOOST=0"
              "-DUSE_SYSTEM_FFMPEG=1"
              "-DENABLE_HTML=1"
              "-DUSE_SYSTEM_CEF=1"
              "-DCEF_ROOT=${config.packages.casparcg-cef}"
            ];

            patches = [
              ./cmake-cef.patch
            ];
          };
        };
      });
}
