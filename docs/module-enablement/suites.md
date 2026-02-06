# Suites

Suites bundle related modules by platform and purpose.

## Shared Suites (Cross-Platform)

<details>
<summary><strong>Common Suite</strong> (<code>modules/common/suites/common/</code>)</summary>

| Category           | Items                                       |
| ------------------ | ------------------------------------------- |
| **Core Utilities** | `coreutils`, `findutils`, `killall`, `lsof` |
| **Network Tools**  | `curl`, `wget`                              |
| **File Utilities** | `fd`, `file`, `unzip`                       |
| **System Info**    | `pciutils`, `tldr`                          |
| **Other**          | `xclip` (clipboard)                         |

**Additional Shared Modules:**

| Module          | Purpose            | Key Features                                              |
| --------------- | ------------------ | --------------------------------------------------------- |
| **Nix Config**  | Advanced Nix setup | Flakes, distributed builds, binary caches, optimization   |
| **Font System** | Font management    | Desktop, emoji, developer fonts; MonaspaceNeon NF default |
| **SSH Config**  | SSH automation     | Known hosts, GPG forwarding, auto-generated aliases       |

</details>

## NixOS Suites

<details>
<summary><strong>Common Suite</strong> (<code>modules/nixos/suites/common/</code>)</summary>

| Category              | Modules                                                                        | Default |
| --------------------- | ------------------------------------------------------------------------------ | ------- |
| **Hardware & System** | `power`, `nix`, `fonts`, `locale`, `time`                                      | ✅      |
| **Programs**          | `bandwhich`, `nix-ld`, `ssh`                                                   | ✅      |
| **Security**          | `clamav`, `gpg`, `pam`, `usbguard`                                             | ✅      |
| **Services**          | `ddccontrol`, `earlyoom`, `logind`, `logrotate`, `oomd`, `openssh`, `printing` | ✅      |

**System Packages:**

- **Network:** `curl`, `dnsutils`, `rsync`, `wget`
- **System Info:** `fortune`, `lolcat`, `lshw`, `pciutils`, `util-linux`
- **Custom Tools:** `isd`, `lazyjournal`, `usbimager`, `trace-symlink`,
  `trace-which`

**Configuration:**

- Clears default packages
- Enables Zsh with autosuggestions
- Enables Zram swap

</details>

<details>
<summary><strong>Desktop Suite</strong> (<code>modules/nixos/suites/desktop/</code>)</summary>

| Category     | Item         | Purpose                   |
| ------------ | ------------ | ------------------------- |
| **Addons**   | `keyring`    | GNOME Keyring integration |
| **Apps**     | `_1password` | Password manager          |
| **Services** | `flatpak`    | Application sandboxing    |

</details>

<details>
<summary><strong>Development Suite</strong> (<code>modules/nixos/suites/development/</code>)</summary>

| Option         | Default | Purpose              |
| -------------- | ------- | -------------------- |
| `aiEnable`     | `false` | AI development tools |
| `dockerEnable` | `false` | Docker development   |
| `sqlEnable`    | `false` | SQL development      |

**Network:** Opens ports `12345`, `3000`, `3001`, `8080`, `8081`

**User Groups:** `git` (always), `mysql` (if sqlEnable)

**Conditional Services:**

| When Enabled   | Service               | Purpose             |
| -------------- | --------------------- | ------------------- |
| `aiEnable`     | `ollama`, `ollama-ui` | Local LLM inference |
| `dockerEnable` | `podman`              | Container runtime   |

</details>

<details>
<summary><strong>Games Suite</strong> (<code>modules/nixos/suites/games/</code>)</summary>

| Category        | Item                    | Purpose                            |
| --------------- | ----------------------- | ---------------------------------- |
| **Performance** | `gamemode`, `gamescope` | CPU optimization, micro-compositor |
| **Launchers**   | `steam`                 | Gaming platform                    |
| **Flatpak**     | `org.vinegarhq.Sober`   | Roblox launcher                    |

