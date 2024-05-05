 # Changelog

 ## [Unreleased]

### Changed

- flake.nix: exclude flake.lock updates from changelog

- CHANGELOG.md: init

- .gitignore: ignore symlinked pre-commit config

- devshell/default: cleanup

- theme: change default package for system

- flake.lock: update

Disable font-manager until fixed

- zellij: more detail to session resurrection

- hypridle: migrate to home-manager module

- hyprland: update terminal keybinds

- zellij: enable session serialization

- skhd: update terminal keybindings

- zellij: remove strider

- wezterm: change term variable

- flake.lock: update

- direnv: silence output

- nix/services: take ownership of logrotate and oomd

- fwupd: set esp location

- flake.lock: update

- theme: fromyaml distinct log message

- CORE: resolve conflict

- cliphist: use home-manager module

- steam: compat tools fix

- gamescope: move to module

- gamemode: renice tweaks

- yubikey: move to hardware

- chore: lint fix

- flake.lock: update

Resolved hyprland bug

- nix: more tweaks

- flake.nix: pin hyprland input to before breaking change

https://github.com/hyprwm/Hyprland/issues/5849

- flake.lock: update

- mpd: disable playerctld

Crashing nonstop

- hyprland: reorg background apps

- nixos/rgb: split modules

- mpd: disable discord rpc

- hyprland: move variables to home

- flake.nix: remove hypr-socket-watch overlay

- flake.nix: remove hypr*.inputs.nixpkgs.follows

- hypridle: use flake pkg

- hyprlock: use flake pkg

- flake.lock: update

- nix: misc tweaks

- nix: documentation tweaks

Might speed up rebuilds

- chore: lint cleanup

- khanelinix: test setting max-jobs

- hyprland: refactor

- flake.lock: more cleanup

- flake.lock: update

- sketchybar: set yabai external_bar on load

Usually yabai loads before sketchybar, allow sketchybar to configure
yabai's external_bar height when it loads

- vscode: user settings

Moving user settings from sync profile over.

- zathura: clean up

- ncmpcpp: qol improvements

- hyprland: adjust grimblast binds

More logical mappings to remember
Also switch to hypr-contrib, fixes issues with nixpkg

- hyprland: adjust grimblast binds

Can just notify from the script itself and can freeze for better
screenshots

- waybar: remove alt for clock

- hyprland: use grimblast for all screenshots

- neovim: disable settings dotnet root global

- flake.lock: update

- easyeffects: disable for now

Finding it kinda annoying

- yazi: highlight links and orphans

- yazi: break up theme config

- git: minor tweaks

- comma: replace with nix-index-database

- flake.nix: remove unused inputs

- flake.lock: update

- hyprpaper: use flake pkg to fix hypr-socket-watch

- flake.lock: update

- waybar: reduce tray padding

- waybar: network format

- waybar: modules cleanup

- services/easyeffects: init module

- nixos/music: cleanup

- nixos/video: clean up FIX todos

- wallpapers: remove module used for creating symlink

- tray: move to separate module

- udiskie: reenable

- homes: consolidate nixcfg alias

- khanelinix: use noisetorch

- home/services/noisetorch: init module

- nixos/noisetorch: init module

- flake.lock: update

- mpd: refactor

- hyprland: cleanup package

- hyprland: remove redundant sessionVariables

https://github.com/NixOS/nixpkgs/pull/307155 added these by default now

- Update README.md
- wlroots: use polkit service module

- services/polkit: init new module

- wlroots: use clipboard service module

- services/cliboard: init new module

- gtk: refactoring

- hyprland: tweak launcher bindings

- qt: reorg and add some packages

- neovim: dont open minimap on load

- swaync: tweaking ui and features

- swaync: misc fixes

- wlroots: clean up systemPackages

- eww: remove

- home-manager: backup existing files

- networking: more refactoring

- devShell/default: use nixpkgs nix-inspect

- swaync: migrate to home-manager module

- networking: refactor

Trying NotAShelf config to see if it helps with my connectivity issues

- flake.lock: update

- chore: misc cleanup

- neovim: use spectre module

- khanelinix: use silentBoot

- plymouth: use theme config values

- nix: daemon priority adjustments

- nix: gc cleanup more frequently

- hardware: restructure gpu with nesting

- hardware: restructure cpu with nesting

- neovim: remove old config inputs

- flake.nix: remove nixos-hardware

- khanelilab: use intelcpu module

- hardware: init intelcpu

- khanelinix/specialization: migrate nixos-hardware nvidia removal to flake

- hardware: remove common-pc

- ssd: migrate nixos-hardware to flake

- bluetooth: tweaks

- pipewire: audio enable

- amdcpu: migrate nixos-hardware to flake

Trying to reduce external input dependencies.

- amdgpu: migrate nixos-hardware to flake

Trying to reduce external input dependencies.

- nixos/theme: init theme module

- home/theme: refactor cursor and icon

Moving ownership of generic theme elements to theme module

- wshowkeys: use module again

- flake.lock: update

- flake.lock: update

- flake.lock: update

- waybar: disable cava module

audio glitches....

- wlroots: nixpkgs-wayland wshowkeys

- flake.lock: update

- flake.lock: update

- flake.nix: remove snowfall-frost and thaw

- flake.lock: update

- flake.lock: update

Reduce amount of overlays

- darwin: missed nixpkgs-fmt -> nixfmt-rfc-style

- flake.lock: update

- wshowkeys: use module

- hyprland: disable scaling on xwayland

- flake.lock: update

- flake.lock: update

- hyprland: refactor keybinds

- khanelinix: boomer scaling

- hyprland: setup advantage keybinds

- zellij: disable for now

Just got a new keyboard and trying to learn how to use existing bindings
before learning an entire new workflow.

- flake.lock: update

- qt: platformtheme deprecation fix

- flake.lock: update

- khanelinix: remove ckb-next

- hyprland: setup advantage keybinds

- flake.lock: update

- flake.lock: update

- hyprland: explicit package reference from input

- hyprland: hyprlock recovery key update

- zellij: init

- waybar: more firefox window-rewrites

- flake.lock: update

- neovim/tagbar: change toggle keymap

- neovim/aerial: change toggle keymap

- neovim: undotree init

- flake.lock: update

- flake.lock: update

- yazi/plugins: credits

- sketchybar/weather: change defaults

- yazi/plugins: ouch for archive previews

- sketchybar/weather: change defaults

- firefox: remove floorp and bypass-paywalls

- overlays/nix-update: remove

- flake.lock: update

- yazi: openers with getExe

- yazi: preloaders and previewers update

- regreet: sway -> hyprland

- flake.lock: update

- yazi: keymap.toml -> nix

- hyprland: use wezterm

- flake.lock: update

- yazi: theme use catppuccin.nix

- yazi: theme.toml -> nix

- yazi: move settings to separate file

- yaba-helper: updates

- hyprpaper: always restart

- hyprland: gamemode script updates

- git: move ignoreRevsFile to local config

Throws error if file is missing... too much hassle to have global in
current git state.

- shells/java: init

- flake.lock: update

- hyprland: misc cleanup

- wezterm: warn_about_missing_glyphs=false

- hyprland: disable kanshi

- nixos/commong: disable tailscale

- overlays/yabai: lint fix

- flake.nix: lint fix

- .github/workflows: fmt match solution

- tmux: set-titles

- mini/starter: reorder recent files

- khanelinix: boot permissions

- git: remove git alias that blocks real command

- zsh: tweak completions

- flake.lock: update

- yabai: 7.0.4 -> 7.1.0

- mini: replace startify with mini.starter

- neorg: disable for now

Errors and dont really use

- .git-blame-ignore-revs: update

- chore: nixfmt solution

- treewide: nixpkgs-fmt -> nixfmt-rfc-style

- flake.lock: update

- flake.lock: update

- flake.lock: update

- flake.lock: update

- services/ddc: init

- neotest: change mapping

- conform: remove codespell

- flake.lock: update

- hyprland: windowrules fix ryujinx

- sops: update github access-token

- flake.lock: update

neotest error requiring nvim-nio

- flake.lock: update

- hyprland: systemd --all

- Update README.md
- tmux: terminal change to fix color issue in k9s

- .git-blame-ignore-revs: update

- chore: cleanup

- ranger: remove

- chore: cleanup

- firefox: move bypass-paywalls-clean to nur package

- flake.lock: update

- khanelinix: enable kubernetes tools

- devshells/dotnet: update to support more dotnet dev

- .git-blame-ignore-revs: init

- chore: remove unnecessary , options

- chore: lint cleanup

- flake.lock: update

- slack-term: create module

- twitch-tui: create module

- weather_config: move to waybar module

- wakatime: move secret to neovim and vscode modules

- fish: format functions

- flake.lock: update

- aliases: move gsed to shared

linux is already using this package for gsed, doesnt need to be
conditional

- user: nixre fix conflict

- user: profile.png converted to actual png

- hyprland: hyprlock immediate on keybind

- user: migrate settings to home-manager

- hyprlock: update theme

- flake.lock: update

- chore: lint cleanup

- keymappings: take ownership of generic buffer commands

- bufremove: handle remove all but current

- flake.lock: update

- neovim: /*lua*/ coverage

- yabai: 7.0.3 -> 7.0.4

- cmp: refine completion selection and insertion

- barbar: remove

- bufremove: init to handle removing single buffer

- nixvim: options => opts

- lualine: winbar ignore aerial

- flake.lock: update

- treesitter: move all grammarPackages to neovim

- chore: lint fix

- flake.lock: update

- hyprland: hyprlock unlock and relock keybind fix

- conform: disable codespell

Dumb behavior of breaking my source code on save...

- .luarc.json: init

- sketchybar: format config

- hyprland: try adding hyprlock focus fix keybind

- neotest: safeguard adding rustaceanvim adapter

- flake.lock: update

- hyprland: allow session lock restore

- hyprlock: hide cursor and ignore empty

- rustaceanvim: tweaks

- chore: cleanup

- dap: try adding bashdb

- dap: refactor

- rustaceanvim: move to new module

- neovim: dap wip

- neovim: backspace works like expected

- neovim: insert navigation keymaps

- waybar: hyprland window-rewrite add minecraft

- neotest: init

- nvtop: split into nvtopPackages.<arch>

- python: consolidate in home-manager

- node: consolidate in home-manager

- git: consolidate in home-manager

- comma: move to home-manager

- flake.nix: cleanup

- flake.lock: update

- flake.lock: update

- flake.lock: update

- chore: format fix

- flake.lock: update

- lualine: disable on certain buffers

- lualine: cleanup buffer tabline

- nixvim: use lualine for tabline

- nixvim: move nvim-web-devicons

- barbar: move keymappings to module

- darwin: dock layout

- flake.nix: disable neovim nightly, for now

- nixvim: buffer format toggle keymap

- nixvim: remove auto center on insert

- chore: lint cleanup

- nixvim: move project-nvim to new module

- nixvim: move aerial telescope keymap to aerial module

- nixvim: move noice telescope keymap to noice module

- nixvim: refactoring add telescope integration

- nixvim: notify and wilder -> noice

- nixvim: use rustaceanvim instead of just rust-analyser lsp

- flake.lock: update

- flake.lock: update

- hypr-socket-watch: use home-manager module

- chore: lint

- flake.nix: restructure inputs and overlays

- hypr_socket_watch: remove local package

- darwin/home: v3 deprecation warning

- nixvim: telescope keymaps moved and disable frecency

- chore: deadnix cleanup

- flake.nix: remove unused insecure programs

- snowfall-lib: v3 migration

- khanelinix: move kvm storage

- flake.lock: update

- hyprland: swap term bindings to match darwin

- jankyborders: use upstreamed pkg

- yabai: use upstreamed pkg

- chore: remove dead code

- hypr_socket_watch: disable temporarily

- nixvim: lsp-format conditional with conform

- flake.lock: follow nixpkgs again

- wlroots: remove swaylock

- hyprland: remove sway addons

- hypr_socket_watch: restructure dependencies calling

- flake.lock: update

- nixvim: treesitter add bicep grammar

- chore: remove sketchybar version overlay

