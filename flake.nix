{
  description = "A helper for building Typst document and importing non-Universe packages";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      system = "x86_64-linux";

      overlay = import ./.;

      pkgs = import nixpkgs {
        inherit system;
        overlays = [ overlay ];
      };
    in
    {
      overlays = {
        default = overlay;
        buildTypst = overlay;
      };

      checks.x86_64-linux = builtins.removeAttrs (pkgs.callPackage ./tests { }) [
        "override"
        "overrideDerivation"
      ];

      templates.default = {
        path = ./template;
        description = "A basic template using Press";
      };

      formatter.${system} = pkgs.nixfmt-tree;

      devShells.${system}.default = pkgs.mkShell {
        stdenv = pkgs.stdenvNoCC;
        packages =
          let
            p = pkgs;
          in
          [
            p.nil
            p.nixfmt-tree
            p.typstyle
          ];
      };
    };
}
