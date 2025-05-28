final: prev:
let
  inherit (final)
    lib
    stdenvNoCC
    buildEnv
    applyPatches
    makeBinaryWrapper
    callPackage
    typst
    ;
  inherit (final.xorg) lndir;
  inherit (lib.asserts) assertMsg;
in
{
  buildTypstDocument = lib.extendMkDerivation {
    # No need for CC here
    constructDrv = stdenvNoCC.mkDerivation;

    # IDK exactly but at least extraPackages is required
    # or things break.
    excludeDrvArgNames = [
      "extraPackages"
      #"fonts"
      #"typstEnv"
      #"inputs"
    ];

    # All the drv args
    # Put sane defualts.
    extendDrvArgs =
      finalAttrs:
      {
        name ? "${finalAttrs.pname}-${finalAttrs.version}",
        verbose ? false,
        meta ? { },
        fonts ? [ ],
        typstEnv ? (_: [ ]),
        extraPackages ? { },
        file ? "main.typ",
        inputs ? { },
        format ? "pdf",
        ...
      }@args:
      let
        userPackages =
          let
            inherit (builtins) typeOf;

            userPack = callPackage ./src/mkPackage.nix;
          in
          assert assertMsg (
            typeOf extraPackages == "set"
          ) "extraPackages must be of type AttributeSet[String, List[TypstPackage]]";
          lib.attrsets.foldlAttrs (
            pkgs: namespace: paths:
            assert assertMsg (typeOf paths == "list") "the attrset values must be lists of typst packages";
            lib.lists.foldl (accum: src: accum ++ [ (userPack { inherit src namespace; }) ]) pkgs paths
          ) [ ] finalAttrs.extraPackages;

        # All fonts in nixpkgs should follow this.
        fontsDrv = callPackage ./src/mkFonts.nix { inherit (finalAttrs) fonts name; };

        # Combine all the packages to one drv
        pkgsDrv = buildEnv {
          name = finalAttrs.name + "-deps";
          pathsToLink = [ "/share/typst/packages" ];
          paths = userPackages;
        };
        typstUni = typst.withPackages finalAttrs.typstEnv;

        typstWrap = stdenvNoCC.mkDerivation {
          strictDeps = true;
          dontUnpack = true;
          dontConfigure = true;
          dontInstall = true;

          name = "typst-wrapped";
          buildInputs = [ makeBinaryWrapper ];
          buildPhase = ''
            runHook preBuild

            makeWrapper ${lib.getExe typstUni} $out/bin/typst \
              --prefix TYPST_FONT_PATHS : ${fontsDrv}/share/fonts \
              --set TYPST_PACKAGE_PATH ${pkgsDrv}/share/typst/packages

            runHook postBuild
          '';
          meta.mainProgram = "typst";
        };
      in
      {
        nativeBuildInputs = args.nativeBuildInputs or [ ] ++ [ typstWrap ];
        strictDeps = true;
        buildPhase =
          assert assertMsg (builtins.elem finalAttrs.format [
            "pdf"
            "html"
          ]) "Typst only supports html or pdf output.";
          args.buildPhase or ''
            runHook preBuild

            typst c ${finalAttrs.file} ${lib.optionalString finalAttrs.verbose "--verbose"} ${
              lib.optionalString (finalAttrs.format == "html") "--features html"
            } ${
              lib.concatStringsSep " " (
                lib.mapAttrsToList (name: value: "--input ${name}=${lib.escapeShellArg value}") finalAttrs.inputs
              )
            } -f ${finalAttrs.format} $out

            runHook postBuild
          '';

        shellHook = ''
          export TYPST_PACKAGE_CACHE_PATH="${typstUni}/lib/typst/packages"
          export TYPST_PACKAGE_PATH="${pkgsDrv}/share/typst/packages"
          export TYPST_FONT_PATHS="${fontsDrv}/share/fonts"
        '';

        meta = meta // {
          badPlatforms = meta.badPlatforms or [ ] ++ typst.badPlatforms or [ ];
          platforms = lib.intersectLists meta.platforms or lib.platforms.all typst.meta.platforms or [ ];
        };
      };
  };
}
