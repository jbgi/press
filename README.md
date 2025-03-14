# Press
![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/RossSmyth/press/.github%2Fworkflows%2Fmain.yml?branch=main&style=for-the-badge)

A library for building Typst documents with Nix. Goals:

1. Hermetic document building
2. Support non-Typst Universe packages

## Status

Usable. Needs a few more things before I'd say it's "complete," but it does build documents.

## Usage

Just import the overlay.

```nix
pkgs = import nixpkgs {
  overlays = [ (import press) ];
};

...
document = pkgs.buildTypstDocument {
  name = "myDoc";
  src = ./.;
};
```