</details>

<details>
<summary><strong>VM Suite</strong> (<code>modules/nixos/suites/vm/</code>)</summary>

| Service          | Purpose                                  |
| ---------------- | ---------------------------------------- |
| `spice-vdagentd` | Clipboard sharing, resolution adjustment |
| `spice-webdav`   | Folder sharing between host/guest        |

</details>

<details>
<summary><strong>Wlroots Suite</strong> (<code>modules/nixos/suites/wlroots/</code>)</summary>

| Type         | Item        | Purpose                       |
| ------------ | ----------- | ----------------------------- |
| **Programs** | `xwayland`  | X11 compatibility for Wayland |
| **Programs** | `wshowkeys` | Display pressed keys          |
| **Services** | `seatd`     | Seat management daemon        |

**Target:** Sway, Hyprland, other wlroots compositors

</details>

## Darwin Suites

<details>
<summary><strong>Art Suite</strong></summary>

| Category            | Items                                      |
| ------------------- | ------------------------------------------ |
| **System Packages** | `imagemagick`, `pngcheck`                  |
| **Homebrew Casks**  | `blender`, `gimp`, `inkscape`, `mediainfo` |
| **Mac App Store**   | Pixelmator                                 |

</details>

<details>
<summary><strong>Business Suite</strong></summary>

| Category           | Items                                                                                             |
| ------------------ | ------------------------------------------------------------------------------------------------- |
| **Homebrew Casks** | `bitwarden`, `calibre`, `fantastical`, `libreoffice`, `meetingbar`, `microsoft-teams`, `obsidian` |
| **Mac App Store**  | Brother iPrint&Scan, Keynote, Microsoft OneNote, Notability, Numbers, Pages                       |
| **Khanelinix**     | `_1password`                                                                                      |

</details>

<details>
<summary><strong>Common Suite</strong></summary>

| Category               | Items                                                                                                      |
| ---------------------- | ---------------------------------------------------------------------------------------------------------- |
| **System Packages**    | `duti`, `gawk`, `gnugrep`, `gnupg`, `gnused`, `gnutls`, `terminal-notifier`, `trash-cli`, `wtfutil`, `mas` |
| **Homebrew Brews**     | `bashdb`                                                                                                   |
| **Khanelinix Modules** | `nix`, `ssh`, `homebrew`, `openssh`, `fonts`, `input`, `interface`, `networking`                           |
| **Custom Tools**       | `trace-symlink`, `trace-which`                                                                             |

</details>

<details>
<summary><strong>Desktop Suite</strong></summary>

| Category            | Items                                                                                                                                                |
| ------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| **System Packages** | `alt-tab-macos`, `appcleaner`, `bartender`, `blueutil`, `monitorcontrol`, `raycast`, `switchaudio-osx`, `stats`                                      |
| **Desktop WM**      | `yabai`                                                                                                                                              |
| **Homebrew Brews**  | `ical-buddy`                                                                                                                                         |
| **Homebrew Casks**  | `bitwarden`, `ghostty`, `gpg-suite`, `hammerspoon`, `launchcontrol`, `sf-symbols`, `xquartz`                                                         |
| **Mac App Store**   | AmorphousMemoryMark, Amphetamine, AutoMounter, Dark Reader for Safari, Disk Speed Test, Microsoft Remote Desktop, PopClip, TestFlight, WiFi Explorer |

</details>

<details>
<summary><strong>Development Suite</strong></summary>

| Category           | Items           | Condition      |
| ------------------ | --------------- | -------------- |
| **Homebrew Casks** | `cutter`        | Always         |
| **Homebrew Casks** | `docker`        | `dockerEnable` |
| **Homebrew Casks** | `ollamac`       | `aiEnable`     |
| **Mac App Store**  | Patterns, Xcode | Always         |

</details>

<details>
<summary><strong>Other Darwin Suites</strong></summary>

