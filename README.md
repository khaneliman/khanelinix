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
# New machine without git
nix-shell -p git

# Clone
git clone https://github.com/khaneliman/khanelinix.git
cd khanelinix

# Linux
sudo nixos-rebuild switch --flake .

# MacOS
# First run without nix-darwin:
nix run github:lnl7/nix-darwin#darwin-rebuild -- switch --flake github:khaneliman/khanelinix

darwin-rebuild switch --flake .

 # With nh (Nix Helper)
nh os switch .

# With direnv
flake switch
```

## Features

Here's an overview of what my Nix configuration offers:

- **External Dependency Integrations**:
  - [Khanelivim](https://github.com/khaneliman/khanelivim) custom neovim
    configuration built with nixvim.
  - Access NUR expressions for Firefox addons and other enhancements.
  - Integration with Hyprland and other Wayland compositors.

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

My Nix configuration is built using
[flake-parts](https://github.com/hercules-ci/flake-parts), providing a flexible
and modular approach to managing your Nix environment. Here's how it works:

- **Flake Parts Structure**: The configuration uses flake-parts to organize
  outputs into modular parts, with the main flake definition importing from the
  `flake/` directory for better organization.

- **Custom Library**: The `lib/` directory contains custom library functions and
  utilities that extend the standard nixpkgs lib, providing additional helpers
  for system configuration.

- **Package Management**: The `packages/` directory contains custom packages
  exported by the flake. Each package is built using `callPackage` and can be
  used across different system configurations.

- **Modular Configurations**: The `modules/` directory defines reusable NixOS,
  Darwin, and Home Manager modules. This modular approach allows for consistent
  configuration across different platforms and systems.

- **Overlay System**: Custom overlays in the `overlays/` directory modify and
  extend the nixpkgs package set, allowing for package customizations and
  additions.

- **System Configurations**: Host-specific configurations are organized in
  `systems/` with separate directories for different architectures
  (`x86_64-linux`, `aarch64-darwin`).

- **Home Configurations**: User-specific Home Manager configurations in the
  `homes/` directory, organized by user and system architecture.

- **Development Environment**: A partitioned development environment in
  `flake/dev/` provides development shells, formatting tools, and checks
  separate from the main flake outputs.

This flake-parts based approach provides excellent modularity and makes it easy
to maintain and extend the configuration while keeping related functionality
organized.

# Exported packages

Run packages directly with:

```console
nix run --extra-experimental-features 'nix-command flakes' github:khaneliman/khanelinix#packageName
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
