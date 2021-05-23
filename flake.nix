{
  description = "NixOps with batteries included.";

  inputs = {
    nixpkgs      = { url = "github:nixos/nixpkgs/nixpkgs-unstable"; };
    poetry2nix   = { url = "github:nix-community/poetry2nix"; };
    flake-utils  = { url = "github:numtide/flake-utils"; };
    flake-compat = { url = "github:edolstra/flake-compat"; flake = false; };
  };

  outputs = { self, nixpkgs, poetry2nix, flake-utils, flake-compat, ... }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs            = import nixpkgs { inherit system; overlays = [poetry2nix.overlay]; };
      nixopsPluggable = import ./nixops-pluggable.nix pkgs;

      inherit (nixopsPluggable) overrides nixops;

    in rec {

      defaultApp = { type = "app"; program = "${packages.nixops-plugged}/bin/nixops"; };

      defaultPackage = packages.nixops-plugged;

      packages = {
        # A nixops with all plugins included.
        nixops-plugged = nixops.withPlugins (ps: [
          ps.nixops-aws
          ps.nixops-gcp
          ps.nixops-digitalocean
          ps.nixops-hetznercloud
          ps.nixopsvbox
        ]);
        # A nixops with each plugin for users who use a single provider.
        # Benefits from a much faster download/install.
        nixops-aws          = nixops.withPlugins (ps: [ps.nixops-aws]);
        nixops-gcp          = nixops.withPlugins (ps: [ps.nixops-gcp]);
        nixops-digitalocean = nixops.withPlugins (ps: [ps.nixops-digitalocean]);
        nixops-hetznercloud = nixops.withPlugins (ps: [ps.nixops-hetznercloud]);
        nixopsvbox          = nixops.withPlugins (ps: [ps.nixopsvbox]);
      };

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
