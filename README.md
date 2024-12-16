<h3 align="center">
 <img src="https://avatars.githubusercontent.com/u/1778670?v=4" width="100" alt="Logo"/><br/>
 <img src="https://raw.githubusercontent.com/catppuccin/catppuccin/main/assets/misc/transparent.png" height="30" width="0px"/>
 <img src="https://nixos.org/logo/nixos-logo-only-hires.png" height="20" /> NixOS Config for <a href="https://github.com/khaneliman">Khaneliman</a>
 <img src="https://raw.githubusercontent.com/catppuccin/catppuccin/main/assets/misc/transparent.png" height="30" width="0px"/>
</h3>

<p align="center">
 <a href="https://github.com/khaneliman/khanelinix/stargazers"><img src="https://img.shields.io/github/stars/khaneliman/khanelinix?colorA=363a4f&colorB=b7bdf8&style=for-the-badge"></a>
 <a href="https://github.com/khaneliman/khanelinix/commits"><img src="https://img.shields.io/github/last-commit/khaneliman/khanelinix?colorA=363a4f&colorB=f5a97f&style=for-the-badge"></a>
  <a href="https://wiki.nixos.org/wiki/Flakes" target="_blank">
 <img alt="Nix Flakes Ready" src="https://img.shields.io/static/v1?logo=nixos&logoColor=d8dee9&label=Nix%20Flakes&labelColor=5e81ac&message=Ready&color=d8dee9&style=for-the-badge">
</a>
<a href="https://github.com/snowfallorg/lib" target="_blank">
 <img alt="Built With Snowfall" src="https://img.shields.io/static/v1?logoColor=d8dee9&label=Built%20With&labelColor=5e81ac&message=Snowfall&color=d8dee9&style=for-the-badge">
</a>
</p>

Welcome to khanelinix, a personal Nix configuration repository. This repository
contains my NixOS and Nixpkgs configurations, along with various tools and
customizations to enhance the Nix experience.

## Table of Contents

1. [Getting Started](#getting-started)
2. [Features](#features)
3. [Customization](#customization)
4. [Exported Packages](#exported-packages)
5. [Screenshots](#screenshots)
6. [Resources](#resources)

## Getting Started

Before diving in, ensure that you have Nix installed on your system. If not, you
can download and install it from the official
[Nix website](https://nixos.org/download.html) or from the
[Determinate Systems installer](https://github.com/DeterminateSystems/nix-installer).
If running on macOS, you need to have Nix-Darwin installed, as well. You can
follow the installation instruction on
[GitHub](https://github.com/LnL7/nix-darwin?tab=readme-ov-file#flakes).

### Clone this repository to your local machine

```bash
git clone https://github.com/khaneliman/khanelinix.git
cd khanelinix

# linux
sudo nixos-rebuild switch --flake .

 # macos
darwin-rebuild switch --flake .

 # with direnv
flake switch
```

## Features

Here's an overview of what my Nix configuration offers:

- **External Dependency Integrations**:
  - [Nixvim](https://github.com/nix-community/nixvim) neovim configuration.
  - Access the Nix User Repository (NUR) for additional packages and
    enhancements.
  - Incorporate Nixpkgs-Wayland to provide an up-to-date Wayland package
    repository.

- **macOS Support**: Seamlessly configure and manage Nix on macOS using the
  power of [Nix-darwin](https://github.com/LnL7/nix-darwin), also leveraging
  homebrew for GUI applications.

- **Home Manager**: Manage your dotfiles, home environment, and user-specific
  configurations with
  [Home Manager](https://github.com/nix-community/home-manager).

- **DevShell Support**: The flake provides a development shell (`devShell`) to
  support maintaining this flake. You can use the devShell for convenient
  development and maintenance of your Nix environment.

- **CI with Cachix**: The configuration includes continuous integration (CI)
  that pushes built artifacts to [Cachix](https://github.com/cachix/cachix).
  This ensures efficient builds and reduces the need to build dependencies on
  your local machine.

- **Utilize sops-nix**: Secret management with
  [sops-nix](https://github.com/Mic92/sops-nix) for secure and encrypted
  handling of sensitive information.

## Customization

My Nix configuration, based on the
[SnowfallOrg lib](https://github.com/snowfallorg/lib) structure, provides a
flexible and organized approach to managing your Nix environment. Here's how it
works:

- **Custom Library**: An optional custom library in the `lib/` directory
  contains a Nix function called with `inputs`, `snowfall-inputs`, and `lib`.
  The function should return an attribute set to merge with `lib`.

- **Modular Directory Structure**: You can create any (nestable) directory
  structure within `lib/`, `packages/`, `modules/`, `overlays/`, `systems/`, and
  `homes/`. Each directory should contain a Nix function that returns an
  attribute set to merge with the corresponding section.

- **Package Overlays**: The `packages/` directory includes an optional set of
  packages to export. Each package is instantiated with `callPackage`, and the
  files should contain functions that take an attribute set of packages and the
  required `lib` to return a derivation.

- **Modules for Configuration**: In the `modules/` directory, you can define
  NixOS modules for various platforms, such as `nixos`, `darwin`, and `home`.
  This modular approach simplifies system configuration management.

- **Custom Overlays**: The `overlays/` directory is for optional custom
  overlays. Each overlay file should contain a function that takes three
  arguments: an attribute set of your flake's inputs and a `channels` attribute
  containing all available channels, the final set of `pkgs`, and the previous
  set of `pkgs`. This allows you to customize package sets effectively.

- **System Configurations**: The `systems/` directory organizes system
  configurations based on architecture and format. You can create configurations
  for different architectures and formats, such as `x86_64-linux`,
  `aarch64-darwin`, and more.

- **Home Configurations**: Similar to system configurations, the `homes/`
  directory organizes home configurations based on architecture and format. This
  is especially useful if you want to manage home environments with Nix.

This structured approach to Nix configuration makes it easier to manage and
customize your Nix environment while maintaining flexibility and modularity.

# Exported packages

Run packages directly with:

```console
nix run github:khaneliman/khanelinix#packageName
```

Or install from the `packages` output. For example:

```nix
# flake.nix
{
  inputs.khanelinix = {
    url = "github:khaneliman/khanelinix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}

# configuration.nix
{pkgs, inputs, system, ...}: {
  environment.systemPackages = [
    inputs.khanelinix.packages."${system}".packageName
  ];
}
```

# Screenshots

## MacOS

<img width="1512" alt="image" src="https://github.com/khaneliman/khanelinix/assets/1778670/abbd501e-60c4-46c3-927d-12890dadd811">

## NixOS

![image](https://github.com/khaneliman/khanelinix/assets/1778670/34aebc9c-b053-4ccf-9540-6da5e93a77d5)

# Resources

Other configurations from where I learned and copied:

- [JakeHamilton/config](https://github.com/jakehamilton/config) *Main
  inspiration and started with
- [FelixKrats/dotfiles](https://github.com/FelixKratz/dotfiles) *Sketchybar
  design and implementation
- [Fufexan/dotfiles](https://github.com/fufexan/dotfiles)
- [NotAShelf/nyx](https://github.com/NotAShelf/nyx)
