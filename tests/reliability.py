"""Serialized evaluation matrix. Logs are evidence, not build or runtime proof."""

import argparse
import json
import pathlib
import subprocess
import time

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument(
    "snapshot", help="immutable flake store path from nix flake archive --json"
)
parser.add_argument("evidence", type=pathlib.Path)
parser.add_argument("--only", nargs="*", default=[])
parser.add_argument(
    "--builders", help="explicit evaluator builders; does not change host policy"
)
parser.add_argument("--timeout", type=int, default=300)
args = parser.parse_args()
args.evidence.mkdir(parents=True, exist_ok=True)
records = []


def evaluate(
    label, expression, expected_failure=False, validate=None, error_message=None
):
    if args.only and not any(label.startswith(prefix) for prefix in args.only):
        return None
    command = [
        "nix",
        "eval",
        "--json",
        "--impure",
        "--option",
        "eval-cache",
        "false",
        "--option",
        "substituters",
        "https://cache.nixos.org/",
        *(["--option", "builders", args.builders] if args.builders is not None else []),
        "--expr",
        "let f = builtins.getFlake "
        + json.dumps(args.snapshot)
        + "; lib = f.inputs.nixpkgs.lib; in "
        + expression,
    ]
    start = time.monotonic()
    try:
        result = subprocess.run(
            command, capture_output=True, text=True, check=False, timeout=args.timeout
        )
    except subprocess.TimeoutExpired as error:
        result = subprocess.CompletedProcess(
            command,
            124,
            (error.stdout or b"").decode(),
            (error.stderr or b"").decode() + "\nEvaluation timed out.\n",
        )
    (args.evidence / (label + ".stdout")).write_text(result.stdout)
    (args.evidence / (label + ".stderr")).write_text(result.stderr)
    value = json.loads(result.stdout) if result.returncode == 0 else None
    passed = (result.returncode != 0) if expected_failure else (result.returncode == 0)
    if passed and expected_failure and error_message:
        passed = error_message in result.stderr
    if passed and not expected_failure and validate:
        passed = validate(value)
    records.append(
        {
            "label": label,
            "passed": passed,
            "expectedFailure": expected_failure,
            "seconds": round(time.monotonic() - start, 2),
            "command": command,
            "value": value,
        }
    )
    (args.evidence / "results.json").write_text(json.dumps(records, indent=2) + "\n")
    print(label, "PASS" if passed else "FAIL", flush=True)
    if not passed:
        print(result.stderr[-1600:], flush=True)
    return value


inventory_cmd = [
    "nix",
    "eval",
    "--json",
    "--impure",
    "--expr",
    "let f = builtins.getFlake "
    + json.dumps(args.snapshot)
    + "; in { nixos = builtins.attrNames f.nixosConfigurations; darwin = builtins.attrNames f.darwinConfigurations; homes = builtins.attrNames f.homeConfigurations; }",
]
inventory = json.loads(subprocess.check_output(inventory_cmd, text=True))
(args.evidence / "inventory.json").write_text(json.dumps(inventory, indent=2) + "\n")
for name in inventory["nixos"]:
    evaluate(
        "nixos-" + name,
        "let c = f.nixosConfigurations."
        + json.dumps(name)
        + ".config; in { drvPath = c.system.build.toplevel.drvPath; system = c.system.build.toplevel.system; specialisations = builtins.mapAttrs (_: s: s.configuration.system.build.toplevel.drvPath) c.specialisation; }",
    )
for name in inventory["darwin"]:
    evaluate(
        "darwin-" + name,
        "{ drvPath = f.darwinConfigurations." + json.dumps(name) + ".system.drvPath; }",
    )
