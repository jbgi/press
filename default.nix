final: prev: let
  inherit (final) lib typst symlinkJoin stdenvNoCC applyPatches;

  lock = builtins.fromJSON (builtins.readFile ./flake.lock);
  uniGit = lock.nodes.universe.locked;
  universe = fetchTarball {
    url = "https://api.github.com/repos/${uniGit.owner}/${uniGit.repo}/tarball/${uniGit.rev}";
    sha256 = uniGit.narHash;
  };
in {
  buildTypstDocument = lib.extendMkDerivation {
    # No need for CC here
    constructDrv = stdenvNoCC.mkDerivation;

    # IDK exactly but at least extraPackages is required
    # or things break.
    excludeDrvArgNames = ["extraPackages" "fonts"];

    # All the drv args
    # Put sane defualts.
    extendDrvArgs = finalAttrs: {
      name ? "${args.pname}-${args.version}",
      src ? null,
      typstPatches ? [],
      patches ? [],
      logLevel ? "",
      buildInputs ? [],
      nativeBuildInputs ? [],
      meta ? {},
      fonts ? [],
      typstUniverse ? true,
      universePatches ? [],
      extraPackages ? {},
      file ? "main.typ",
      format ? "pdf",
      ...
    } @ args: let
      # Must patch Typst Universe if requested.
      universe' = let
        patchedUni =
          if universePatches == []
          then universe
          else
            applyPatches {
              name = "universe-patched";
              src = universe;
              patches = universePatches;
            };
      in
        lib.optionalString typstUniverse ''
          mkdir -p $XDG_DATA_HOME/typst/packages
          cp -r ${patchedUni}/packages/preview $XDG_DATA_HOME/typst/packages/
        '';

      # Must carefully arrange the environment so that Typst gets the packages.
      # Read the docs, but it's basically:
      #
      # $XDG_DATA_HOME/typst/packages/$NAMESPACE/$PACKAGE_NAME/$PACKAGE_VERSION/typst.toml
      # And we are looking for the TOML file.
      #
      # It is good to allow the user to provide an AttrSet if they want specific namespaces for packages.
      # But also if they provide a list, just throw it in the "local" namespace as the Typst documentation
      # uses that. If they just provide a single package, then do the same thing.
      userPackages = let
        # I feel like there may be a funny point free way to do this, but my brain cannot
        # figure it out.
        # A typst.toml is required. There is no other sane way of doing it.
        userPack = {
          path,
          namespace,
        }: let
          manifest = lib.importTOML "${path}/typst.toml";
          version = manifest.package.version or (throw "${path}/typst.toml missing version field");
          name = manifest.package.name or (throw "${path}/typst.toml missing name field");
        in ''
          mkdir -p $XDG_DATA_HOME/typst/packages/${namespace}/${name}/${version}
          cp -r ${path}/* $XDG_DATA_HOME/typst/packages/${namespace}/${name}/${version}
        '';

        # Some helpers. Match expression when.
        type = builtins.typeOf extraPackages;
        isDrv = lib.isDerivation extraPackages;
      in
        if (type == "set" && !isDrv)
        then
          # Set key is the namespace.
          lib.attrsets.foldlAttrs (shString: namespace: paths:
            # Might as well accept lists, str, path, or drv as well here.
            let
              valType = builtins.typeOf paths;
              valIsDrv = lib.isDerivation paths;
            in
              if valType == "list"
              then
                lib.lists.foldl (accum: path:
                  accum
                  + userPack {inherit path namespace;})
                shString
                paths
              else if (valType == "string" || valType == "path" || valIsDrv)
              then
                # Same as below. Realize the path. Use the namespace.
                userPack {
                  inherit namespace;
                  path = "${paths}";
                }
              else throw "Found type ${valType} for the ${namespace} key's value in extraPackages. Expected list, string, path, or derivation") ""
          extraPackages
        else if type == "list"
        then
          # Put all the packages in the local namespace.
          lib.lists.foldl (accum: path:
            accum
            + userPack {
              inherit path;
              namespace = "local";
            }) ""
          extraPackages
        else if (type == "string" || isDrv || type == "path")
        then
          # Interpolate the string so if it is a path or drv it is realized.
          userPack {
            path = "${extraPackages}";
            namespace = "local";
          }
        else throw "Found type ${type} for binding 'extraPackages', expected AttrSet, list, string, path, or derivation";

      # All fonts in nixpkgs should follow this.
      fontsDrv = symlinkJoin {
        name = "typst-fonts";
        paths = fonts;
        stripPrefix = "/share/fonts";
      };

      # HTML is experimental.
      formatPrefix =
        if format == "pdf"
        then "-f"
        else if format == "html"
        then "--features html -f"
        else throw "Unsupported format.";
    in {
      nativeBuildInputs = nativeBuildInputs ++ [typst];
      patches = typstPatches ++ patches;
      strictDeps = true;

      env.TYPST_FONT_PATHS = "${fontsDrv}";

      buildPhase =
        args.buildPhase
        or (''
            runHook preBuild

            export XDG_DATA_HOME=$(mktemp -d)
          ''
          + universe'
          + userPackages
          + ''
            typst c ${file} ${formatPrefix} ${format} $out

            runHook postBuild
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
