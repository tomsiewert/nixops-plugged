# NixOps Plugged

Flakified version of [nixops-with-plugins](https://github.com/typetetris/nixops-with-plugins/) by @typetetris.

| Plugins | Included |
|:---|:---:|
| AWS           | :heavy_check_mark: |
| DigitalOcean  | :heavy_check_mark: |
| GCE           | :heavy_check_mark: |
| Hetzner Robot | :x: |
| Hetzner Cloud | :heavy_check_mark: |
| Proxmox       | :heavy_check_mark: |
| Virtd         | :heavy_check_mark: |
| VBox          | :heavy_check_mark: |

You can refer to this flake as input for another flake, i.e. inside the development environment for a flake packaging a NixOps network.
```nix
{
  description = "Your awesome flake";
  
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.nixops-plugged.url = "github:lukebfox/nixops-plugged";
  inputs.utils.url = "github:numtide/flake-utils";
  
  outputs = {self, nixpkgs, nixops-plugged, utils, ...}:
    let pkgs = import nixpkgs { inherit system; };
    in {
      nixopsConfigurations.default = { ... }; # your network definition
    } // utils.lib.eachDefaultSystem (system: {
      devShell = pkgs.mkShell {
        nativeBuildInputs = [ nixops-plugged.defaultPackage.${system} ];
      };
    });
}
```

To get a version of nixops with only the plugins you want, I would recommend forking this and following the instructions.
It is packages as a flake anticipating the coming flake app

Pinned nixpkgs version, so you can just use `default.nix` to build it or include
it somewhere else.

Pinned nixpkgs should not imply, you have to use the nixpkgs version this was
build with, anywhere else. It is just a python app being build and after
that `nixops` should pick up, which `nixpkgs` to use the usual way it always does.

The general steps to add a plugin:

Install poetry in some way.

Add your plugin to `pyproject.toml` and in `defaultPackage`.

Run `poetry lock`. If you made any errors editing `pyproject.toml` it should
tell you.

Run `nix build`.

---
