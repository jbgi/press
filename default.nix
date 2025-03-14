universe: final: prev: let
  inherit (final) lib typst;
in {
  buildTypstDocument = lib.extendMkDerivation {
    constructDrv = final.stdenvNoCC.mkDerivation;

    excludeDrvArgNames = [];

    extendDrvArgs = finalAttrs: {
      name ? "${args.pname}-${args.version}",
      src ? null,
      srcs ? null,
      preUnpack ? null,
      postUnpack ? null,
      typstPatches ? [],
      patches ? [],
      sourceRoot ? null,
      logLevel ? "",
      buildInputs ? [],
      nativeBuildInputs ? [],
      meta ? {},
      fonts ? [],
      typstUniverse ? true,
      extraPackages ? [],
      file ? "main.typ",
      format ? "pdf",
      ...
    } @ args: let
      universe = lib.optionalString typstUniverse ''
        mkdir -p $XDG_DATA_HOME/typst/packages
        mv -r ${universe}/packages/preview $XDG_DATA_HOME/typst/packages/
      '';

      userPackages = lib.lists.foldl (accum: pack:
        accum
        + ''
          mkdir -p $XDG_DATA_HOME/typst/packages/${pack.namespace}/${pack.name}/${pack.version}
          mv -r ${pack.src}/* $XDG_DATA_HOME/typst/packages/${pack.namespace}/${pack.name}/${pack.version}
        '') ""
      extraPackages;
    in {
      nativeBuildInputs = nativeBuildInputs ++ [typst];
      patches = typstPatches ++ patches;
      strictDeps = true;

      buildPhase =
        args.buildPhase
        or (''
            export XDG_DATA_HOME=$(mktemp -d)
          ''
          + universe
          + userPackages
          + ''
            typst c ${file} -f ${format} $out
          '');

      meta =
        meta
        // {
          badPlatforms = meta.badPlatforms or [] ++ typst.badPlatforms or [];
          platforms = lib.intersectLists meta.platforms or lib.platforms.all typst.meta.platforms or [];
        };
    };
  };
}