- flake.lock: update

- skhd: cleanup executables

- jankyborders: bordersrc nix expression

- darwin: jankyborders brew -> nix

- flake.nix: configure nix fmt

- dependabot.yml: update
- build(deps): bump cachix/install-nix-action from 25 to 26

Bumps [cachix/install-nix-action](https://github.com/cachix/install-nix-action) from 25 to 26.
- [Release notes](https://github.com/cachix/install-nix-action/releases)
- [Commits](https://github.com/cachix/install-nix-action/compare/v25...v26)

---
updated-dependencies:
- dependency-name: cachix/install-nix-action
  dependency-type: direct:production
  update-type: version-update:semver-major
...

Signed-off-by: dependabot[bot] <support@github.com>
- chore: remove dead code

- flake.lock: update

- sketchybar: cpu color fix

- sketchybar: wifi popup fix and add details

- sketchybar: network use mach helper

- sketchyhelper: felix implementation and cpu update

- flake.lock: update

- gtk: remove XCURSOR explicit sessionVariables

Handled in the home.pointerCursor module

- theme: use capitalize function

Seems to be a catppuccin specific thing, though... need to break theme out into separate modules probably.

- sketchybar: 2.20.1-unstable -> 2.21.0

- yabai: 6.0.15 -> 7.0.2

- flake.lock: update

- hypridle: package set to flake output

- hyprlock: package set to flake output

- flake.lock: hyprland flakes dont follow nixpkgs

- chore: lint fix

- hyprpaper: use flake module

- nixvim: project-nvim telescope deprecation fix

- flake.lock: update

- ncspot: move to music suite

- mpd: hide behind linux check

- flake.lock: update

- Update README.md
- khanelinix: use sudo-rs

- flake.lock: update

- nixvim: dap

- nixvim: telescope keybinding updates

- nixvim: try conform-nvim

- nixvim: neotree open on first buffer

- nixvim: remove unused autocmds

- nixvim: show neo-tree on buffread

- nixvim: open minimap on buffread

- nixvim: cleanup keymapping conflicts

- nixvim: move keymappings closer to plugins

- nixvim: neo-tree visible hidden

- chore: consolidate nixvim plugins to plugins folder

- nixvim: nvim-colorizer keymapping and tweak

- nixvim: neo-tree tweaks

- nixvim: barbar tweak

- yazi: 0.2.3 -> 0.2.4

- Update README.md
- chore: cleanup

- yazi: border style

- yazi: tab keybinding updates

- ranger: commit bump

- yazi: move preset overrides to plugins folders

- yazi: keymap.toml taplo formatting

- nixvim: enable taplo lsp for toml

- yazi: plugins add smart-enter

- nixvim: project-nvim enable explicitly

- nixvim: startify tweaks

- nixvim: telescope project-nvim

- nixvim: telescope extensions added

- nixvim: lsp ccls update and disable clangd

- flake.lock: update

- nixvim: rust-analyzer updates

- flake.lock: update

- fastfetch: remove unused temp setting

- yabai: cleanup old border settings

- darwin: common suite tools

- fastfetch: clean up configs

- sketchybar: bump overlay commit

- flake.lock: update

- homebrew: remove cask tap again

- build(deps): bump DeterminateSystems/update-flake-lock from 20 to 21

Bumps [DeterminateSystems/update-flake-lock](https://github.com/determinatesystems/update-flake-lock) from 20 to 21.
- [Release notes](https://github.com/determinatesystems/update-flake-lock/releases)
- [Commits](https://github.com/determinatesystems/update-flake-lock/compare/v20...v21)

---
updated-dependencies:
- dependency-name: DeterminateSystems/update-flake-lock
  dependency-type: direct:production
  update-type: version-update:semver-major
...

Signed-off-by: dependabot[bot] <support@github.com>
- chore: nixpkgs-wayland fix upstreamed, use it again

- chore: flake lock update

- chore: cleanup old sketchybar config

- sketchybar: network cleanup

- chore: flake lock update

- sketchybar: spaces module cleanup

- sketchybar: apple module cleanup

- sketchybar: today module cleanup

- sketchybar: stats animation

- sketchybar: commit bump

- sketchybar: bluetooth add system_woke subscription

- sketchybar: wifi module cleanup

- sketchybar: volume module cleanup

- chore: flake lock update

- sketchybar: github module cleanup

- sketchybar: bluetooth module cleanup

- sketchybar: battery module cleanup

- sketchybar: brew fixes

- chore: neovim-nightly follows nixpkgs

- chore: flake lock update

- chore: lint cleanup

- sketchybar: more cleanup

- sketchybar: cleanup

- sketchybar: more right click refreshes

- sketchybar: popup toggle util

- sketchybar: enable right click refreshes

- sketchybar: reenable hotload

- sketchybar: update_freq tweaks

- sketchybar: cpu mach_helper

- sketchybar: overlay commit bump

- sketchybar: sketchybar.so check instead of directory check

- sketchybar: disable volume osd

- sketchybar: disable hotload trial

- sketchybar: use sbar.exec callbacks

- sketchybar: use sbarlua

- sketchybar: 2.20.1 -> master

- neovim: todoTelescope keybind update

- chore: flake lock update

- sketchybar: helper compiles

- sketchybar: clean up source paths

- chore: flake lock update

- yabai: 6.0.12 -> 6.0.15

- hyprlock: use screenshot with blur

- hyprlock: layout update

- hyprlock: tweak with new home-manager module updates

- chore: clean up flake input forks

- hyprland: swaylock -> hyprlock

- Revert "waybar: go back to nixpkgs-wayland"

This reverts commit 93e0343e744c8774b2b3ceed822d154321f1a84f.
Nixpkgs-wayland is currently not updating because of failing packages. Readd after its updated.

- waybar: go back to nixpkgs-wayland

- chore: flake lock update

- chore: flake lock update

- waybar: use new persistent workspace feature branch

- chore: lint fixes

- chore: flake lock update and workarounds for broken nixos-unstable and nixvim

- hypridle: use flake pkg

- hypridle: use hm-module from flake

- hyprland: use new hypridle instead of swayidle

- sketchybar: remove wifi and bluetooth aliases

- yabai: 6.0.11 -> 6.0.12

- regreet: use nixpkgs-wayland sway

- wlroots: wl-screenrec and wlr-randr use nixpkgs-wayland

- swaylock-effects: use nixpkgs-wayland

- firefox: bpc latest instead of versioned

- chore: flake lock update

- chore: flake lock update

- darwin: remove broken package reference

- nixvim: tagbar extraConfig -> settings

- chore: flake lock update

- nixvim: startify header update

- nixvim: manual todo matching -> todo-comments plugin

- dynamic-island-helper: create nix derivation

- sketchyhelper: create nix derivation

- chore: flake lock update

- yabai: 6.0.7 -> 6.0.11

- yazi: keymap update

- chore: flake lock update

- chore: sketchybar bump

- chore: flake lock update

- chore: flake lock update

- lint: cleanup

- wezterm: remove custom package

- nixvim: update which-key sections

- nixvim: remove scrolloff locking

- nixvim: neo-tree bump width

- feat: nixvim add notify and toggle formatting keymap

- refactor: cleanup ripgrep dependency

- refactor: neo-tree tweaks

- chore: disable wezterm building on wsl home

- feat: nixvim completions added

- feat: nixvim add wilder

- refactor: nixvim remove tabnine

- feat: nixvim toggleterm lazygit

- refactor: nixvim keymappings support optional attributes

- refactor: nixvim floatterm -> toggleterm

- chore: nixvim keymappings

- refactor: manual imports -> import non default nix files

- refactor: nixvim move gitsigns into file

- chore: update telescope keymappings

- chore: cleanup old nvim config

- feat: lsp-format all and fix nix

- refactor: codeium-vim -> codeium.nvim

- feat: nixvim add codeium

- feat: nixvim add lsp servers

- feat: sketchybar 2.20.0

- chore: deadnix cleanup

- feat: nixvim keymappings

- feat: nixvim add wakatime

- feat: nixvim general options

- feat: nixvim

- feat: yabai 6.0.7

- chore: flake lock update

- feat: git rebase again

- chore: update k9s home-manager config

- feat: waybar add systemd-failed-units

- chore: bump dotnet sdk version neovim

- chore: flake lock update and workarounds

- chore: flake lock update

- chore: flake lock update

Add overlays to compensate for broken packages.

- chore(deps): bump cachix/cachix-action from 13 to 14

Bumps [cachix/cachix-action](https://github.com/cachix/cachix-action) from 13 to 14.
- [Release notes](https://github.com/cachix/cachix-action/releases)
- [Commits](https://github.com/cachix/cachix-action/compare/v13...v14)

---
updated-dependencies:
- dependency-name: cachix/cachix-action
  dependency-type: direct:production
  update-type: version-update:semver-major
...

Signed-off-by: dependabot[bot] <support@github.com>
- chore(deps): bump cachix/install-nix-action from 24 to 25

Bumps [cachix/install-nix-action](https://github.com/cachix/install-nix-action) from 24 to 25.
- [Release notes](https://github.com/cachix/install-nix-action/releases)
- [Commits](https://github.com/cachix/install-nix-action/compare/v24...v25)

---
updated-dependencies:
- dependency-name: cachix/install-nix-action
  dependency-type: direct:production
  update-type: version-update:semver-major
...

Signed-off-by: dependabot[bot] <support@github.com>
- feat: yabai 6.0.4 -> 6.0.6

- chore: flake lock update

- chore: waybar overlay changed to upstream

- feat: waybar overlay for unreleased fix

- chore: flake lock update

- chore: white space cleanup

- chore: flake lock update

- feat: yabai 6.0.4

- chore: minor firefox userchrome styling setup

- refactor: darwin remove alacritty

- chore: flake lock update

- feat: firefox add browser toolbox

- refactor: clean up userchrome

- feat: sidebery instead of tabcenter

- feat: firefox gpu acceleration and hardware decoding options

- feat: khanelimac firefox battery tweaks

- chore: flake lock update

- chore: sketchybar.h update to latest

- chore: clean up overlays

- chore: flake lock update

- chore: wezterm update

- chore: sketchybar restart dynamic island on start

- chore: homebrew tap cleanup - api default support

- chore: flake lock update

- feat: dotnet devshell

- feat: angular devshell

- chore: flake lock update

- refactor: sway use package option

- refactor: wlogout nixos -> home-manager

- chore: flake lock update

- chore: deadnix

- chore: cava pkgs.emptyDirectory instead of null

- chore: flake lock update

- chore: clean up pinentry warnings

- chore: flake lock update

- feat: waybar libre office icons

- refactor: git workaround

- refactor: cdrom group using user config option

- refactor: use gerg spicetify

- refactor: use catppuccin pkg qt theme file

- refactor: git changes

- chore: flake lock update

- chore: comment out systems.modules.home

- chore: flake lock update

- chore: update sops.yaml

- wip

- chore(deps): bump cachix/install-nix-action from 23 to 24 (#60)

Bumps [cachix/install-nix-action](https://github.com/cachix/install-nix-action) from 23 to 24.
- [Release notes](https://github.com/cachix/install-nix-action/releases)
- [Commits](https://github.com/cachix/install-nix-action/compare/v23...v24)

---
updated-dependencies:
- dependency-name: cachix/install-nix-action
  dependency-type: direct:production
  update-type: version-update:semver-major
...

Signed-off-by: dependabot[bot] <support@github.com>
Co-authored-by: dependabot[bot] <49699333+dependabot[bot]@users.noreply.github.com>
- chore(deps): bump cachix/cachix-action from 12 to 13 (#59)

Bumps [cachix/cachix-action](https://github.com/cachix/cachix-action) from 12 to 13.
- [Release notes](https://github.com/cachix/cachix-action/releases)
- [Commits](https://github.com/cachix/cachix-action/compare/v12...v13)

---
updated-dependencies:
- dependency-name: cachix/cachix-action
  dependency-type: direct:production
  update-type: version-update:semver-major
...

Signed-off-by: dependabot[bot] <support@github.com>
Co-authored-by: dependabot[bot] <49699333+dependabot[bot]@users.noreply.github.com>
- chore(deps): bump actions/labeler from 4 to 5 (#58)

Bumps [actions/labeler](https://github.com/actions/labeler) from 4 to 5.
- [Release notes](https://github.com/actions/labeler/releases)
- [Commits](https://github.com/actions/labeler/compare/v4...v5)

---
updated-dependencies:
- dependency-name: actions/labeler
  dependency-type: direct:production
  update-type: version-update:semver-major
...

Signed-off-by: dependabot[bot] <support@github.com>
Co-authored-by: dependabot[bot] <49699333+dependabot[bot]@users.noreply.github.com>
- chore: disable nix flake check for now

- chore: lint fix

- chore: flake lock update

- refactor: move betterdiscord theme to home-manager

- refactor: cleanup khanelinix services

- refactor: nix-ld -> nix-ld-rs

- chore: flake lock update and remove overlay

- chore: lint cleanup

- chore: flake lock update

- refactor: move cava to home-manager module

- chore: flake lock update

- refactor: go back to swaylock-effects (correct fork)

- chore: deadnix cleanup

- refactor: swayidle use nixpkgs-wayland

- refactor: wlroots suite use nixpkgs-wayland

- refactor: use nixpkgs-wayland wlogout

- refactor: nixify qt config

- refactor: move hyprland polish to appendConfig

- refactor: gtk reorganize

- chore: cleanup remaining sfmono

- refactor: move displays.conf to prependConfig hyprland

- chore: remove duplicate qt session variable

- feat: hyprland numlock by default

- chore: wezterm bump

- chore: cleanup gitignore result

- chore: cleanup overlay after nixpkgs update

- chore: remove upstreamed swayidle systemdTarget

- refactor: try upstream swaylock again

- refactor: try locking swaylock differently

- refactor: use new firefox policies option

- chore: flake lock update

- refactor: gnome firefox support

- refactor: move firefox config to home module

- chore: Remove dead code (#54)

Co-authored-by: khaneliman <khaneliman@users.noreply.github.com>
- chore: flake lock update

- refactor: argon -> neon

- feat: monaspace nerd font

- chore: flake lock update

- chore: hyprland environment variable update

- chore: flake lock update

- feat: replace radeontop with amdgpu_top

- feat: file manager updates

- chore: flake lock update

- chore: misc mac cleanup

- chore: flake lock update

- chore: lsp language comments for nix expressions

- chore: networking tweaks

- chore: cleanup amdgpu

- chore: 1password-gui stable

- chore: flake lock update

- chore: manual dynamic island cleanup

- chore: lint fix

- chore: flake lock update

- refactor: sketchybar theme

- feat: yazi catppuccin theme

- feat: yazi layout customization

- chore: dynamic island sketchybar update

- chore: cleanup sketchybar colors.sh usage

- refactor: tweak caprine styling more

- feat: jankyborders homebrew

- chore: flake lock update and workarounds for broken packages

- feat: wezterm git package

- chore: remove monaspace overlay

- chore: remove yabai overlay

- feat: multiple neovim configs

- chore: deadnix

- chore: flake lock update

- feat: macos overlays until nixpkgs updated

- feat: monaspace font

- feat: rofi enhancements

- chore: flake lock update

- chore: flake lock update and fastfetch workaround

- feat: nvidialess specialization

- chore: flake lock update

- chore: remove unnecessary spicetify-cli module

- feat: shell improvements

- feat: retroarch core updates and full option

- chore: flake lock update (breaking changes)

- feat: fzf module

- chore: key input timeout removal

- chore: sway lazy man timeouts

- feat: kitty add shell integration

- chore: flake lock update

- chore: cleanup unnecessary scratchpad exec-once

- feat: hyprland default app workspace rules

- feat: hyprland named specials

- chore: flake lock update

- feat: thunderbird reminders pinned upper right

- feat: hyprland new tmux terminal bind

- chore: flake.lock: Update (#40)

Flake lock file updates:

• Updated input 'home-manager':
    'github:nix-community/home-manager/c5c1ea85181d2bb44e46e8a944a8a3f56ad88f19' (2023-10-19)
  → 'github:nix-community/home-manager/ae631b0b20f06f7d239d160723d228891ddb2fe0' (2023-10-20)
• Updated input 'hyprland':
    'github:hyprwm/Hyprland/bb9d0aed5bd11879f5a532e26fc0a91d1a8af714' (2023-10-20)
  → 'github:hyprwm/Hyprland/4a79718fe8e4601983797d254cce39960827cb02' (2023-10-20)
• Updated input 'nixpkgs':
    'github:nixos/nixpkgs/ca012a02bf8327be9e488546faecae5e05d7d749' (2023-10-16)
  → 'github:nixos/nixpkgs/7c9cc5a6e5d38010801741ac830a3f8fd667a7a0' (2023-10-19)
• Updated input 'nixpkgs-master':
    'github:nixos/nixpkgs/a0961ec2b7a4c7014a6233a290883e33ea0db04d' (2023-10-20)
  → 'github:nixos/nixpkgs/28eb936285ed02bbd53e3771f1e0153ced640c44' (2023-10-20)
• Updated input 'nixpkgs-wayland':
    'github:nix-community/nixpkgs-wayland/fad6dabaa830ba040cdbebf685c1de476285f1f2' (2023-10-20)
  → 'github:nix-community/nixpkgs-wayland/95eccd7ecead085fb419309dc9f351a3d252aaa7' (2023-10-20)
• Updated input 'nur':
    'github:nix-community/NUR/d531cd7ef0001eaba84743d6666726df3c3b5620' (2023-10-20)
  → 'github:nix-community/NUR/5275d02ba283b544d714ede2d5c8b846854af3f3' (2023-10-20)

Co-authored-by: github-actions[bot] <github-actions[bot]@users.noreply.github.com>
- chore: Remove dead code (#42)

Co-authored-by: khaneliman <khaneliman@users.noreply.github.com>
- chore: remove dooit overlay and add to nixos

- refactor: modularize waybar css

- feat: waybar hyprland workspaces styling change

- chore: flake lock update

- chore: remove custom waybar overlay

This reverts commit dfac919656d50196f4fa69f3d09eeacff5211537.

- refactor: waybar module refactor

- feat: waybar css updates

- feat: temporary waybar overlay with fixes

- chore: flake.lock: Update (#39)

Flake lock file updates:

• Updated input 'home-manager':
    'github:nix-community/home-manager/78125bc681d12364cb65524eaa887354134053d0' (2023-10-15)
  → 'github:nix-community/home-manager/3433206e51766b4164dad368a81325efbf343fbe' (2023-10-18)
• Updated input 'hyprland':
    'github:hyprwm/Hyprland/54e1c2ccbdfa6dfade63221b5df02bf8578d96a6' (2023-10-16)
  → 'github:hyprwm/Hyprland/d70cc88dab11bc6d1095523a0ce655dff40b27a2' (2023-10-18)
• Updated input 'nixpkgs':
    'github:nixos/nixpkgs/5e4c2ada4fcd54b99d56d7bd62f384511a7e2593' (2023-10-11)
  → 'github:nixos/nixpkgs/ca012a02bf8327be9e488546faecae5e05d7d749' (2023-10-16)
• Updated input 'nixpkgs-wayland':
    'github:nix-community/nixpkgs-wayland/86615cbbddb6797ca143a24cfd36941cb9255f14' (2023-10-16)
  → 'github:nix-community/nixpkgs-wayland/6fc186ae56a3debdd628c0e4df9e133e46299866' (2023-10-18)
• Updated input 'nur':
    'github:nix-community/NUR/998d09217e50c2c30ac41c4f3c8ddfc83427ffb2' (2023-10-16)
  → 'github:nix-community/NUR/6b779ecc1afe9d3709d718c613136f56b3ac8b52' (2023-10-18)
• Updated input 'rustup-overlay':
    'github:oxalica/rust-overlay/056256f2fcf3c5a652dbc3edba9ec1a956d41f56' (2023-10-16)
  → 'github:oxalica/rust-overlay/a2ccfb2134622b28668a274e403ba6f075ae1223' (2023-10-18)

Co-authored-by: github-actions[bot] <github-actions[bot]@users.noreply.github.com>
- feat: darwin tmux skhd update

- chore: remove git safe directory

- refactor: git pull ff again remove whitespace override

- refactor: remove tmux always on init, move to keybind

- refactor: hyprland persistent workspace instead of waybar

- chore: remove dead code (#38)

Co-authored-by: khaneliman <khaneliman@users.noreply.github.com>
- refactor: move obs to home-manager

- chore: flake.lock: Update (#37)

Flake lock file updates:

• Updated input 'nur':
    'github:nix-community/NUR/cc83a858d3dbf50a934a4f74fe5508ac2fa72bc5' (2023-10-16)
  → 'github:nix-community/NUR/998d09217e50c2c30ac41c4f3c8ddfc83427ffb2' (2023-10-16)

Co-authored-by: github-actions[bot] <github-actions[bot]@users.noreply.github.com>
- chore: sort waybar module definitions

- chore: flake.lock: Update (#36)

* chore: flake.lock: Update

Flake lock file updates:

• Updated input 'home-manager':
    'github:nix-community/home-manager/d4a5076ea8c2c063c45e0165f9f75f69ef583e20' (2023-10-14)
  → 'github:nix-community/home-manager/78125bc681d12364cb65524eaa887354134053d0' (2023-10-15)
• Updated input 'hyprland':
    'github:hyprwm/Hyprland/261c594458fec8bc64136eebf7c7e4e5ab421907' (2023-10-14)
  → 'github:hyprwm/Hyprland/8af3e7beebb96eceb8a094a20286d57e3b135938' (2023-10-15)
• Updated input 'nixpkgs-wayland':
    'github:nix-community/nixpkgs-wayland/6b428305043afaf77119adb44dfea246c809e07f' (2023-10-14)
  → 'github:nix-community/nixpkgs-wayland/0eaba2ea36991eeb0b6c7c5b97c6270c7aecfb9c' (2023-10-15)
• Updated input 'nixpkgs-wayland/lib-aggregate':
    'github:nix-community/lib-aggregate/9f495e4feea66426589cbb59ac8b972993b5d872' (2023-10-08)
  → 'github:nix-community/lib-aggregate/af42578368ca0c97d5836ba55b146745911aaecc' (2023-10-15)
• Updated input 'nixpkgs-wayland/lib-aggregate/nixpkgs-lib':
    'github:nix-community/nixpkgs.lib/59da6ac0c02c48aa92dee37057f978412797db2a' (2023-10-08)
  → 'github:nix-community/nixpkgs.lib/05c07c73de74725ec7efa6609011687035a92c0f' (2023-10-15)
• Updated input 'nur':
    'github:nix-community/NUR/a7f7dc7099baec26335cb9335e0adfc3d838e098' (2023-10-15)
  → 'github:nix-community/NUR/366ab72bab2a056be9834de1270132072c83f574' (2023-10-15)
• Updated input 'yubikey-guide':
    'github:drduh/YubiKey-Guide/4a641dffd002e8132bcbbcd46089acfa2040c749' (2023-08-13)
  → 'github:drduh/YubiKey-Guide/703c6aa37f45b68ec872de08d064a31aac8ffa93' (2023-10-15)

* feat: waybar animation overhaul

* refactor: waybar modules separated into nix expressions

---------

Co-authored-by: github-actions[bot] <github-actions[bot]@users.noreply.github.com>
Co-authored-by: Austin Horstman <khaneliman12@gmail.com>
- chore: copy pasta cleanup

- chore: flake.lock: Update (#35)

chore: flake.lock: Update

Flake lock file updates:

• Updated input 'home-manager':
    'github:nix-community/home-manager/6bba64781e4b7c1f91a733583defbd3e46b49408' (2023-10-10)
  → 'github:nix-community/home-manager/d4a5076ea8c2c063c45e0165f9f75f69ef583e20' (2023-10-14)
• Updated input 'hyprland':
    'github:hyprwm/Hyprland/424c9a7e704590db5c823557e5e388e366f7b1cd' (2023-10-13)
  → 'github:hyprwm/Hyprland/261c594458fec8bc64136eebf7c7e4e5ab421907' (2023-10-14)
• Updated input 'nixpkgs-wayland':
    'github:nix-community/nixpkgs-wayland/7dcd2934b3cf761471d5e9bab8d8fb0d50ab2bca' (2023-10-13)
  → 'github:nix-community/nixpkgs-wayland/6b428305043afaf77119adb44dfea246c809e07f' (2023-10-14)
• Updated input 'nur':
    'github:nix-community/NUR/25fedce20d4b0671adeefa9d52f6b69079af84c0' (2023-10-13)
  → 'github:nix-community/NUR/00cf27339d55115a0f5311041dded91049e4426d' (2023-10-14)
• Updated input 'rustup-overlay':
    'github:oxalica/rust-overlay/b48a7e5dab1b472dd9c9ee9053401489dbb4d6fc' (2023-10-13)
  → 'github:oxalica/rust-overlay/dce60ca7fca201014868c08a612edb73a998310f' (2023-10-14)
• Updated input 'sops-nix':
    'github:Mic92/sops-nix/f995ea159252a53b25fa99824f2891e3b479d511' (2023-10-11)
  → 'github:Mic92/sops-nix/7711514b8543891eea6ae84392c74a379c5010de' (2023-10-14)

Co-authored-by: github-actions[bot] <github-actions[bot]@users.noreply.github.com>
- chore: cleanup code length theme module

- refactor: move bat and delta theme to theme module

- refactor: move tmux catppuccin to theme module

- chore: fromyaml runcommand naming

- chore: flake.lock: Update (#34)

Flake lock file updates:

• Updated input 'hyprland':
    'github:hyprwm/Hyprland/3a61350286de842c7f1566c38e2b42821080ddf4' (2023-10-12)
  → 'github:hyprwm/Hyprland/424c9a7e704590db5c823557e5e388e366f7b1cd' (2023-10-13)
• Updated input 'nixpkgs-wayland':
    'github:nix-community/nixpkgs-wayland/b3a13eac46963b8f5343d481a282d92df0d39e06' (2023-10-13)
  → 'github:nix-community/nixpkgs-wayland/7dcd2934b3cf761471d5e9bab8d8fb0d50ab2bca' (2023-10-13)
• Updated input 'nur':
    'github:nix-community/NUR/527c0fa45b385206d5c6e6bbed7e1a6ad096fda9' (2023-10-13)
  → 'github:nix-community/NUR/25fedce20d4b0671adeefa9d52f6b69079af84c0' (2023-10-13)

Co-authored-by: github-actions[bot] <github-actions[bot]@users.noreply.github.com>
- chore: secret update

- feat: lsd custom aliases

- refactor: break git aliases out into separate module

- feat: try to arrange calendar reminder notifications

- refactor: development tui to home

- refactor: move social tui to home packages

- refactor: sops json -> yaml

- feat: twitch-tui

- chore: remove unused hyprland variable

- feat: git diff-so-fancy -> delta

- refactor: bottom uses new theme package

- refactor: k9s use new theme package

- refactor: btop use new theme package

- refactor: lazygit use new theme package

- refactor: bat theme attribute set new package

- chore: flake.lock: Update (#33)

chore: flake.lock: Update

Flake lock file updates:

• Updated input 'hyprland':
    'github:hyprwm/Hyprland/06cc42441cd5b24444f7c79495851dedde8bc732' (2023-10-11)
  → 'github:hyprwm/Hyprland/3a61350286de842c7f1566c38e2b42821080ddf4' (2023-10-12)
• Updated input 'neovim-config':
    'github:khaneliman/khanelivim/e4f338261ee4c5086a577f3b57f3e66c42074def' (2023-10-09)
  → 'github:khaneliman/khanelivim/76c4249afaada3a35c1c2eb84ffce0c25592c196' (2023-10-12)
• Updated input 'nixpkgs-wayland':
    'github:nix-community/nixpkgs-wayland/8ca67f97319a954d41e08e65bbbd9b4552f81e05' (2023-10-12)
  → 'github:nix-community/nixpkgs-wayland/090c471a5bf3e137c106df899a5abdd9af6a586f' (2023-10-12)
• Updated input 'nur':
    'github:nix-community/NUR/c324f1bd5ad41d63a4721f08760480e346fbff0c' (2023-10-12)
  → 'github:nix-community/NUR/9652d4b7c5c05d982e69d1c9df8d05010d431ba0' (2023-10-12)

Co-authored-by: github-actions[bot] <github-actions[bot]@users.noreply.github.com>
- feat: hyprland thunderbird reminder rules

- feat: lsof

- chore: Remove dead code (#30)


- chore: flake.lock update

Flake lock file updates:

• Updated input 'hyprland':
    'github:hyprwm/Hyprland/d83357f4976a240a4418a1a0a16641518a47da25' (2023-10-10)
  → 'github:hyprwm/Hyprland/06cc42441cd5b24444f7c79495851dedde8bc732' (2023-10-11)
• Updated input 'nixos-hardware':
    'github:nixos/nixos-hardware/c2bbfcfc3d12351919f8df7c7d6528f41751d0a3' (2023-10-10)
  → 'github:nixos/nixos-hardware/d6b554a85caac840430a822aae963c811e9c7e26' (2023-10-11)
• Updated input 'nixpkgs-wayland':
    'github:nix-community/nixpkgs-wayland/a86a11dea571a2e757295aabd4e085d3aff7dd23' (2023-10-10)
  → 'github:nix-community/nixpkgs-wayland/941e5c403f01de6161c7d233845d309c64d021a6' (2023-10-11)
• Updated input 'nur':
    'github:nix-community/NUR/6b1a5fb1a213d7daf13f3af6757321a288876d59' (2023-10-10)
  → 'github:nix-community/NUR/9e3dfb3a12fc0be2722bb4a58c25656f5eae3915' (2023-10-11)
• Updated input 'rustup-overlay':
    'github:oxalica/rust-overlay/c0df7f2a856b5ff27a3ce314f6d7aacf5fda546f' (2023-10-09)
  → 'github:oxalica/rust-overlay/c6d2f0bbd56fc833a7c1973f422ca92a507d0320' (2023-10-11)
• Updated input 'sops-nix':
    'github:Mic92/sops-nix/6b32358c22d2718a5407d39a8236c7bd9608f447' (2023-10-09)
  → 'github:Mic92/sops-nix/f995ea159252a53b25fa99824f2891e3b479d511' (2023-10-11)

- feat: 1password home config

- feat: darwin ssh setup

- refactor: nixos mdns

- feat: darwin networking disable stealth

- feat: khanelimac ssh config

- feat: hyprpaper service to handle crashes

- flake.lock: Update

Flake lock file updates:

• Updated input 'home-manager':
    'github:nix-community/home-manager/3c1d8758ac3f55ab96dcaf4d271c39da4b6e836d' (2023-10-08)
  → 'github:nix-community/home-manager/6bba64781e4b7c1f91a733583defbd3e46b49408' (2023-10-10)
• Updated input 'hyprland':
    'github:hyprwm/Hyprland/499df49f7b28f9e3be9b1c53843fd5c465dec60b' (2023-10-08)
  → 'github:hyprwm/Hyprland/d83357f4976a240a4418a1a0a16641518a47da25' (2023-10-10)
• Updated input 'neovim-config':
    'github:khaneliman/khanelivim/4ee64fd7b218c0fda4727f3b09a32617d0b22314' (2023-10-08)
  → 'github:khaneliman/khanelivim/e4f338261ee4c5086a577f3b57f3e66c42074def' (2023-10-09)
• Updated input 'nixos-hardware':
    'github:nixos/nixos-hardware/bb2db418b616fea536b1be7f6ee72fb45c11afe0' (2023-10-06)
  → 'github:nixos/nixos-hardware/c2bbfcfc3d12351919f8df7c7d6528f41751d0a3' (2023-10-10)
• Updated input 'nixos-wsl':
    'github:nix-community/nixos-wsl/337edef90c8abe35b42e95aecf510a063dad02dd' (2023-10-02)
  → 'github:nix-community/nixos-wsl/5da7c4fd0ab9693d83cae50de7d9430696f92568' (2023-10-09)
• Updated input 'nixos-wsl/flake-compat':
    'github:edolstra/flake-compat/35bb57c0c8d8b62bbfd284272c928ceb64ddbde9' (2023-01-17)
  → 'github:edolstra/flake-compat/0f9255e01c2351cc7d116c072cb317785dd33b33' (2023-10-04)
• Updated input 'nixpkgs':
    'github:nixos/nixpkgs/87828a0e03d1418e848d3dd3f3014a632e4a4f64' (2023-10-06)
  → 'github:nixos/nixpkgs/f99e5f03cc0aa231ab5950a15ed02afec45ed51a' (2023-10-09)
• Updated input 'nixpkgs-wayland':
    'github:nix-community/nixpkgs-wayland/6713cae5c550a7a68ac0bca534ec4e92585c9200' (2023-10-08)
  → 'github:nix-community/nixpkgs-wayland/a86a11dea571a2e757295aabd4e085d3aff7dd23' (2023-10-10)
• Updated input 'nixpkgs-wayland/nix-eval-jobs':
    'github:nix-community/nix-eval-jobs/26af7cabdb7ee637dc9b63f1ce609a467534713c' (2023-10-07)
  → 'github:nix-community/nix-eval-jobs/7cdbfd5ffe59fe54fd5c44be96f58c45e25d5b62' (2023-10-09)
• Updated input 'nixpkgs-wayland/nix-eval-jobs/nixpkgs':
    'github:NixOS/nixpkgs/c52af267ad0c11b55f89cf6c70adb10694ad938e' (2023-10-05)
  → 'github:NixOS/nixpkgs/35c640b19a189ce3a86698ce2fdcd87d085a339b' (2023-10-09)
• Updated input 'nur':
    'github:nix-community/NUR/e59a27dcfd30d62a5927fe9f89c273cc15d09c47' (2023-10-08)
  → 'github:nix-community/NUR/6b1a5fb1a213d7daf13f3af6757321a288876d59' (2023-10-10)
• Updated input 'rustup-overlay':
    'github:oxalica/rust-overlay/6528a18a62d817200099c520b6eea7833ade9a9a' (2023-10-08)
  → 'github:oxalica/rust-overlay/c0df7f2a856b5ff27a3ce314f6d7aacf5fda546f' (2023-10-09)
• Updated input 'sops-nix':
    'github:Mic92/sops-nix/d7380c38d407eaf06d111832f4368ba3486b800e' (2023-10-08)
  → 'github:Mic92/sops-nix/6b32358c22d2718a5407d39a8236c7bd9608f447' (2023-10-09)

- Update README.md
- flake.lock: Update

Flake lock file updates:

• Updated input 'home-manager':
    'github:nix-community/home-manager/b2a2133c9a0b0aa4d06d72b5891275f263ee08df' (2023-10-06)
  → 'github:nix-community/home-manager/3c1d8758ac3f55ab96dcaf4d271c39da4b6e836d' (2023-10-08)
• Updated input 'hyprland':
    'github:hyprwm/Hyprland/728a8bb48e0f7de1cbe1ad13fb469754c3d0bc97' (2023-10-07)
  → 'github:hyprwm/Hyprland/499df49f7b28f9e3be9b1c53843fd5c465dec60b' (2023-10-08)
• Updated input 'neovim-config':
    'github:khaneliman/khanelivim/a40cc29bb465bbcb84d1daa17afac055fb639687' (2023-10-06)
  → 'github:khaneliman/khanelivim/4ee64fd7b218c0fda4727f3b09a32617d0b22314' (2023-10-08)
• Updated input 'nixpkgs-wayland':
    'github:nix-community/nixpkgs-wayland/ac7584ae702177c9f6f4a5e52550f7c2fcea29b9' (2023-10-07)
  → 'github:nix-community/nixpkgs-wayland/6713cae5c550a7a68ac0bca534ec4e92585c9200' (2023-10-08)
• Updated input 'nixpkgs-wayland/lib-aggregate':
    'github:nix-community/lib-aggregate/273cc814826475216b2a8aa008697b939e784514' (2023-10-01)
  → 'github:nix-community/lib-aggregate/9f495e4feea66426589cbb59ac8b972993b5d872' (2023-10-08)
• Updated input 'nixpkgs-wayland/lib-aggregate/nixpkgs-lib':
    'github:nix-community/nixpkgs.lib/56992d3dfd3b8cee5c5b5674c1a477446839b6ad' (2023-10-01)
  → 'github:nix-community/nixpkgs.lib/59da6ac0c02c48aa92dee37057f978412797db2a' (2023-10-08)
• Updated input 'nur':
    'github:nix-community/NUR/975896ef9edb4539c040ea28ecebd7a2a12a5dd0' (2023-10-07)
  → 'github:nix-community/NUR/e59a27dcfd30d62a5927fe9f89c273cc15d09c47' (2023-10-08)
• Updated input 'rustup-overlay':
    'github:oxalica/rust-overlay/126829788e99c188be4eeb805f144d73d8a00f2c' (2023-10-07)
  → 'github:oxalica/rust-overlay/6528a18a62d817200099c520b6eea7833ade9a9a' (2023-10-08)
• Updated input 'sops-nix':
    'github:Mic92/sops-nix/746c7fa1a64c1671a4bf287737c27fdc7101c4c2' (2023-10-03)
  → 'github:Mic92/sops-nix/d7380c38d407eaf06d111832f4368ba3486b800e' (2023-10-08)
• Updated input 'sops-nix/nixpkgs-stable':
    'github:NixOS/nixpkgs/dbe90e63a36762f1fbde546e26a84af774a32455' (2023-10-01)
  → 'github:NixOS/nixpkgs/2f3b6b3fcd9fa0a4e6b544180c058a70890a7cc1' (2023-10-07)

- refactor: rename neovim config again

- chore: remove nixpkgs-khanelinix again

- feat: lazygit catppuccin

- chore: lint fix

- flake.lock: Update

Flake lock file updates:

• Updated input 'hyprland':
    'github:hyprwm/Hyprland/61d3d4dee7a4f9f68b4e7dd1e77ccd9acbed9a7c' (2023-10-06)
  → 'github:hyprwm/Hyprland/728a8bb48e0f7de1cbe1ad13fb469754c3d0bc97' (2023-10-07)
• Updated input 'nixpkgs':
    'github:nixos/nixpkgs/81e8f48ebdecf07aab321182011b067aafc78896' (2023-10-03)
  → 'github:nixos/nixpkgs/87828a0e03d1418e848d3dd3f3014a632e4a4f64' (2023-10-06)
• Updated input 'nixpkgs-khanelinix':
    'github:khaneliman/nixpkgs/51d261b0aed53b56dd4a658a05c9ed6b937eb731' (2023-10-06)
  → 'github:khaneliman/nixpkgs/d09cd1d7d177a30af5b2efbbc853842b6af9f546' (2023-10-07)
• Updated input 'nixpkgs-wayland':
    'github:nix-community/nixpkgs-wayland/53e525b2ee8d84bab4db3e90a7b94db51249d393' (2023-10-06)
  → 'github:nix-community/nixpkgs-wayland/ac7584ae702177c9f6f4a5e52550f7c2fcea29b9' (2023-10-07)
• Updated input 'nixpkgs-wayland/nix-eval-jobs':
    'github:nix-community/nix-eval-jobs/6841d05ad796d57ecb34e8f5a3910f8fe5211b84' (2023-10-05)
  → 'github:nix-community/nix-eval-jobs/26af7cabdb7ee637dc9b63f1ce609a467534713c' (2023-10-07)
• Updated input 'nur':
    'github:nix-community/NUR/b5bfec93605030aa492e339fd60ad00bdc9492ed' (2023-10-06)
  → 'github:nix-community/NUR/975896ef9edb4539c040ea28ecebd7a2a12a5dd0' (2023-10-07)
• Updated input 'rustup-overlay':
    'github:oxalica/rust-overlay/fdb37574a04df04aaa8cf7708f94a9309caebe2b' (2023-10-06)
  → 'github:oxalica/rust-overlay/126829788e99c188be4eeb805f144d73d8a00f2c' (2023-10-07)

- refactor: hyprland home-manager module systemd handles environment variables now

- flake.lock: Update

Flake lock file updates:

• Updated input 'home-manager':
    'github:nix-community/home-manager/68f7d8c0fb0bfc67d1916dd7f06288424360d43a' (2023-10-04)
  → 'github:nix-community/home-manager/b2a2133c9a0b0aa4d06d72b5891275f263ee08df' (2023-10-06)
• Updated input 'hyprland':
    'github:hyprwm/Hyprland/1afb00a01b7cab3e68f5af3ca6a7d7d86b8f913e' (2023-10-06)
  → 'github:hyprwm/Hyprland/61d3d4dee7a4f9f68b4e7dd1e77ccd9acbed9a7c' (2023-10-06)
• Updated input 'nixos-hardware':
    'github:nixos/nixos-hardware/f4ef5df944429e2ce3308bdbe69da940fffc5942' (2023-10-06)
  → 'github:nixos/nixos-hardware/bb2db418b616fea536b1be7f6ee72fb45c11afe0' (2023-10-06)
• Updated input 'nixpkgs':
    'github:nixos/nixpkgs/fdd898f8f79e8d2f99ed2ab6b3751811ef683242' (2023-10-01)
  → 'github:nixos/nixpkgs/81e8f48ebdecf07aab321182011b067aafc78896' (2023-10-03)
• Updated input 'nixpkgs-wayland':
    'github:nix-community/nixpkgs-wayland/23e99072b523607ee4748a896b041e9a6f3ab1b6' (2023-10-06)
  → 'github:nix-community/nixpkgs-wayland/53e525b2ee8d84bab4db3e90a7b94db51249d393' (2023-10-06)
• Updated input 'nur':
    'github:nix-community/NUR/e9db143072899753216cd84143489ed2a544e793' (2023-10-06)
  → 'github:nix-community/NUR/b5bfec93605030aa492e339fd60ad00bdc9492ed' (2023-10-06)

- chore: update renamed neovim repo

- chore: flake lock update

- Remove dead code

- refactor: hide op-ssh-sign behind feature flag

- refactor: mkBoolOpt git

- refactor: dont use op-ssh-sign

- feat: 1password-gui-beta attempt workaround

- chore: sort hyprland variables

- feat: waybar window-rewrite setup

- chore: python3 instead of python311 explicitly

- chore: remove nixpkgs fork again

- flake.lock: Update

Flake lock file updates:

• Updated input 'darwin':
    'github:lnl7/nix-darwin/792c2e01347cb1b2e7ec84a1ef73453ca86537d8' (2023-09-30)
  → 'github:lnl7/nix-darwin/8b6ea26d5d2e8359d06278364f41fbc4b903b28a' (2023-10-03)
• Updated input 'home-manager':
    'github:nix-community/home-manager/6f9b5b83ad1f470b3d11b8a9fe1d5ef68c7d0e30' (2023-10-01)
  → 'github:nix-community/home-manager/68f7d8c0fb0bfc67d1916dd7f06288424360d43a' (2023-10-04)
• Updated input 'hyprland':
    'github:hyprwm/Hyprland/b784931e678f907b1f1e41d04485fefd8a1faaf8' (2023-10-02)
  → 'github:hyprwm/Hyprland/1b99a69dc11c3c8266559c3c20b2f4dac6621dcc' (2023-10-04)
• Updated input 'hyprland/wlroots':
    'gitlab:wlroots/wlroots/5ef42e8e8adece098848fac53c721b6eb3818fc2' (2023-10-02)
  → 'gitlab:wlroots/wlroots/3406c1b17a4a7e6d4e2a7d9c1176affa72bce1bc' (2023-10-04)
• Updated input 'hyprland-contrib':
    'github:hyprwm/contrib/33663f663e07b4ca52c9165f74e3d793f08b15e7' (2023-09-23)
  → 'github:hyprwm/contrib/2e3f8ac2a3f1334fd2e211b07ed76b4215bb0542' (2023-10-03)
• Updated input 'neovim-config':
    'github:khaneliman/astronvim/ab840c25072ff5ef5bee6aee3565a59a4126607b' (2023-09-24)
  → 'github:khaneliman/astronvim/37d69ee0e9cc4f82b2871ca30851e10709885f50' (2023-10-03)
• Updated input 'nixpkgs':
    'github:nixos/nixpkgs/f5892ddac112a1e9b3612c39af1b72987ee5783a' (2023-09-29)
  → 'github:nixos/nixpkgs/fdd898f8f79e8d2f99ed2ab6b3751811ef683242' (2023-10-01)
• Updated input 'nixpkgs-wayland':
    'github:nix-community/nixpkgs-wayland/a734b5414e55cbe8a0ac1f4e79bb5c290d45f1d6' (2023-10-02)
  → 'github:nix-community/nixpkgs-wayland/fe7ca23b2e28cda8eac1d0d4d7984acd99885c79' (2023-10-04)
• Updated input 'nur':
    'github:nix-community/NUR/e91591b0854baca7bc1a90c6d74181dba079b174' (2023-10-02)
  → 'github:nix-community/NUR/330ca7d24da8e5e6af288b54fb1de105609ed14d' (2023-10-04)
• Updated input 'rustup-overlay':
    'github:oxalica/rust-overlay/1aaa2dc3e7367f2014f939c927e9e768a0cc2f08' (2023-10-02)
  → 'github:oxalica/rust-overlay/f144d5022c94a893d14c2b0e632672935dc83662' (2023-10-04)
• Updated input 'snowfall-lib':
    'github:snowfallorg/lib/83e7839dd1aaa7694b88f50963716dc1bc5de371' (2023-09-16)
  → 'github:snowfallorg/lib/92803a029b5314d4436a8d9311d8707b71d9f0b6' (2023-10-04)
• Updated input 'snowfall-lib/flake-utils-plus':
    'github:gytis-ivaskevicius/flake-utils-plus/2bf0f91643c2e5ae38c1b26893ac2927ac9bd82a' (2022-07-07)
  → 'github:gytis-ivaskevicius/flake-utils-plus/bfc53579db89de750b25b0c5e7af299e0c06d7d3' (2023-10-03)
• Updated input 'snowfall-lib/flake-utils-plus/flake-utils':
    'github:numtide/flake-utils/3cecb5b042f7f209c56ffd8371b2711a290ec797' (2022-02-07)
  → 'github:numtide/flake-utils/ff7b65b44d01cf9ba6a71320833626af21126384' (2023-09-12)
• Added input 'snowfall-lib/flake-utils-plus/flake-utils/systems':
    'github:nix-systems/default/da67096a3b9bf56a91d16901293e51ba5b49a27e' (2023-04-09)
• Updated input 'sops-nix':
    'github:Mic92/sops-nix/2f375ed8702b0d8ee2430885059d5e7975e38f78' (2023-09-21)
  → 'github:Mic92/sops-nix/746c7fa1a64c1671a4bf287737c27fdc7101c4c2' (2023-10-03)
• Updated input 'sops-nix/nixpkgs-stable':
    'github:NixOS/nixpkgs/596611941a74be176b98aeba9328aa9d01b8b322' (2023-09-16)
  → 'github:NixOS/nixpkgs/dbe90e63a36762f1fbde546e26a84af774a32455' (2023-10-01)

- feat: remove armcord

- chore: remove custom xdg-open-with-portal

- feat: xdg enable open use portal

- feat: disable hyprland background

- chore: reorg substituters

- flake.lock: Update

Flake lock file updates:

• Updated input 'hyprland':
    'github:hyprwm/Hyprland/9ec656a37df103edc111e8e48cdfe89528dfe92e' (2023-10-01)
  → 'github:hyprwm/Hyprland/b784931e678f907b1f1e41d04485fefd8a1faaf8' (2023-10-02)
• Updated input 'hyprland/wlroots':
    'gitlab:wlroots/wlroots/c2aa7fd965cb7ee8bed24f4122b720aca8f0fc1e' (2023-09-28)
  → 'gitlab:wlroots/wlroots/5ef42e8e8adece098848fac53c721b6eb3818fc2' (2023-10-02)
• Updated input 'nixos-wsl':
    'github:nix-community/nixos-wsl/cadde47d123d1a534c272b04a7582f1d11474c48' (2023-09-30)
  → 'github:nix-community/nixos-wsl/337edef90c8abe35b42e95aecf510a063dad02dd' (2023-10-02)
• Updated input 'nixpkgs-wayland':
    'github:nix-community/nixpkgs-wayland/047ac635a222c9d6e38c61d10d3c5703954ad78c' (2023-10-01)
  → 'github:nix-community/nixpkgs-wayland/a734b5414e55cbe8a0ac1f4e79bb5c290d45f1d6' (2023-10-02)
• Updated input 'nixpkgs-wayland/nix-eval-jobs':
    'github:nix-community/nix-eval-jobs/39657d146828157ef51c4f2d8bebb96a77075fc6' (2023-09-21)
  → 'github:nix-community/nix-eval-jobs/82cede4edd01989095040b55d0212d61a65fc5fd' (2023-10-02)
• Updated input 'nixpkgs-wayland/nix-eval-jobs/flake-parts':
    'github:hercules-ci/flake-parts/7f53fdb7bdc5bb237da7fefef12d099e4fd611ca' (2023-09-01)
  → 'github:hercules-ci/flake-parts/21928e6758af0a258002647d14363d5ffc85545b' (2023-10-01)
• Updated input 'nixpkgs-wayland/nix-eval-jobs/nixpkgs':
    'github:NixOS/nixpkgs/ff7daa56614b083d3a87e2872917b676e9ba62a6' (2023-09-21)
  → 'github:NixOS/nixpkgs/fe0b3b663e98c85db7f08ab3a4ac318c523c0684' (2023-10-02)
• Updated input 'nixpkgs-wayland/nix-eval-jobs/treefmt-nix':
    'github:numtide/treefmt-nix/7a49c388d7a6b63bb551b1ddedfa4efab8f400d8' (2023-09-12)
  → 'github:numtide/treefmt-nix/720bd006d855b08e60664e4683ccddb7a9ff614a' (2023-09-27)
• Updated input 'nur':
    'github:nix-community/NUR/72619f85c0eeec8864f0c365932e39e8935a5b93' (2023-10-01)
  → 'github:nix-community/NUR/e91591b0854baca7bc1a90c6d74181dba079b174' (2023-10-02)
• Updated input 'rustup-overlay':
    'github:oxalica/rust-overlay/fc6fe50d9a4540a1111731baaa00f207301fdeb7' (2023-10-01)
  → 'github:oxalica/rust-overlay/1aaa2dc3e7367f2014f939c927e9e768a0cc2f08' (2023-10-02)

- feat: cachix the flake check

- chore(deps): bump actions/checkout from 3 to 4

Bumps [actions/checkout](https://github.com/actions/checkout) from 3 to 4.
- [Release notes](https://github.com/actions/checkout/releases)
- [Changelog](https://github.com/actions/checkout/blob/main/CHANGELOG.md)
- [Commits](https://github.com/actions/checkout/compare/v3...v4)

---
updated-dependencies:
- dependency-name: actions/checkout
  dependency-type: direct:production
  update-type: version-update:semver-major
...

Signed-off-by: dependabot[bot] <support@github.com>
- chore(deps): bump cachix/install-nix-action from 20 to 23

Bumps [cachix/install-nix-action](https://github.com/cachix/install-nix-action) from 20 to 23.
- [Release notes](https://github.com/cachix/install-nix-action/releases)
- [Commits](https://github.com/cachix/install-nix-action/compare/v20...v23)

---
updated-dependencies:
- dependency-name: cachix/install-nix-action
  dependency-type: direct:production
  update-type: version-update:semver-major
...

Signed-off-by: dependabot[bot] <support@github.com>
- Remove dead code

- flake.lock: Update

Flake lock file updates:

• Updated input 'home-manager':
    'github:nix-community/home-manager/ae896c810f501bf0c3a2fd7fc2de094dd0addf01' (2023-09-30)
  → 'github:nix-community/home-manager/6f9b5b83ad1f470b3d11b8a9fe1d5ef68c7d0e30' (2023-10-01)
• Updated input 'hyprland':
    'github:hyprwm/Hyprland/a2a29a60e5301df2cadf58c1bb18495d02710547' (2023-09-30)
  → 'github:hyprwm/Hyprland/9ec656a37df103edc111e8e48cdfe89528dfe92e' (2023-10-01)
• Updated input 'nixos-hardware':
    'github:nixos/nixos-hardware/adcfd6aa860d1d129055039696bc457af7d50d0e' (2023-09-28)
  → 'github:nixos/nixos-hardware/0ab3ee718e964fb42dc57ace6170f19cb0b66532' (2023-10-01)
• Updated input 'nixpkgs':
    'github:nixos/nixpkgs/8a86b98f0ba1c405358f1b71ff8b5e1d317f5db2' (2023-09-27)
  → 'github:nixos/nixpkgs/f5892ddac112a1e9b3612c39af1b72987ee5783a' (2023-09-29)
• Updated input 'nixpkgs-wayland':
    'github:nix-community/nixpkgs-wayland/bedaae13271fd5cfd861698e591d6af7104174e4' (2023-09-30)
  → 'github:nix-community/nixpkgs-wayland/047ac635a222c9d6e38c61d10d3c5703954ad78c' (2023-10-01)
• Updated input 'nixpkgs-wayland/lib-aggregate':
    'github:nix-community/lib-aggregate/cb8bfd550aaaf32a330c1c8870a3d9a5bfa00954' (2023-09-24)
  → 'github:nix-community/lib-aggregate/273cc814826475216b2a8aa008697b939e784514' (2023-10-01)
• Updated input 'nixpkgs-wayland/lib-aggregate/nixpkgs-lib':
    'github:nix-community/nixpkgs.lib/01fc4cd75e577ac00e7c50b7e5f16cd9b6d633e8' (2023-09-24)
  → 'github:nix-community/nixpkgs.lib/56992d3dfd3b8cee5c5b5674c1a477446839b6ad' (2023-10-01)
• Updated input 'nur':
    'github:nix-community/NUR/02ba0aeaddf56c02b8030f81d765e8de3d342f5b' (2023-09-30)
  → 'github:nix-community/NUR/72619f85c0eeec8864f0c365932e39e8935a5b93' (2023-10-01)
• Updated input 'rustup-overlay':
    'github:oxalica/rust-overlay/a4c3c904ab29e04a20d3a6da6626d66030385773' (2023-09-30)
  → 'github:oxalica/rust-overlay/fc6fe50d9a4540a1111731baaa00f207301fdeb7' (2023-10-01)

- feat: darwin disable automatic space switching

- feat: yabai 5.0.9 overlay until merged

- chore: remove redundant shebangs

- Remove dead code

- flake.lock: Update

Flake lock file updates:

• Updated input 'darwin':
    'github:lnl7/nix-darwin/e236a1e598a9a59265897948ac9874c364b9555f' (2023-09-26)
  → 'github:lnl7/nix-darwin/792c2e01347cb1b2e7ec84a1ef73453ca86537d8' (2023-09-30)
• Updated input 'home-manager':
    'github:nix-community/home-manager/4f02e35f9d150573e1a710afa338846c2f6d850c' (2023-09-29)
  → 'github:nix-community/home-manager/ae896c810f501bf0c3a2fd7fc2de094dd0addf01' (2023-09-30)
• Updated input 'hyprland':
    'github:hyprwm/Hyprland/86e8ed038f5b195cdf2548bc469f8f8bbc0caca8' (2023-09-30)
  → 'github:hyprwm/Hyprland/a2a29a60e5301df2cadf58c1bb18495d02710547' (2023-09-30)
• Updated input 'nixos-generators':
    'github:nix-community/nixos-generators/8ee78470029e641cddbd8721496da1316b47d3b4' (2023-09-04)
  → 'github:nix-community/nixos-generators/150f38bd1e09e20987feacb1b0d5991357532fb5' (2023-09-30)
• Updated input 'nixos-wsl':
    'github:nix-community/nixos-wsl/8735bdfa5fdfa6e90d944ff9f5f806668b53eacb' (2023-09-29)
  → 'github:nix-community/nixos-wsl/cadde47d123d1a534c272b04a7582f1d11474c48' (2023-09-30)
• Updated input 'nixpkgs-wayland':
    'github:nix-community/nixpkgs-wayland/627951bf2a490f7b5f31e98e2180e4b715968895' (2023-09-29)
  → 'github:nix-community/nixpkgs-wayland/bedaae13271fd5cfd861698e591d6af7104174e4' (2023-09-30)
• Updated input 'nur':
    'github:nix-community/NUR/b38a6a856e3c8258b6d776f63eb1041c314e96f6' (2023-09-30)
  → 'github:nix-community/NUR/02ba0aeaddf56c02b8030f81d765e8de3d342f5b' (2023-09-30)

- chore: use sri hash ranger overlay

- chore: update README

- Create cachix.yml
- flake.lock: Update

Flake lock file updates:

• Updated input 'home-manager':
    'github:nix-community/home-manager/0f4e5b4999fd6a42ece5da8a3a2439a50e48e486' (2023-09-26)
  → 'github:nix-community/home-manager/4f02e35f9d150573e1a710afa338846c2f6d850c' (2023-09-29)
• Updated input 'hyprland':
    'github:hyprwm/Hyprland/6d7dc70f663891ef39dcfb8ba8e5ff643b4d9ed8' (2023-09-27)
  → 'github:hyprwm/Hyprland/86e8ed038f5b195cdf2548bc469f8f8bbc0caca8' (2023-09-30)
• Updated input 'hyprland/wlroots':
    'gitlab:wlroots/wlroots/98a745d926d8048bc30aef11b421df207a01c279' (2023-09-21)
  → 'gitlab:wlroots/wlroots/c2aa7fd965cb7ee8bed24f4122b720aca8f0fc1e' (2023-09-28)
• Updated input 'nixos-wsl':
    'github:nix-community/nixos-wsl/e7d93d0f478b6fbb47c00d03449dc3d08b90abb7' (2023-09-12)
  → 'github:nix-community/nixos-wsl/8735bdfa5fdfa6e90d944ff9f5f806668b53eacb' (2023-09-29)
• Updated input 'nixos-wsl/flake-utils':
    'github:numtide/flake-utils/f9e7cf818399d17d347f847525c5a5a8032e4e44' (2023-08-23)
  → 'github:numtide/flake-utils/ff7b65b44d01cf9ba6a71320833626af21126384' (2023-09-12)
• Updated input 'nixpkgs':
    'github:nixos/nixpkgs/6500b4580c2a1f3d0f980d32d285739d8e156d92' (2023-09-25)
  → 'github:nixos/nixpkgs/8a86b98f0ba1c405358f1b71ff8b5e1d317f5db2' (2023-09-27)
• Updated input 'nixpkgs-wayland':
    'github:nix-community/nixpkgs-wayland/ed461a19c9d8cb149f9348d57c3506f2c6bc9324' (2023-09-28)
  → 'github:nix-community/nixpkgs-wayland/627951bf2a490f7b5f31e98e2180e4b715968895' (2023-09-29)
• Updated input 'nur':
    'github:nix-community/NUR/25f533015835c7d08883b7182fb20f60e717ad34' (2023-09-28)
  → 'github:nix-community/NUR/b38a6a856e3c8258b6d776f63eb1041c314e96f6' (2023-09-30)
• Updated input 'rustup-overlay':
    'github:oxalica/rust-overlay/9d8f850c3de67597c65271f3088aced0a671677f' (2023-09-28)
  → 'github:oxalica/rust-overlay/a4c3c904ab29e04a20d3a6da6626d66030385773' (2023-09-30)

- chore(deps): bump cachix/install-nix-action from 18 to 23

Bumps [cachix/install-nix-action](https://github.com/cachix/install-nix-action) from 18 to 23.
- [Release notes](https://github.com/cachix/install-nix-action/releases)
- [Commits](https://github.com/cachix/install-nix-action/compare/v18...v23)

---
updated-dependencies:
- dependency-name: cachix/install-nix-action
  dependency-type: direct:production
  update-type: version-update:semver-major
...

Signed-off-by: dependabot[bot] <support@github.com>
- chore(deps): bump actions/checkout from 2 to 4

Bumps [actions/checkout](https://github.com/actions/checkout) from 2 to 4.
- [Release notes](https://github.com/actions/checkout/releases)
- [Changelog](https://github.com/actions/checkout/blob/main/CHANGELOG.md)
- [Commits](https://github.com/actions/checkout/compare/v2...v4)

---
updated-dependencies:
- dependency-name: actions/checkout
  dependency-type: direct:production
  update-type: version-update:semver-major
...

Signed-off-by: dependabot[bot] <support@github.com>
- Create dependabot.yml
- Create settings.yml
- Update update-flakes.yml
- Create update-flakes.yml
- chore: cleanup

- refactor: remove simple package modules

- refactor: sort solution

- refactor: feature flags boot module

- refactor: break development into feature flags

- chore: cleanup

- chore: flake lock update

- refactor: clean up ssh config

- refactor: move where wakatime secret is enabled

- chore: lint fix

- chore: remove global python

- chore: standardize  python versions

- feat: sketchybar spaces activate animation

- refactor: clean up yabai config

- refactor: darwin development dependencies

- feat: readd astronvim v4 config

- chore: set recommended tmux escape-time

- feat: wsl smarter

- Revert "feat: use astronvim v4 config"

This reverts commit 746c3753d5f7080a03d9cbfad750c7a0994fa753.

- feat: use astronvim v4 config

- refactor: give bees less again

- feat: wsl add wsl-open

- feat: wsl add wslutilities and wslview override

- chore: lint fix

- Update README.md
- feat: hardware add nvidia programs

- chore: bump dooit overlay until new nixos-unstable

- refactor: replace hyprland overlay with direct pkg references

- refactor: refine getExe and use getExe'

- chore: cleanup snowfall inputs

- chore: remove duplicate home-manager imports

- feat: initial wsl setup (#5)


- chore: group attributes

- chore: remove unused bindings

- chore: linting cleanup

- wip home sops

- chore: remove unused types

- chore: remove unused attributes

- chore: remove unused agenix

- chore: cleanup overlays

- chore: remove unused packages

- feat: dooit 2.0.0 overlay

- chore: remove snowfallorg flake fork

- chore: cleanup with inputs;

- chore: remove unused inputs

- feat: hypr_socket_watch systemd service

- feat: hyprland socket watch wallpaper changer

- feat: hyprland reenable GDK_BACKEND=wayland

- refactor: move import_env to packages

- refactor: hyprpaper dynamic config

- refactor: move hyprpaper to separate module

- refactor: waybar persistent-workspaces rename

- refactor: waybar add idle_inhibitor to secondary monitor

- feat: more sops configuration

- refactor: move btrfs into new module

- chore: replace exa with eza

- refactor: tweak waybar format-icons

- feat: initial sops addition

- refactor: hide vscode/argv.json behind keyring enable

- chore: remove unneeded sketchybar overlay

- refactor: nixpkgs-wayland specific packages instead of overlay

- refactor: nixpkgs-wayland overlay replace manual waybar overlay

- refactor: waybar tweak urgent css

- refactor: convert hyprland workspaces to nix expression

- feat: readd scroll events waybar

- feat: waybar add empty and visible styling

- chore: update waybar overlay

- refactor: replace lib.getExe with inherit

- refactor: replace with lib with inherit

- chore: minor cleanup of boot

- chore: sketchybar version overlay until nixpkgs updated

- refactor: greetd -> regreet

- chore: waybar hyprland new config style

- feat: development add cpplint

- chore: cleanup flake.nix

- feat: nixos security add seahorse

- remove upstreamed overlay fix

- chore: update waybar overlay and flake lock

- darwin networking dns

- remove duplicate home-manager imports

- astronvim fix treesitter compile issue

- home folder cleanup

- swaylock debug level to troubleshoot

- swayidle debug level to troubleshoot

- flake darwin fix

- linting cleanup CORE

- xdg add associations too

- minor spicetify cleanup

- waybar fix xdg-open not found

- rename neovim to astronvim

- ranger overlay updated to latest commit

- remove unused sketchybar version overlay

- hyprland environment import safeguards

- add barrier kvm

- zen kernel for now since main is fubar

- hardware cleanup

- linting fixes

- waybar remove tooltip on wlogout

- revert nixpkgs update

- sketchybar overlay until nixpkgs update

- darwin zsh login shell

- git prune on fetch

- sketchybar config embedded manually for now

- getExe more configs

- darwin desktop configs use getexe

- kitty default again (wezterm crashes on display unplug)

- waybar overlay until new release

- ranger attempt jsonc preview support

- ranger edit jsonc support

- fastfetch jsonc config nix expression

- wezterm default hyprland

- add wezterm

- tmux colors fix

- waybar switch back to wlr/workspaces

- waybar overlay for hyprland urgent support until upstreamed

- waybar tweak urgent css

- create debug option for waybar

- btrfs-assistant add

- add protonup-qt

- waybar remove hyprland overlay and update config

- misc cleanup

- add yubikey to workstation

- darwin build fix

- sf-mono use source as input

- firefox embed config

- rofi embed config

- hyprland embed config

- embed ranger config

- embed qt theming

- alacritty home-manager config

- wlogout embed layout

- kitty home-manager config

- remove .functions

- zsh plugins

- bash home-manager config

- embed swaync dotfiles

- nixos remove neofetch

- helix cleanup

- minor fastfetch cleanup

- btop to home-manager config

- zsh to home-manager config

- fish to home-manager config

- fastfetch to home-manager config

- snowfall lib switch to dev

- ranger fork support tmux image preview

- cleanup neovim config

- khanelimac nixcfg alias

- micro home-manager consolidation

- topgrade home-manager consolidation

- tmux updates

- default editor options

- hyprland hyprpaper nix file

- darwin sketchybar aliases

- tmux home-manager consolidation

- lazygit home-manager consolidation

- nixos remove bundled op-ssh-sign

- git use home-manager options

- deadnix fixes

- direnv home-manager consolidation

- sort systems

- sort devshell.toml

- sort flake inputs

- nixos remove icehouse

- nixos cleanup discord config

- remove cowsay packages and overlays

- cleanup home-manager fish config

- remove .aliases file

- openssl alias specify bin

- nixos cava alias

- bat moved to home-manager

- lsd moved to home-manager

- refine aliases

- darwin shell fixes

- nixos add github desktop

- shell refactoring

- nixos networking nameservers

- remove lazygit overlay

- khanelinix disable common-gpu-nvidia-disable so gpu passthru works with nixos-hardware update

- flake lock update and disable broken packages

- nixos add snapper

- nixos add btrfs storage options

- consolidate git

- wip home-manager refactor

- home-manager git config support darwin and linux

- darwin conflict fix

- looking-glass update

- misc dev tweaks

- lazygit overlay until nixpkgs updated

- darwin add shell configs

- darwin use nix tmux config

- khanelimac archetypes

- darwin add tmux custom config

- darwin add archetypes and suite updates

- misc cleanup

- move agenix to shared module (still doesn't work with config)

- change nixos direnv to use nixos module

- consolidate common

- consolidate networking

- khanelimac specific tweaks

- darwin move homebrew to tools

- consolidate fonts

- darwin add sketchybar-app-font

- remove nur finally

- more refactoring

- cleanup formatting

- nixos add to social suite

- [wip] refactoring

- flake update and misc fixes/changes

- darwin hide mas apps behind flag

- darwin dev update (wip)

- cleanup

- darwin migrate sfmono to cask

- darwin consolidate homebrew config

- darwin homebrew tweaks

- migrate sddm-catppuccin to catppuccin-sddm-corners (will replace with nixpkgs)

- minor cleanup on display-managers sddm still not working for me

- nixos add element-desktop

- migrate wttrbar from custom package to nixpkg

- misc cleanup

- darwin yabai rule for element

- darwin disable home-manager until fixed and add element

- update workflows

- nixpkgs-lint solution

- nixpkgs-fmt solution

- switch to nixpkgs-fmt

- hyprland updates

- darwin system defaults added

- misc tweaks and fixes

- darwin add packages

- darwin migrate sketchybar to nix-darwin

- home-manager ncmpcpp use same directory as mpd explicitly

- hyprland use home-manager mpd-mpris

- hyprland use home-manager gnome-keyring daemon

- hyprland use blueman home-manager service

- nixpkgs development reqs

- hyprland tweaks

- nixos fix hyprland windowrule for spotify and add mpdevil

- nixos add mpris functionality waybar and mpd setup

- nixos migrate waybar to home-manager

- nixos fix hyprland rofi

- darwin migrate yabai to nix-darwin

- darwin migrate skhd to nix-darwin

- migrate swaylock to home-manager

- remove nixos swayidle just use home-manager

- nixos fix wallpaper change temporary hack

- nixos modularize hyprland config

- nixos convert hyprland to home-manager

- darwin remove brew suite

- darwin organize brews casks and taps

- darwin organize masApps

- minor cleanup

- nixos plymouth fix

- darwin organize better

- darwin migrate gui apps to homebrew module

- spotify cleanup

- minor hyprland and home-manager scaffold / test

- use mdns instead of ip

- update thunderbird a little and add vlc

- add darwin to check

- deadnix cleanup

- rename darwin hostname

- darwin add stuff from brewfile as a module for now

- enable colord for printing

- flake lock update

- hyprland remove unused script call

- bluetooth and power fix

- blacklist module throwing errors

- remove qmk from dev

- misc fixes

- waybar overlay for unreleased hyprland fix

- khanelinix enable sysrq

- darwin update common

- darwin add gimp

- nixos swaync icon update

- nixos waybar icon update

- shared blender config

- darwin fix username

- nixos enable blender again

- darwin remove iterm2

- darwin 1password

- darwin home app linker

- add darwin firefox (wip)

- shared nix config module

- add zathura

- xdg mimeapps config

- helix initial config

- spicetify extensions and apps

- cleanup

- add spicetify

- darwin tweaks

- initial darwin setup

- initial snowfallorg home-manager setup

- move nixos into separate modules

- use breeze dark icons

- deadnix and statix fixes

- hyprland config tweak

- unpin linux kernel

- firefox updates

- try and fix printing

- screenlayout disable resetting secondary monitor

- cleanup gtk, qt, and hyprland configs a bit

- gdm instead of regreet again

- update hyprland polish file to use config values

- flake lock update - temp pin kernel crash on 6.4

- hyprland add gsettings schemas to regular terminal

- Update README.md
- some lint fixes

- gate flake check behind branch condition

- add lint workflow

- remove unused secrets file

- alejandra reformat

- deadnix fix

- alejandra format

- statix fix

- flake lock update

- add nixos packages to common

- refine xdg-desktop-portal implementation

- gamemode tweak

- flake lock update

- add gamemode

- add mangohud

- update firefox addon

- flake lock update and gtk breaking change fix

- flake lock update

- massive refactor

- flake lock update

- wlroots suite

- catppuccin regreet, modularize display-managers, some cleanup and reorg

- ranger plugins fix

- ranger dependencies

- flake lock update

- khanelinix remove nix controlled openrgb config

- samba update for khanelinix

- flake lock update

- add emulationstation

- thunderbird updates

- add emulators

- include discord in startup apps

- flake lock update

- remove waybar overlay with 0.9.18 in nixpkgs

- add glxinfo

- remove unused cava overlay

- attempt to fix peek.nvim (still errors but new errors)

- flake lock update

- add group notifications back to waybar 0.9.18

- add hydra-check

- Create README.md
- flake lock update

- add ssh public keys and aliases

- move sddm-catppuccin to its own nix flake

- change login shell to zsh

- use waybar again after new release with fixes

- flake lock update

- eww tweaks

- add betterdiscord theme

- hyprland add secondary monitor workaround

- add spotify

- initial eww bar config attempt

- environment variable updates

- flake lock update

- update khanelinix hardware

- update hyprland environment variables

- update firefox config

- tmux update

- flake update and remove things breaking build

- workflow add

- flake lock update

- initial commit


### New

- flake.nix: add git-cliff hook

- packages/git-cliff: add git-cliff package for hook

- flake.nix: add pre-commit-hooks

- zellij: add shell tab to layout

mimic my normal tmux layout

- music: add musikube and pulsemixer

- zellij: add custom layout

- nix/system: add logrotate

- nix/system: add oomd

- system/time: add ntp

- khanelinix: add realtime

- nixos/system: add realtime module

- user.extraGroups: add extra groups

- khanelinix: add networking address

Apparently configured in wrong system...

- khanelilab: fix networking address

- shell/c: fix darwin

- shell/dotnet: fix darwin

- gamemode: fix hyprland commands

For real this time....

- hyprland: add resize binds

- gamemode: fix hyprland commands

- khanelinix: add tpm

- nix/hardware: add tpm module

- swaync: fixes

- hyprland: fix variable name

- swaync: fix

- fonts: add some more fonts

- obs: add extra plugins

- swaync: fix screenshot utility

- hyprland: fix hl alias

- yazi: add unique type icons

- yazi: add icons

- neovim/treesitter: add kdl grammar

- waybar: additional modules

- .gitignore: add flake

- nix: add channel links

- lib: add booltToNum

- services/power: add power-profiles-daemon

- darwin: fixes

- polkit: add logging

- boot: add silentBoot config

- nix: add extra substituters

- nvidia: add extra configuration

- tmux: add fzf

- waybar: add cava module

- hyprland: fix slurp shortcuts

- bluetooth: add experimental features

- hyprland: fix yazi launch bind

- neovim: add quickfix navigation keybind

- neovim/catppuccin: fix changed setting names

- nixvim: fix deprecations

- shells/default: add nix-inspect

- yazi: add miller previewer

- yazi: add glow previewer

- yazi: add dmg opener

- yazi: fix openers

- neovim/neotest: add junit_jar

- neovim/conform: add sqlfluff

- neovim/conform: add shfmt

- neovim/conform: add xmlformat

- waybar: add wezterm window-rewrite

- yazi: add archive opener

- qt: fix style name

- codeium: add plugin settings

- treesitter: add vimdoc back

- darwin: add bashdb

- treesitter: add markdown_inline

- noice: add nvim-notify

- efm: add linters

- gitsigns: add git blame

- telescope: add git stash keymap

- development: add postman

- telescope: fix conflicting key map

- hyprlock: fix images.shadow_passes

- git: add blame.ignoreRevsFile

- git: add GITHUB_TOKEN secret

- theme: add catppuccin.nix

- cmp: add priorities

- rustaceanvim: add excludeDirs (doesnt seem to work)

- conform: add codespell formatter

- neotest: add summary keymap

- conform: add formatter commands

- yabai: add teams work rule

- sketchybar: add window rewrite front app

- dap: fix darwin build

- neotest: add adapters

- lualine: fix dap-ui

- games: add minecraft and prismlauncher

- gitsigns: add line blame

- lazygit: add overrideGpg

- conform: add async formatting

- telescope: add autocommands search

- lualine: add winbar

- lualine: add tabs to tabline

- lualine: add aerial

- nixvim: add refactoring-nvim

- nixvim: add webapi-vim for rustplay

- git: fix darwin git credential helper

- git: add core azure host credential provider

- git: add dib azure host credential provider

- hypr-socket-watch: add new rust flake

- devshell: add thaw

This reverts commit 05a880d54c37997b325964d2a9b5e36d1f8668bd.

- flake.nix: add snowfallorg.thaw

- sway: add swaylock

- conform: fix format toggle

- khanelinix: add dib signing

- sketchybar: add default space icon

- labeler.yml: fix
- deadnix: fix commit message

- sketchybar: add copy labels wifi module

- jankyborders: add bordersrc for default behavior

- skhd: fix yabai and skhd restart mappings

- lib: add capitalize function

- hyprland: fix screen sharing

- firefox: fix intl.accept_languages

- khanelimac: add music suite

- git: add safe directories

- security: add sudo-rs

- nixvim: add aerial

- nixvim: add nix-develop

- yazi: fix conflicting keybinding

- yazi: add hostname to header

- yazi: add dragon keymap

- yazi: add extra status information

- yazi: add full border

- nixvim: add mini.map

- nixvim: add mini.basics and mini.bracketed

- nixvim: add mini.indentscope

- nixvim: add mini.surround

- flake.nix: fix rust-overlay name

- firefox: add react dev tools

- sketchybar: add lua shebang on all

- sketchybar: add yabai item

- hyprland: add teams windowrule

- waybar: add teams window rewrite

- business: add teams

- sketchybar: fix github

- sketchybar: add print_table

- sketchybar: add spaces with windowrules

- sketchybar: add skhd

- homebrew: add cask back

- khanelinix: fix swayoutput

- waybar: fix tray slider

- hyprlock: add grace on lock

- firefox: add floorp package without customization, for now

- khanelinix: add hyprlandOutput

- khanelinix: add kernel specializations

- nixvim: add yanky

- nixvim: fix todo and fix highlights

- sketchybar: add logFile output

- nixvim: add fix highlights

- nixvim: fix autoformat keymap

- nixvim: fix spellang

- nixvim: add toggle fold column

- nixvim: add toggle spell and wrap

- nixvim: add diffview

- nixvim: add indent-blankline

- feat: add ripgrep darwin

- feat: add floorp

- fix: dib core remapping

- fix: wttrbar config location

- fix: non aarch-64 builds

- feat: add zoxide to yazi

- chore: add dynamic-island-sketchybar logging output

- fix: sketchybar helper.sh make without cd

- fix: sketchybar remove compiled helpers

- fix: sketchybar island notification init

- fix: sketchybar toggle fixes

- fix: sketchybar bluetooth fix indexing

- fix: sketchybar  weather gracefully handle failed api calls

- fix: deno darwin overlay fix

- feat: add neovim nightly overlay again

- fix: steam menu focus

- chore: add spotify free rules and window rewrite

- fix: qt theme fix

- fix: hacks and workarounds for k3b

- feat: add git-credential-oauth

- feat: add video programs

- feat: add cloudflared

- feat: add khanelilab cloudflared secret

- chore: add supported secrets directories

- feat: add more to devshell

- chore: add meta.platforms to packages

- fix: cava for darwin

- feat: add hyprland crash report aliases

- fix: fix hyprland log aliases

- fix: sketchybar icons

- fix: record_screen

- fix: hyprland screenshot binds

- feat: add logging hyprland (breaking change randomly)

- fix: firefox search force

- fix: firefox cfg.userchrome used appended after /chrome/userchrome.css

- feat: add firefox search defaults

- fix: firefox needing to be beta for now for profile to work

- fix: proper darwin firefox config location

- fix: firefox not supported darwin

- fix: neovim onChange temporarily disabled

- fix: neovim onchange events

- feat: add weather_config to secrets

- feat: add chromium while troubleshooting firefox crashes

- fix: scream service property

- fix: hl commands breaking due to aliases

- fix: vulkan-utility-libraries revert

- fix: yabai bar height

- fix: zsh sketchybar aliases

- fix: music playing artwork sketchybar

- fix: caprine hide messenger ad

- fix: caprine macos config

- fix: caprine style fix

- fix: cleanup fonts

- fix: firefox theme

- feat: add c devshell

- fix: wlroots readd clipboard

- fix: hyprland pkg exe references

- fix: spicetify catppuccin theme

- feat: add disko khanelinix

- feat: fix_git pkg (wip)

- fix: tmux ranger img previews

- feat: add hyprland catppuccin.conf

- fix: discord master overlay until released unstable

- feat: add nix-update

- fix: readd waybar persistent workspaces to config

This reverts commit aa86bb51e6169da2f9b485aa8f72511fd08bdeab.

- fix: lint fixes

- feat: add theme module

- fix: k9s theme path

- feat: add flake-checker to check.yml

- feat: add jqp dev packages

- fix: hypraper restart always

- fix: kitty scratchpad launch

- fix: khanelinix static ip match router config

- fix: ssh port expression only nixos configurations

- feat: add yazi goto keymap

- feat: add gsed alias darwin

- feat: add yazi (wip config)

- feat: add tree-sitter to allow building from grammar

- fix: tmux truecolor

- feat: add k9s

- feat: add bottom

- fix: udiskie breaks darwin

- fix: nixos networking mdns

- fix: remove custom dib signing key

- fix: revert waybar workspaces setup for now

- fix: reenable wslagentbridge and remove ssh auth override

- feat: add prefetch-sri

- feat: add tearing to games

- feat: add hyprland tearing

- feat: add udiskie

- feat: add tree

- fix: revert xdgOpenUsePortal until i can figure out portal application associations

- feat: add element windowrule

- fix: sddm module fix

- fix: broken / disabled packages

- fix: trace-which encapsulate dependency properly

- fix: hyprland removed decoration setting

- fix: sops configuration

- feat: add khanelinix cachix

- feat: add git fix

- feat: add efi tools

- feat: add lanzaboote secure boot

- feat: add dib kubeconfig core laptop

- feat: add azure tools

- feat: add gtk and qt theme core laptop

- fix: add qt6 kvantum

- feat: add k9s to k8s

- fix: credentials usehttppath

- feat: add nix secret

- fix: lint fixes

- fix: sopsdiffer attribute

- feat: add wakatime secret for khanelimac khaneliman

- feat: add wakatime secret for core nixos

- feat: add wakatime secret and user ssh

- fix: marksman dependencies

- fix: add python3 pip dependency

- fix: jdtls fix dependency

- fix: csharp-ls neovim

- fix: neovim lazy lock

- fix: remove conflicting dotnet-sdk version

- feat: add godot engine

- fix: wgetrc missing error

- fix: git includes option default

- feat: add wakatime secret (wip implementation)

- fix: sops fixes

- fix: CORE nixcfg alias

- fix: git wsl not enabled

- fix: wsl git credentials

- fix: wsl git signing

- fix: remove doas from common to fix wsl

- feat: add snowfall-frost

- fix: tune bees more

- fix: spice service wantedby

- fix: limit bees a different way

- feat: add unityhub

- refactor: fix lint warning waybar

- fix: stupid darwin sandbox workaround

- fix: hypr_socket_watch encapsulate dependency

- fix: remove broken darwin package

- fix: hyprland remove ws explicit bind conflicts

- fix: devshell

- chore: add meta.mainProgram to local packages

- fix: hyprland prevent stupid cursor relocation default change

- fix: limit beesd threads to prevent performance issues

- fix: replace types.string with types.str

- fix: btrfs dedupe

- feat: add btrfs auto scrub

- fix: dumb waybar on-click workaround on hyprland

- feat: add some disk space analysers

- fix: darwin missing inherits

- fix: disable mangohud for now (broke steam)

- fix: primary.sh xrandr command

- fix: regreet use sway and support monitor definitions

- fix: regreet work with vulkan

- feat: add tuigreet (unthemed)

- feat: add lightdm

- feat: add vscode/argv.json to fix keychain issue

- fix: nixos-revision correct url and jq parameter

- feat: add nix trace helper programs

- fix: flake switch on darwin

- fix: astronvim gnumake dependency

- fix neovim plugins not being able to update

- nixos-wsl: add CORE-PW00LM92 init

- record:screen: fix darwin build

- testing kernel because of amdgpu issues in current

- fix hyprland log aliases

- fix fastfetch config

- fix bat theme name

- fix home-manager config for khanelimac

- fixes and cleanup

- test out armcord as a discord client

- fix nixos config

- fix gdm user icon script

- fix mdns

- fix cursor-size gtk

- fix gtk theme name

- fix cachix

- fix check action

- fix waybar bug and use gdm for nixos since sddm is outdated

- fix discord theme error



This changelog has been generated automatically using the custom git-cliff hook for
[git-hooks.nix](https://github.com/cachix/git-hooks.nix)

