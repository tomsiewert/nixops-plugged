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
While inside the development shell for your flake you will now have access to a fully(ish) featured `nixops`. 
```
λ nix develop
λ nixops list-plugins
```
If you only care about one plugin, this flake additionally exports packages for this use case, i.e `nixops-plugged.packages.nixops-aws` to get a `nixops` with the `nixops-aws` plugin.

| Plugins | Included |
|:---|:---:|
| [AWS][1]           | :heavy_check_mark: |
| [DigitalOcean][2]  | :heavy_check_mark: |
| [GCE][3]           | :heavy_check_mark: |
| [Hetzner Cloud][4] | :heavy_check_mark: |
| [VBox][5]          | :heavy_check_mark: |
| [Hetzner Robot][6] | :x: |
| [Proxmox][7]       | :x: |
| [Virtd][8]         | :x: |

To get a version of nixops with *exactly* the plugins you want, no more and no less, I would recommend forking this and following the instructions:
```bash
λ nix develop
λ vim pyproject.toml # add plugin to dependencies
λ vim flake.nix      # add plugin to defaultPackage and/or packages
λ poetry lock
```
You can run `nix run . -- list-plugins` to verify your changes.

## Use from legacy nix.
The legacy commands `nix-build` and `nix-shell` should still work thanks to the compatability shim from [flake-compat](https://github.com/edolstra/flake-compat), although I don't use these so YMMV.

[1]: https://github.com/NixOS/nixops-aws
[2]: https://github.com/nix-community/nixops-digitalocean
[3]: https://github.com/nix-community/nixops-gce
[4]: https://github.com/lukebfox/nixops-hetznercloud
[5]: https://github.com/nix-community/nixops-vbox
[6]: https://github.com/NixOS/nixops-hetzner
[7]: https://github.com/RaitoBezarius/nixops-proxmox
[8]: https://github.com/nix-community/nixops-libvirtd
