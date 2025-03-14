{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    press = {
      url = "github:RossSmyth/press";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Put your non-Universe packages in the input section
    # Declare them to not be a flake.
    unify = {
      url = "github:ChHecker/unify";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    press,
    unify,
  }: let
    system = "x86_64-linux";

    pkgs = import nixpkgs {
      inherit system;
      overlays = [press.overlays.default];
    };
  in {
    packages.${system}.default = pkgs.buildTypstDocument {
      # [Optional] The name of the derivation
      # Default: ${pname}-${version}
      name = "example";
      # Source directory
      src = ./.;
      # [Optional] The entry-point to the document, default is "main.typ"
      # This is relative to the directory input above.
      # Default: "main.typ"
      path = "main.typ";
      # [Optional] Whether to pull in Typst Universe or not (it is large!)
      # Default: true
      universe = true;
      # [Optional] Any non-universe packages. The attribute key is the namespace.
      # The package must have a typst.toml file in its root.
      # Default: {}
      extraPackages = {local = [unify];};
      # [Optional] The format to output
      # Default: "pdf"
      format = "pdf";
    };
  };
}
