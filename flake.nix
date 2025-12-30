{
  description = "Blog flake";
  inputs.nixpkgs.url = "nixpkgs/nixos-25.11";

  outputs = {nixpkgs, ...}: let
    supportedSystems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    forEachSupportedSystem = f:
      nixpkgs.lib.genAttrs supportedSystems (system:
        f {
          pkgs = import nixpkgs {inherit system;};
        });
  in {
    devShells = forEachSupportedSystem ({pkgs}: {
      default = pkgs.mkShell {
        packages = with pkgs; [
          pandoc
          nushell
          caddy
        ];
      };
    });
    packages = forEachSupportedSystem ({pkgs}: {
      default = let
        builder = pkgs.writeScriptBin "build.nu" "use ${./nurfile} *; nur build";
      in
        pkgs.stdenv.mkDerivation {
          pname = "website-pages";
          version = "1.0";
          src = ./.;
          nativeBuildInputs = with pkgs; [
            nushell
            pandoc
          ];
          buildPhase = ''
            runHook preBuild
            nu ${builder}/bin/build.nu
            runHook postBuild
          '';
          installPhase = ''
            runHook preInstall
            mkdir -p $out/pages
            cp -r pages/* $out/pages/
            runHook postInstall
          '';
        };
    });
  };
}
