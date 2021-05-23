pkgs:

let

  inherit (pkgs) lib;

  # Make a python derivation pluginable
  #
  # This adds a `withPlugins` function that works much like `withPackages`
  # except it only links binaries from the explicit derivation /share
  # from any plugins
  toPluginAble = { drv, finalDrv, final }: drv.overridePythonAttrs(old: {
    passthru = old.passthru // {
      # Wrap the buildEnv derivation in an outer derivation that omits interpreters & other binaries
      withPlugins = pluginFn:
        let
          plugins = [finalDrv] ++ pluginFn final;
          # The complete buildEnv drv
          buildEnvDrv = interpreter.buildEnv.override { extraLibs = plugins; };
          # Create a separate environment aggregating the share directory
          # This is done because we only want /share for the actual plugins
          # and not for e.g. the python interpreter and other dependencies.
          manEnv = pkgs.symlinkJoin {
            name = "${finalDrv.pname}-plugged-share-${finalDrv.version}";
            preferLocalBuild = true;
            allowSubstitutes = false;
            paths = plugins;
            postBuild = ''
              if test -e $out/share; then
                mv $out out
                mv out/share $out
              else
                rm -r $out
                mkdir $out
              fi
              '';
          };
        in
          pkgs.runCommandNoCC
            "${finalDrv.pname}-plugged-${finalDrv.version}"
            { inherit (finalDrv) passthru meta; }
            ''
              mkdir -p $out/bin

              for bindir in ${lib.concatStringsSep " " (map (d: "${lib.getBin d}/bin") plugins)}; do
                for bin in $bindir/*; do
                  ln -s ${buildEnvDrv}/bin/$(basename $bin) $out/bin/
                done
              done

              ln -s ${manEnv} $out/share
              '';
    };
  });

  interpreter = (pkgs.poetry2nix.mkPoetryPackages {
    inherit overrides;
    projectDir = ./.;
  }).python;

  overrides = pkgs.poetry2nix.overrides.withDefaults (final: prev: {
    nixops = toPluginAble {
      inherit final;
      finalDrv = final.nixops;
      # Attach meta to nixops
      drv = prev.nixops.overridePythonAttrs (old: {
        format = "pyproject";
        buildInputs = old.buildInputs ++ [ final.poetry ];
        meta = old.meta // {
          homepage = https://github.com/NixOS/nixops;
          description = "NixOS cloud provisioning and deployment tool";
          maintainers = with lib.maintainers; [ aminechikhaoui eelco rob domenkozar ];
          platforms = lib.platforms.unix;
          license = lib.licenses.lgpl3;
        };
      });
    };

    # These are included in the latest poetry2nix overlay.

    jsonpickle = prev.jsonpickle.overridePythonAttrs (old: {
      nativeBuildInputs = old.nativeBuildInputs ++ [final.toml];
    });
    # https://github.com/nix-community/poetry2nix/issues/218
    packaging = prev.packaging.overridePythonAttrs({buildInputs ? [], ...}: {
      format = "pyproject";
      buildInputs = buildInputs ++ [ final.flit-core ];
    });
    # https://github.com/nix-community/poetry2nix/issues/208
    #typeguard = prev.typeguard.overridePythonAttrs (old: {
    #  postPatch = ''
    #    substituteInPlace setup.py \
    #      --replace 'setup()' 'setup(version="${old.version}")'
    #  '';
    #});

  });

in {
  inherit overrides;
  inherit (interpreter.pkgs) nixops;
}