summary = """x: {
  username = x.home.username; directory = x.home.homeDirectory;
  name = x.khanelinix.user.name; profile = x.khanelinix.packageProfile;
  stylix = x.stylix.enable; scheme = if !x.stylix.enable then null else if builtins.isAttrs x.stylix.base16Scheme then x.stylix.base16Scheme else toString x.stylix.base16Scheme;
  ghostty = x.khanelinix.programs.terminal.emulators.ghostty.enable;
  kitty = x.khanelinix.programs.terminal.emulators.kitty.enable;
  glxinfo = x.khanelinix.programs.terminal.tools.glxinfo.enable;
  tray = x.khanelinix.services.tray.enable; udiskie = x.khanelinix.services.udiskie.enable;
  docker = x.khanelinix.suites.development.dockerEnable;
  cursor = if !x.home.pointerCursor.enable then null else x.home.pointerCursor.name;
  stylixCursor = if x.stylix.cursor == null then null else x.stylix.cursor.name;
} """
for name in inventory["homes"]:
    user, host = name.split("@")
    platform = "darwin" if "khanelimac" in host else "nixos"
    value = evaluate(
        "home-" + name,
        "let h = f.homeConfigurations."
        + json.dumps(name)
        + "; c = f."
        + platform
        + "Configurations."
        + json.dumps(host)
        + ".config.home-manager.users."
        + json.dumps(user)
        + "; summary = "
        + summary
        + "; in { drvPath = h.activationPackage.drvPath; standalone = summary h.config; integrated = summary c; }",
    )
    if value and value["standalone"] != value["integrated"]:
        records[-1]["passed"] = False
        (args.evidence / "results.json").write_text(
            json.dumps(records, indent=2) + "\n"
        )
        print("PARITY MISMATCH", name, flush=True)
for profile in ["core", "standard", "maximal"]:
    for name in ["bruddy@bruddynix", "khaneliman@nixos", "khaneliman@khanelimac"]:
        evaluate(
            "profile-" + profile + "-" + name,
            "let h = f.homeConfigurations."
            + json.dumps(name)
            + ".extendModules { modules = [ { khanelinix.packageProfile = lib.mkForce "
            + json.dumps(profile)
            + "; } ]; }; in { drvPath = h.activationPackage.drvPath; profile = h.config.khanelinix.packageProfile; packages = map lib.getName h.config.home.packages; }",
            validate=lambda value, selected=profile, home=name: (
                value["profile"] == selected
                and ("postman" in value["packages"]) == (selected != "core")
                and (
                    home != "bruddy@bruddynix"
                    or (
                        ("heroic" in value["packages"]) == (selected != "core")
                        and ("wowup-cf" in value["packages"]) == (selected == "maximal")
                        and "moonlight-qt" in value["packages"]
                    )
                )
                and (
                    home == "khaneliman@khanelimac"
                    or ("qtcreator" in value["packages"]) == (selected == "maximal")
                )
            ),
        )
evaluate(
    "profile-override",
    'let h = f.homeConfigurations."bruddy@bruddynix".extendModules { modules = [ { khanelinix.packageProfile = lib.mkForce "core"; khanelinix.suites.games.packageProfile = lib.mkForce "maximal"; } ]; }; in { drvPath = h.activationPackage.drvPath; profile = h.config.khanelinix.packageProfile; suite = h.config.khanelinix.suites.games.packageProfile; packages = map lib.getName h.config.home.packages; }',
    validate=lambda value: (
        value["profile"] == "core"
        and value["suite"] == "maximal"
        and {"heroic", "wowup-cf"} <= set(value["packages"])
        and "qtcreator" not in value["packages"]
    ),
)

consumers = 'import (f.outPath + "/tests/consumers") { flake = f; }'
for name in ["nixos", "darwin", "home", "homeDarwin"]:
    drv = (
        "c.activationPackage.drvPath"
        if name.startswith("home")
        else "c.system.drvPath"
        if name == "darwin"
        else "c.config.system.build.toplevel.drvPath"
    )
    evaluate(
        "consumer-" + name,
        "let c = ("
        + consumers
        + ")."
        + name
        + "; in { drvPath = "
        + drv
        + "; secrets = builtins.attrNames c.config.sops.secrets; sshHosts = c.config.khanelinix.programs.terminal.tools.ssh.hosts; email = c.config.khanelinix.user.email; acmeStaging = "
        + ("c.config.khanelinix.security.acme.staging" if name == "nixos" else "null")
        + "; }",
        validate=lambda value, selected=name: (
            value["secrets"] == []
            and value["sshHosts"] == {}
            and value["email"] in ["", "user@example.invalid"]
            and (selected != "nixos" or value["acmeStaging"] is False)
        ),
    )