| Suite          | Key Items                                                           |
| -------------- | ------------------------------------------------------------------- |
| **Games**      | `moonlight`, `steam` (Homebrew)                                     |
| **Music**      | GarageBand (Mac App Store)                                          |
| **Networking** | `tailscale` service                                                 |
| **Social**     | `slack@beta` (Homebrew)                                             |
| **Video**      | `ffmpeg` (system), `plex` (Homebrew), Infuse/iMovie (Mac App Store) |
| **VM**         | `vte` (system), `utm` (Homebrew)                                    |

</details>

## Home Manager Suites

<details>
<summary><strong>Common Suite</strong></summary>

| Category              | Items                                                                                    |
| --------------------- | ---------------------------------------------------------------------------------------- |
| **Terminal Emulator** | `kitty`                                                                                  |
| **Shells**            | `bash`, `zsh`                                                                            |
| **Essential Tools**   | `atuin`, `bat`, `btop`, `direnv`, `eza`, `fzf`, `git`, `jq`, `ripgrep`, `yazi`, `zoxide` |
| **System Packages**   | `ncdu`, `tree`, `wikiman`, `nix-du`, `graphviz`                                          |
| **Platform-Specific** | `pngpaste` (Darwin), `glxinfo` (Linux)                                                   |
| **Services**          | `udiskie`+`tray` (Linux), `input` system (Darwin)                                        |

**Configuration:** Creates `.hushlogin`, sets session variables, includes shell
aliases

</details>

<details>
<summary><strong>Development Suite</strong></summary>

| Category            | Items                                                           | Condition                          |
| ------------------- | --------------------------------------------------------------- | ---------------------------------- |
| **Core Tools**      | `jqp`, `neovide`, `onefetch`, `postman`, `tree-sitter`          | Always                             |
| **Editors**         | `vscode`, `neovim`                                              | Always                             |
| **Version Control** | `act`, `git-crypt`, `gh`, `jujutsu`, `lazygit`                  | Always                             |
| **Nix Tools**       | `hydra-check`, `nix-diff`, `nix-update`, `nixpkgs-review`, etc. | `nixEnable`                        |
| **Game Dev**        | `gdevelop`, `godot`                                             | `gameEnable`                       |
| **SQL Tools**       | `dbeaver-bin`, `mysql-workbench`                                | `sqlEnable`                        |
| **AI Tools**        | `claude-code`                                                   | `aiEnable`                         |
| **Container Tools** | `k9s`, `lazydocker`                                             | `kubernetesEnable`, `dockerEnable` |

**Secrets:** API keys for ANTHROPIC, AZURE_OPENAI, OPENAI, TAVILY **Aliases:**
Extensive nixpkgs and home-manager development shortcuts

</details>

<details>
<summary><strong>Specialized Suites</strong></summary>

| Suite          | Focus             | Key Tools                                                  |
| -------------- | ----------------- | ---------------------------------------------------------- |
| **Art**        | Creative software | `blender`, `gimp`, `inkscape-with-extensions`              |
| **Business**   | Productivity      | `thunderbird`, `_1password-cli`, `syncthing`, office tools |
| **Desktop**    | GUI applications  | `firefox`, theme systems, file managers                    |
| **Emulation**  | Game emulation    | `mame`, `mednafen`, `retroarch`, console emulators         |
| **Games**      | Gaming tools      | `bottles`, `heroic`, `lutris`, `steam` tools               |
| **Music**      | Audio production  | `ncmpcpp`, `cava`, `mpd` (Linux), audio editors            |
| **Networking** | Network tools     | `nmap`, `openssh`, `speedtest-cli`                         |
| **Photo**      | Image editing     | `darktable`, `digikam`, `exiftool` (Linux)                 |
| **Social**     | Communication     | `caprine`, `vesktop`, `slack-term`, `twitch-tui`           |
| **Video**      | Video editing     | `obs`, `mpv`, `vlc`, `handbrake` (Linux)                   |
| **Wlroots**    | Wayland tools     | `waybar`, `swaync`, clipboard/screen tools                 |

</details>
