{
  buildTypstDocument,
}:

buildTypstDocument (self: {
  name = "basic";
  src = ./documents;
  typstUniverse = false;
  file = "basic.typ";
})
