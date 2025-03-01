{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    universe = {
      url = "github:typst/packages/main";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    universe,
  }: let
    overlay = (import ./.) universe;
  in {
    overlays = {
      default = overlay;
      buildTypst = overlay;
    };

    devShells = let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
      };
    in {
      ${system}.default = pkgs.mkShell {
        stdenv = pkgs.stdenvNoCC;
        packages = let
          p = pkgs;
        in [
          p.nil
          p.alejandra
        ];
      };
    };
  };
}
