# NixOps 2.0 with batteries included.

This flake aims to include any compatible plugins as they become available.

## Use from the command line.
Clone this repository and you can run nixops from inside the project root. This flake exports a Nix App, so running `nix run . -- <args>` is equivalent to running `nixops <args>`.

## Use as a flake input.
You can refer to this flake as input for another flake, i.e. inside the development environment for some flake packaging a NixOps network.
```nix
{
  description = "Your awesome flake";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.nixops-plugged.url = "github:lukebfox/nixops-plugged";
  inputs.utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, nixops-plugged, utils, ... }: {
      nixopsConfigurations.default = { ... }; # your network definition
    } // utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs { inherit system; };
    in {
      devShell = pkgs.mkShell {
        nativeBuildInputs = [ nixops-plugged.defaultPackage.${system} ];
      };
    });
}
```
While inside the development shell for your flake you will now have access to a fully featured nixops.

| Plugins | Included |
|:---|:---:|
| AWS           | :heavy_check_mark: |
| DigitalOcean  | :heavy_check_mark: |
| GCE           | :heavy_check_mark: |
| Hetzner Robot | :x: |
| Hetzner Cloud | :heavy_check_mark: |
| Proxmox       | :x: |
| Virtd         | :x: |
| VBox          | :heavy_check_mark: |

To get a version of nixops with only the plugins you want, I would recommend forking this and following the instructions:
```bash
λ nix develop
λ vim pyproject.toml # add plugin to dependencies
λ vim flake.nix      # add plugin to defaultPackage and/or packages
λ poetry lock
```
You can run `nix run . -- list-plugins` to verify your changes.

---
