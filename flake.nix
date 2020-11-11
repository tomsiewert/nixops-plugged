{
  description = "NixOps with several plugins installed.";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/master";
  inputs.utils.url = "github:numtide/flake-utils";

  outputs = inputs: inputs.utils.lib.eachDefaultSystem (system: let
    
    pkgs = import inputs.nixpkgs { inherit system; };

    inherit (pkgs) lib;
    
    # Wrap the buildEnv derivation in an outer derivation that omits interpreters & other binaries
    mkPluginDrv = { finalDrv, interpreter, plugins }:
      let

        # The complete buildEnv drv
        buildEnvDrv = interpreter.buildEnv.override {
          extraLibs = plugins;
        };

        # Create a separate environment aggregating the share directory
        # This is done because we only want /share for the actual plugins
        # and not for e.g. the python interpreter and other dependencies.
        manEnv = pkgs.symlinkJoin {
          name = "${finalDrv.pname}-with-plugins-share-${finalDrv.version}";
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
          "${finalDrv.pname}-with-plugins-${finalDrv.version}"
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

    # Make a python derivation pluginable
    #
    # This adds a `withPlugins` function that works much like `withPackages`
    # except it only links binaries from the explicit derivation /share
    # from any plugins
    toPluginAble = { drv, finalDrv, final }: drv.overridePythonAttrs(old: {
      passthru = old.passthru // {
        withPlugins = pluginFn: mkPluginDrv {
          plugins = [ finalDrv ] ++ pluginFn final;
          inherit finalDrv interpreter;
        };
      };
    });

    overrides = pkgs.poetry2nix.overrides.withDefaults (final: prev: {
      # Make nixops pluggable
      nixops = toPluginAble {
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
        finalDrv = final.nixops;
        inherit final;
      };
    });

    interpreter = (pkgs.poetry2nix.mkPoetryPackages {
      inherit overrides;
      projectDir = ./.;
    }).python;

  in {

    # A nixops with all plugins.
    defaultPackage = interpreter.pkgs.nixops.withPlugins (ps: [
      # ps.nixops-aws
      # ps.nixops-digitalocean
      # ps.nixops-gcp
      ps.nixops-hetznercloud
      # ps.nixops-proxmox
      # ps.nixops-virtd
      # ps.nixopsvbox
    ]);

    # A nixops for each plugin for those who just want a specific one.
    packages = {
      # nixops-aws = interpreter.pkgs.nixops.withPlugins (ps: [ps.nixops-aws]);
      # nixops-gcp = interpreter.pkgs.nixops.withPlugins (ps: [ps.nixops-gcp]);
      # nixops-digitalocean = interpreter.pkgs.nixops.withPlugins (ps: [ps.nixops-digitalocean]);
      nixops-hetznercloud = interpreter.pkgs.nixops.withPlugins (ps: [ps.nixops-hetznercloud]);
      # nixops-proxmox = interpreter.pkgs.nixops.withPlugins (ps: [ps.nixops-proxmox]);
      # nixops-virtd = interpreter.pkgs.nixops.withPlugins (ps: [ps.nixops-virtd]);
      # nixopsvbox = interpreter.pkgs.nixops.withPlugins (ps: [ps.nixopsvbox]);
    };

    # Can use this function to mix plugins as you see fit.
    lib = interpreter.pkgs.nixops.withPlugins;

    devShell = pkgs.mkShell {
      buildInputs = [
        pkgs.poetry
        (pkgs.poetry2nix.mkPoetryEnv {
          inherit overrides;
          projectDir = ./.;
        })
      ];
    };

  });
}
