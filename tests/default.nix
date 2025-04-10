{
  buildTypstDocument,
  fetchFromGitHub,
  fira-code,
  inconsolata,
  ripgrep,
}:
let
  note-me = fetchTree {
    type = "github";
    narHash = "sha256-Bpmdt59Tt4DNBg8G435xccH/W3aYSK+EuaU2ph2uYTY=";
    owner = "FlandiaYingman";
    repo = "note-me";
    rev = "03310b70607e13bdaf6928a6a9df1962af1005ff";
  };

  note-meGh = fetchFromGitHub {
    inherit (note-me) rev;
    owner = "FlandiaYingman";
    repo = "note-me";
    hash = "sha256-Bpmdt59Tt4DNBg8G435xccH/W3aYSK+EuaU2ph2uYTY=";
  };

  mkTest =
    { name, ... }@args:
    buildTypstDocument (
      self:
      (
        args
        // {
          inherit name;
          src = ./documents;
          file = args.file or (self.name + ".typ");
        }
      )
    );
in
{
  basic = mkTest {
    name = "basic";
    typstUniverse = false;
  };

  imports = mkTest {
    name = "import";
    file = "import.typ";
  };

  fonts = mkTest {
    name = "fonts";
    fonts = [
      fira-code
      inconsolata
    ];

    nativeCheckInputs = [
      ripgrep
    ];
    doCheck = true;
    checkPhase = ''
      set -eu
      rg --binary "BaseFont [^\.]*FiraCode" $out
      rg --binary "BaseFont [^\.]*Inconsolata" $out
    '';
  };

  patch = mkTest {
    name = "patch";
    patches = [
      ./patch.patch
    ];
  };

  patchUni = mkTest {
    name = "patchUni";
    universePatches = [
      ./universe.patch
    ];
  };

  html = mkTest {
    name = "html";
    format = "html";
  };

  gitImport = mkTest {
    name = "gitImport";
    extraPackages = {
      local = [ note-me ];
    };
  };

  gitImportList = mkTest {
    name = "gitImport";
    extraPackages = [ note-me ];
  };

  gitImportString = mkTest {
    name = "gitImport";
    extraPackages = "${note-me}";
  };

  gitImportDrv = mkTest {
    name = "gitImport";
    extraPackages = note-me;
  };

  gitImportAttrStr = mkTest {
    name = "gitImport";
    extraPackages = {
      local = "${note-me}";
    };
  };

  gitImportAttrDrv = mkTest {
    name = "gitImport";
    extraPackages = {
      local = note-me;
    };
  };

  githubFetch = mkTest {
    name = "gitHubImport";
    file = "gitImport.typ";
    extraPackages = note-meGh;
  };
}
