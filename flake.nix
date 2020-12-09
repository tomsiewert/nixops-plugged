{
  description = "NixOps with several plugins installed.";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.poetry2nix.url = "github:nix-community/poetry2nix";
  inputs.utils.url = "github:numtide/flake-utils";

  inputs.flake-compat = {
    url = "github:edolstra/flake-compat";
    flake = false;
  };

  outputs = { self, flake-compat, nixpkgs, poetry2nix, utils, ... }: utils.lib.eachDefaultSystem (system:
    let
      pkgs            = import nixpkgs { inherit system; overlays = [poetry2nix.overlay]; };
      nixopsPluggable = import ./nixops-pluggable.nix pkgs;

      inherit (nixopsPluggable) overrides nixops;
    in rec {

    defaultApp = {
      type = "app";
      program = "${packages.nixops-plugged}/bin/nixops";
    };

    defaultPackage = packages.nixops-plugged;

    packages = {
      # A nixops with all plugins included.
      nixops-plugged = nixops.withPlugins (ps: [
        ps.nixops-aws
        ps.nixops-digitalocean
        ps.nixops-gcp
        ps.nixops-hetznercloud
        #ps.nixops-virtd
        ps.nixopsvbox
      ]);
      # A nixops with each plugin for users who use a single provider.
      # Benefits from a much faster download/install.
      nixops-aws = nixops.withPlugins (ps: [ps.nixops-aws]);
      nixops-gcp = nixops.withPlugins (ps: [ps.nixops-gcp]);
      nixops-digitalocean = nixops.withPlugins (ps: [ps.nixops-digitalocean]);
      nixops-hetznercloud = nixops.withPlugins (ps: [ps.nixops-hetznercloud]);
      #nixops-virtd = nixops.withPlugins (ps: [ps.nixops-virtd]);
      nixopsvbox = nixops.withPlugins (ps: [ps.nixopsvbox]);
    };

    devShell = pkgs.mkShell {
      buildInputs = [
        (pkgs.poetry2nix.mkPoetryEnv {
          inherit overrides;
          projectDir = ./.;
        })
        pkgs.poetry
      ];
    };


  });
}
