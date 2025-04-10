final: prev:
let
  inherit (final)
    lib
    typst
    symlinkJoin
    stdenvNoCC
    applyPatches
    makeBinaryWrapper
    ;
  inherit (final.xorg) lndir;

  lock = builtins.fromJSON (builtins.readFile ./flake.lock);
  uniGit = lock.nodes.universe.locked;
  universe = fetchTarball {
    url = "https://api.github.com/repos/${uniGit.owner}/${uniGit.repo}/tarball/${uniGit.rev}";
    sha256 = uniGit.narHash;
  };
in
{
  buildTypstDocument = lib.extendMkDerivation {
    # No need for CC here
    constructDrv = stdenvNoCC.mkDerivation;

    # IDK exactly but at least extraPackages is required
    # or things break.
    excludeDrvArgNames = [
      "extraPackages"
      "fonts"
    ];

    # All the drv args
    # Put sane defualts.
    extendDrvArgs =
      finalAttrs:
      {
        name ? "${args.pname}-${args.version}",
        verbose ? false,
        meta ? { },
        fonts ? [ ],
        typstPatches ? [ ],
        typstUniverse ? true,
        universePatches ? [ ],
        extraPackages ? { },
        file ? "main.typ",
        format ? "pdf",
        ...
      }@args:
      assert builtins.elem format [
        "pdf"
        "html"
      ];
      let
        # Must patch Typst Universe if requested.
        universe' =
          let
            patchedUni =
              if universePatches == [ ] then
                universe
              else
                applyPatches {
                  name = "universe-patched";
                  src = universe;
                  patches = universePatches;
                };
          in
          symlinkJoin {
            name = "universe-pkg";
            paths = [ ];
            postBuild = ''
              mkdir -p $out/share/typst/packages/

              ${lib.getExe lndir} -silent ${patchedUni}/packages $out/share/typst/packages/
              ls -al $out/share/typst/packages
            '';
          };

        # It is good to allow the user to provide an AttrSet if they want specific namespaces for packages.
        # But also if they provide a list, just throw it in the "local" namespace as the Typst documentation
        # uses that. If they just provide a single package, then do the same thing.
        userPackages =
          let
            inherit (builtins) typeOf;
            inherit (lib) isDerivation attrsets lists;

            # Some helpers. Match expression when.
            type = typeOf extraPackages;
            isDrv = (isDerivation extraPackages) || (extraPackages ? outPath);

            userPack = final.callPackage ./src/mkPackage.nix;
          in
          if (type == "set" && !isDrv) then
            # Set key is the namespace.
            attrsets.foldlAttrs (
              pkgs: namespace: paths:
              # Might as well accept lists, str, path, or drv as well here.
              let
                valType = typeOf paths;
              in
              if valType == "list" then
                lists.foldl (accum: src: accum ++ [ (userPack { inherit src namespace; }) ]) pkgs paths
              else
                # Same as below. Realize the path. Use the namespace.
                [
                  (userPack {
                    inherit namespace;
                    src = "${paths}";
                  })
                ]
            ) [ ] extraPackages
          else if type == "list" then
            # Put all the packages in the local namespace.
            lists.foldl (
              pkgs: src:
              pkgs
              ++ [
                (userPack {
                  inherit src;
                })
              ]
            ) [ ] extraPackages
          else
            [
              (userPack {
                src = "${extraPackages}";
              })
            ];

        # All fonts in nixpkgs should follow this.
        fontsDrv = final.callPackage ./src/mkFonts.nix { inherit fonts name; };

        # Combine all the packages to one drv
        pkgsDrv = symlinkJoin {
          name = name + "-deps";
          paths = userPackages ++ lib.optionals typstUniverse [ universe' ];
        };

        typstWrap = symlinkJoin {
          name = "typst-wrapped";
          paths = [ typst ];
          buildInputs = [ makeBinaryWrapper ];
          postBuild = ''
            wrapProgram $out/bin/typst \
              --set TYPST_FONT_PATHS ${fontsDrv}/share/fonts \
              --set XDG_DATA_HOME ${pkgsDrv}/share
          '';
          meta.mainProgram = "typst";
        };
      in
      {
        nativeBuildInputs = args.nativeBuildInputs or [ typstWrap ];
        strictDeps = true;
        patches =
          args.patches or [ ]
          ++ lib.trivial.warnIf (typstPatches != [ ])
            "typstPatches is deprecated and will be removed in a future release. Just use the 'patches' attribute."
            typstPatches;

        buildPhase =
          args.buildPhase or ''
            runHook preBuild

            typst c ${file} ${lib.optionalString verbose "--verbose"} ${
              lib.optionalString (format == "html") "--features html"
            } -f ${format} $out

            runHook postBuild
          '';

        meta = meta // {
          badPlatforms = meta.badPlatforms or [ ] ++ typst.badPlatforms or [ ];
          platforms = lib.intersectLists meta.platforms or lib.platforms.all typst.meta.platforms or [ ];
        };
      };
  };
}
