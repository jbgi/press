{buildTypstDocument}: {
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
}