for platform in ["nixos", "darwin"]:
    evaluate(
        "consumer-multi-user-" + platform,
        "let c = ("
        + consumers
        + ")."
        + platform
        + ".extendModules { modules = [ { "
        + ("users.users.alice.isNormalUser = true; " if platform == "nixos" else "")
        + 'users.users.alice.home = "'
        + ("/Users/alice" if platform == "darwin" else "/home/alice")
        + '"; home-manager.users.alice = { home.stateVersion = "26.05"; khanelinix.user.enable = true; }; } ]; }; h = c.config.home-manager.users.alice; in { name = h.khanelinix.user.name; username = h.home.username; directory = h.home.homeDirectory; email = h.khanelinix.user.email; drvPath = h.home.activationPackage.drvPath; systemDrvPath = c.config.system.build.toplevel.drvPath; }',
        validate=lambda value, selected=platform: (
            value["name"] == "alice"
            and value["username"] == "alice"
            and value["directory"]
            == ("/Users/alice" if selected == "darwin" else "/home/alice")
            and value["email"] == ""
        ),
    )
    evaluate(
        "consumer-home-network-" + platform,
        "let c = ("
        + consumers
        + ")."
        + platform
        + '.extendModules { modules = [ { home-manager.users.example.khanelinix.environments.home-network = { enable = true; serverHostname = "server.example.invalid"; serverLocalHostname = "server.local"; }; } ]; }; h = c.config.home-manager.users.example; in { drvPath = h.home.activationPackage.drvPath; server = h.programs.ssh.settings."austinserver austinserver.local server".data.HostName; systemDrvPath = c.config.system.build.toplevel.drvPath; }',
        validate=lambda value: value["server"] == "server.local",
    )
for backend in ["none", "colima", "docker-desktop"]:
    evaluate(
        "backend-" + backend,
        'let c = f.darwinConfigurations.khanelimac.extendModules { modules = [ { khanelinix.suites.development.containerBackend = lib.mkForce "'
        + backend
        + '"; } ]; }; in { drvPath = c.system.drvPath; docker = c.config.home-manager.users.khaneliman.khanelinix.suites.development.dockerEnable; colima = c.config.home-manager.users.khaneliman.launchd.agents ? colima-default; casks = map (cask: cask.name) c.config.homebrew.casks; }',
        validate=lambda value, selected=backend: (
            value["docker"] == (selected != "none")
            and value["colima"] == (selected == "colima")
            and ("docker-desktop" in value["casks"]) == (selected == "docker-desktop")
        ),
    )
evaluate(
    "invalid-backend",
    "let c = f.darwinConfigurations.khanelimac.extendModules { modules = [ { khanelinix.home.extraOptions.khanelinix.suites.development.dockerEnable = lib.mkForce false; } ]; }; in c.system.drvPath",
    expected_failure=True,
    error_message="The embedded Home Manager Docker capability must match",
)
evaluate("library", "lib.runTests f.tests", validate=lambda value: value == [])
evaluate(
    "package-platforms",
    "{ linuxClamshell = f.packages.x86_64-linux ? clamshell; darwinNeedsReboot = f.packages.aarch64-darwin ? nixos-needsreboot; clamshell = f.packages.aarch64-darwin.clamshell.meta.platforms; needsReboot = f.packages.x86_64-linux.nixos-needsreboot.meta.platforms; }",
    validate=lambda value: (
        not value["linuxClamshell"]
        and not value["darwinNeedsReboot"]
        and "aarch64-darwin" in value["clamshell"]
        and "x86_64-linux" in value["needsReboot"]
    ),
)
evaluate(
    "consumer-credentials",
    "let h = ("
    + consumers
    + ").home.extendModules { modules = [ { khanelinix.programs.terminal.tools = { atuin.enable = true; github-copilot-cli.enable = true; }; khanelinix.programs.terminal.social = { slack-term.enable = true; twitch-tui.enable = true; }; khanelinix.programs.graphical.editors.vscode.enable = true; khanelinix.programs.graphical.bars.waybar.enable = true; khanelinix.services.rclone.enable = true; } ]; }; in { secrets = builtins.attrNames h.config.sops.secrets; email = h.config.khanelinix.user.email; rcloneConfig = h.config.khanelinix.services.rclone.configFile; rcloneCache = h.config.khanelinix.services.rclone.cacheDir; }",
    validate=lambda value: (
        value["secrets"] == []
        and value["email"] == "user@example.invalid"
        and value["rcloneConfig"] == "/home/example/.config/rclone/rclone.conf"
        and value["rcloneCache"] == "/home/example/.cache/rclone"
    ),
)
for image in ["installer-minimal", "rescue"]:
    evaluate(
        "image-" + image,
        "let c = f.nixosConfigurations."
        + json.dumps(image)
        + ".config; in { drvPath = c.system.build.isoImage.drvPath; uefi = c.isoImage.makeEfiBootable; usb = c.isoImage.makeUsbBootable; users = builtins.attrNames c.users.users; builders = c.nix.buildMachines; secrets = builtins.attrNames (c.sops.secrets or {}); disks = c.disko.devices or {}; keys = c.users.users.nixos.openssh.authorizedKeys.keys; caches = c.nix.settings.substituters; network = c.networking.networkmanager.enable; }",
        validate=lambda value, name=image: (
            value["uefi"]
            and value["usb"]
            and "khaneliman" not in value["users"]
            and value["builders"] == []
            and value["secrets"] == []
            and value["disks"] == {}
            and value["keys"] == []
            and (name != "rescue" or (value["caches"] == [] and not value["network"]))
        ),
    )
