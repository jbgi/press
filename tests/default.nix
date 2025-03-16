{
  buildTypstDocument,
  fetchFromGitHub,
  fira-code,
  inconsolata,
}: let
  note-me = fetchFromGitHub {
    owner = "FlandiaYingman";
    repo = "note-me";
    rev = "03310b70607e13bdaf6928a6a9df1962af1005ff";
    hash = "sha256-Bpmdt59Tt4DNBg8G435xccH/W3aYSK+EuaU2ph2uYTY=";
  };
in {
  basic = buildTypstDocument (self: {
    name = "basic";
    src = ./documents;
    typstUniverse = false;
    file = "basic.typ";
  });

  imports = buildTypstDocument (self: {
    name = "import";
    src = ./documents;
    file = "import.typ";
  });

  fonts = buildTypstDocument (self: {
    name = "fonts";
    src = ./documents;
    file = "fonts.typ";
    fonts = [
      fira-code
      inconsolata
    ];
  });

  patch = buildTypstDocument (self: {
    name = "patch";
    src = ./documents;
    file = "patch.typ";
    typstPatches = [
      ./patch.patch
    ];
  });

  patchUni = buildTypstDocument (self: {
    name = "patchUni";
    src = ./documents;
    file = "patchUni.typ";
    universePatches = [
      ./universe.patch
    ];
  });

  html = buildTypstDocument (self: {
    name = "html";
    src = ./documents;
    file = "html.typ";
    format = "html";
  });

  gitImport = buildTypstDocument (self: {
    name = "gitImport";
    src = ./documents;
    file = "gitImport.typ";
    extraPackages = {
      local = [note-me];
    };
  });

  gitImportList = buildTypstDocument (self: {
    name = "gitImport";
    src = ./documents;
    file = "gitImport.typ";
    extraPackages = [note-me];
  });

  gitImportString = buildTypstDocument (self: {
    name = "gitImport";
    src = ./documents;
    file = "gitImport.typ";
    extraPackages = "${note-me}";
  });

  gitImportDrv = buildTypstDocument (self: {
    name = "gitImport";
    src = ./documents;
    file = "gitImport.typ";
    extraPackages = note-me;
  });

  gitImportAttrStr = buildTypstDocument (self: {
    name = "gitImport";
    src = ./documents;
    file = "gitImport.typ";
    extraPackages = {
      local = "${note-me}";
    };
  });

  gitImportAttrDrv = buildTypstDocument (self: {
    name = "gitImport";
    src = ./documents;
    file = "gitImport.typ";
    extraPackages = {
      local = note-me;
    };
  });
}
