{
  description = "Hugo flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
  let 
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages."${system}";
  in {
    devShells."${system}".default = pkgs.mkShell {
      nativeBuildInputs = with pkgs; [
        hugo
      ];
    };
  };
}