for platform in ["nixos", "darwin"]:
    evaluate(
        "consumer-no-user-" + platform,
        "let c = ("
        + consumers
        + ")."
        + platform
        + ".extendModules { modules = [ { khanelinix.user.name = lib.mkForce null; home-manager.users = lib.mkForce {}; khanelinix.nix.enable = true; "
        + (
            "khanelinix.security.acme = { enable = true; staging = true; }; "
            if platform == "nixos"
            else ""
        )
        + "} ]; }; in { drvPath = "
        + (
            "c.system.drvPath"
            if platform == "darwin"
            else "c.config.system.build.toplevel.drvPath"
        )
        + '; builders = c.config.nix.buildMachines; caches = c.config.nix.settings.substituters; secrets = builtins.attrNames c.config.sops.secrets; user = c.config.khanelinix.user.name; allowedUsers = c.config.nix.settings.allowed-users or [ "*" ]; acmeServer = '
        + ("c.config.security.acme.defaults.server" if platform == "nixos" else "null")
        + "; }",
        validate=lambda value, selected=platform: (
            value["builders"] == []
            and value["secrets"] == []
            and value["user"] is None
            and value["allowedUsers"] == ["*"]
            and value["caches"] == ["https://cache.nixos.org/"]
            and (
                selected != "nixos"
                or value["acmeServer"]
                == "https://acme-staging-v02.api.letsencrypt.org/directory"
            )
        ),
    )
for platform in ["nixos", "darwin"]:
    for network in [False, True]:
        evaluate(
            "consumer-local-cache-" + platform + "-" + str(network).lower(),
            "let c = ("
            + consumers
            + ")."
            + platform
            + '.extendModules { modules = [ { khanelinix.nix = { enable = true; localCaches = { first-host = "first-host.local-1:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; neutral-cache = "neutral-cache.local-1:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; }; }; khanelinix.environments.home-network = { enable = '
            + str(network).lower()
            + '; serverHostname = "server.example.invalid"; enableNFSMounts = false; }; } ]; }; in { caches = c.config.nix.settings.substituters; keys = c.config.nix.settings.trusted-public-keys; builders = c.config.nix.buildMachines; secrets = builtins.attrNames c.config.sops.secrets; }',
            validate=lambda value, enabled=network: (
                ("http://neutral-cache.local:5020" in value["caches"]) == enabled
                and (
                    "neutral-cache.local-1:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
                    in value["keys"]
                )
                == enabled
                and "http://first-host.local:5020" not in value["caches"]
                and "first-host.local-1:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
                not in value["keys"]
                and value["builders"] == []
                and value["secrets"] == []
                and set(value["caches"])
                == (
                    {"https://cache.nixos.org/", "http://neutral-cache.local:5020"}
                    if enabled
                    else {"https://cache.nixos.org/"}
                )
            ),
        )
