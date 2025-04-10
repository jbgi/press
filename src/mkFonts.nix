{
  fonts,
  name,
  
  symlinkJoin
}:
  symlinkJoin {
    name = name + "-fonts";
    paths = fonts;
  }
