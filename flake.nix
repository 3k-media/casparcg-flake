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
              inherit (config.packages) casparcg-server casparcg-media-scanner;
          };
          packages.casparcg-cef = pkgs.cef-binary.override {};
          #   installPhase = ''
          #       runHook preInstall

          #       mkdir -p $out/lib
          #       cp build/libcef_dll_wrapper/libcef_dll_wrapper.a $out/lib/
          #       cp Release/libcef.so $out/lib/
          #       cp Release/libEGL.so $out/lib/
          #       cp Release/libGLESv2.so $out/lib/
          #       cp Release/libvk_swiftshader.so $out/lib/
          #       cp Release/libvulkan.so.1 $out/lib/
          #       cp Release/chrome-sandbox $out/lib/
          #       cp Release/*.bin Release/*.json $out/lib/
          #       cp -r Resources/* $out/lib/
          #       cp -r include $out/

          #       runHook postInstall
          #   '';
          # });
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
              ffmpeg_7
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
              "-DUSE_SYSTEM_CEF=0"
              "-DCEF_ROOT=${config.packages.casparcg-cef}"
            ];

            patches = [
              ./cmake-cef.patch
            ];
          };
          packages.casparcg-media-scanner = pkgs.stdenv.mkDerivation (finalAttrs: {
            pname = "casparcg-media-scanner";
            version = "1.3.4";
            src = pkgs.fetchFromGitHub {
              owner = "CasparCG";
              repo = "media-scanner";
              rev = "2208c7bd72d61e5a33176504a0dae8df24ddf18d";
              hash = "sha256-M+bwU/nV7oZpR+WiYytum8IDAyn+AfqYtshT2dukr20=";
            };

            nativeBuildInputs = with pkgs; [
              makeBinaryWrapper
              yarn-berry_4
              yarn-berry_4.yarnBerryConfigHook
            ];

            buildPhase = ''
              runHook preBuild
              yarn run build:ts
              runHook postBuild
            '';

            installPhase = ''
              runHook preInstall

              mkdir -p $out/share/casparcg-media-scanner/dist
              cp -r dist/*.js $out/share/casparcg-media-scanner/dist
              cp package.json $out/share/casparcg-media-scanner
              cp -r node_modules $out/share/casparcg-media-scanner
              makeWrapper ${pkgs.nodejs}/bin/node $out/bin/casparcg-media-scanner \
                --add-flags $out/share/casparcg-media-scanner/dist/index.js \
                --add-flags "--paths.ffmpeg=${pkgs.ffmpeg}/bin/ffmpeg" \
                --add-flags "--paths.ffprobe=${pkgs.ffmpeg}/bin/ffprobe" \
                --set NODE_ENV production \
                --set NODE_PATH "$out/share/casparcg-media-scanner/node_modules"

              runHook postInstall
            '';

            offlineCache = pkgs.yarn-berry_4.fetchYarnBerryDeps {
              inherit (finalAttrs) src;
              hash = "sha256-xeCABqD3laTeaTrG+pxL0ENRFTu8Gj/nW8ZvdB6ZSmQ=";
            };
          });
        };
      });
}