evaluate(
    "fleet-default-overrides",
    """let
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA override-test";
      expectedKeys = import (f.outPath + "/systems/fleet-authorized-keys.nix");
      probe = mode:
        let
          keys = if mode == "empty" then [] else [ key ];
          caches = if mode == "empty" then {} else {
            override-cache = "override-cache.local-1:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
          };
          c = (f.nixosConfigurations.khanelinix.extendModules { modules = [
            (lib.optionalAttrs (mode != "default") {
              khanelinix.nix.localCaches = caches;
              khanelinix.services.openssh.authorizedKeys = keys;
            })
          ]; }).config;
          h = (f.homeConfigurations."khaneliman@khanelinix".extendModules { modules = [
            (lib.optionalAttrs (mode != "default") {
              khanelinix.programs.terminal.tools.ssh.authorizedKeys = keys;
            })
          ]; }).config;
        in {
          caches = c.khanelinix.nix.localCaches;
          substituters = c.nix.settings.substituters;
          trustedKeys = c.nix.settings.trusted-public-keys;
          systemKeys = c.users.users.khaneliman.openssh.authorizedKeys.keys;
          homeKeys = h.home.file.".ssh/authorized_keys".text;
        };
    in { inherit key expectedKeys; cases = lib.genAttrs [ "default" "empty" "replacement" ] probe; }""",
    validate=lambda value: (
        set(value["cases"]["default"]["caches"]) == {"khanelinix", "khanelimac"}
        and value["cases"]["default"]["systemKeys"] == value["expectedKeys"]
        and value["cases"]["default"]["homeKeys"] == "\n".join(value["expectedKeys"])
        and "http://khanelimac.local:5020" in value["cases"]["default"]["substituters"]
        and value["cases"]["default"]["caches"]["khanelimac"]
        in value["cases"]["default"]["trustedKeys"]
        and value["cases"]["empty"]["caches"] == {}
        and value["cases"]["empty"]["systemKeys"] == []
        and value["cases"]["empty"]["homeKeys"] == ""
        and all(
            key not in value["cases"][mode]["trustedKeys"]
            for mode in ["empty", "replacement"]
            for key in value["cases"]["default"]["caches"].values()
        )
        and all(
            url not in value["cases"][mode]["substituters"]
            for mode in ["empty", "replacement"]
            for url in ["http://khanelinix.local:5020", "http://khanelimac.local:5020"]
        )
        and value["cases"]["replacement"]["caches"]
        == {
            "override-cache": "override-cache.local-1:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
        }
        and value["cases"]["replacement"]["systemKeys"] == [value["key"]]
        and value["cases"]["replacement"]["homeKeys"] == value["key"]
        and "http://override-cache.local:5020"
        in value["cases"]["replacement"]["substituters"]
        and "override-cache.local-1:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
        in value["cases"]["replacement"]["trustedKeys"]
    ),
)
evaluate(
    "optional-disabled",
    "let h = ("
    + consumers
    + ').home.extendModules { specialArgs.inputs = f.inputs // builtins.listToAttrs (map (name: { inherit name; value = throw ("disabled input forced: " + name); }) [ "khanelivim" "mcp-servers-nix" "t3code" "claude-plugins-official" ]); modules = [ { khanelinix.services.sops.enable = lib.mkForce false; khanelinix.programs.terminal.editors.neovim.enable = lib.mkForce false; } ]; }; in { drvPath = h.activationPackage.drvPath; secrets = builtins.attrNames h.config.sops.secrets; }',
    validate=lambda value: value["secrets"] == [],
)
evaluate(
    "consumer-stylix-cursors",
    "let consumers = "
    + consumers
    + """; pkgs = consumers.nixos.pkgs;
      systemCursor = { package = pkgs.bibata-cursors; name = "Bibata-Modern-Ice"; size = 24; };
      home = { followSystem ? true, cursor ? systemCursor, extraOptions ? {} }:
        (consumers.nixos.extendModules { modules = [ {
          stylix = {
            enable = true;
            base16Scheme = "${f.inputs.stylix.inputs.tinted-schemes}/base16/catppuccin-macchiato.yaml";
            inherit cursor;
            homeManagerIntegration.followSystem = followSystem;
          };
          home-manager.users.example = lib.mkMerge [
            { khanelinix.theme.stylix.enable = true; }
            extraOptions
          ];
        } ]; }).config.home-manager.users.example;
      summary = h: {
        stylix = h.stylix.enable;
        cursor = if h.stylix.cursor == null then null else {
          inherit (h.stylix.cursor) name size;
        };
        pointer = if !h.home.pointerCursor.enable then null else {
          inherit (h.home.pointerCursor) name size;
        };
      };
      cases = {
      inherited = home {};
      independent = home { followSystem = false; };
      explicitNamespace = home { followSystem = false; extraOptions.khanelinix.theme.stylix.cursor.size = 40; };
      inheritedNamespace = home { extraOptions.khanelinix.theme.stylix.cursor.size = 40; };
      explicitUpstream = home { extraOptions.stylix.cursor = {
        package = pkgs.catppuccin-cursors.macchiatoBlue;
        name = "catppuccin-macchiato-blue-cursors"; size = 48;
      }; };
      curated = home { extraOptions.khanelinix.theme.catppuccin.enable = true; };
      nullSystemCursor = home { cursor = null; };
      explicitNullNamespace = home { cursor = null; extraOptions.khanelinix.theme.stylix.cursor.size = 40; };
      disabledHomeCursor = home { extraOptions.stylix.cursor = null; };
      standalone = (consumers.home.extendModules { modules = [ { khanelinix.theme.stylix.enable = true; } ]; }).config;
      };
    in {
      cases = builtins.mapAttrs (_: summary) cases;
      builds = builtins.mapAttrs (_: h: h.home.activationPackage.drvPath) {
        inherit (cases) inherited standalone;
      };
    }""",
    validate=lambda value: (
        all(case["stylix"] for case in value["cases"].values())
        and all(
            value["cases"][name]["pointer"] == {"name": cursor, "size": size}
            for name, cursor, size in [
                ("inherited", "Bibata-Modern-Ice", 24),
                ("independent", "catppuccin-macchiato-blue-cursors", 32),
                ("explicitNamespace", "catppuccin-macchiato-blue-cursors", 40),
                ("inheritedNamespace", "Bibata-Modern-Ice", 24),
                ("explicitUpstream", "catppuccin-macchiato-blue-cursors", 48),
                ("curated", "catppuccin-macchiato-blue-cursors", 32),
                ("nullSystemCursor", "catppuccin-macchiato-blue-cursors", 32),
                ("explicitNullNamespace", "catppuccin-macchiato-blue-cursors", 40),
                ("standalone", "catppuccin-macchiato-blue-cursors", 32),
            ]
        )
        and all(
            value["cases"][name]["cursor"] == value["cases"][name]["pointer"]
            for name in [
                "inherited",
                "independent",
                "explicitNamespace",
                "inheritedNamespace",
                "explicitUpstream",
                "nullSystemCursor",
                "explicitNullNamespace",
                "standalone",
            ]
        )
        and value["cases"]["curated"]["cursor"] is None
        and value["cases"]["disabledHomeCursor"]["cursor"] is None
        and value["cases"]["disabledHomeCursor"]["pointer"] is None
    ),
)
for platform in ["nixos", "darwin"]:
    evaluate(
        "consumer-stylix-manual-" + platform,
        "let c = ("
        + consumers
        + ")."
        + platform
        + '.extendModules { modules = [ { stylix = { enable = true; homeManagerIntegration.autoImport = false; base16Scheme = "${f.inputs.stylix.inputs.tinted-schemes}/base16/catppuccin-macchiato.yaml"; }; home-manager.users.example.khanelinix.theme.stylix.enable = true; } ]; }; h = c.config.home-manager.users.example; in { drvPath = h.home.activationPackage.drvPath; stylix = h.stylix.enable; }',
        validate=lambda value: value["stylix"],
    )

(args.evidence / "results.json").write_text(json.dumps(records, indent=2) + "\n")
if not records:
    parser.error("no verification cases matched the requested selectors")
raise SystemExit(0 if all(r["passed"] for r in records) else 1)
