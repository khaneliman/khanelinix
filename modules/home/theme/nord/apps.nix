{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkDefault mkIf;

  cfg = config.khanelinix.theme.nord;
  inherit ((import ./colors.nix)) palette;
in
{
  config = mkIf cfg.enable {
    programs = {
      alacritty.settings.general.import = [
        "${pkgs.alacritty-theme}/share/alacritty-theme/nord.toml"
      ];

      ghostty.settings.theme = "nord";

      helix.settings.theme = mkDefault "Nord";

      kitty.extraConfig = ''
        include ${pkgs.kitty-themes}/share/kitty-themes/themes/Nord.conf
      '';

      neovim.plugins = [
        pkgs.vimPlugins.nord-nvim
      ];

      tmux.plugins = [
        { plugin = pkgs.tmuxPlugins.nord; }
      ];

      vicinae.settings.theme = lib.mkForce {
        name = "nord";
        light.name = "nord-light";
        dark.name = "nord";
      };

      wezterm.extraConfig = /* Lua */ ''
        function scheme_for_appearance(appearance)
          if appearance:find "Dark" then
            return "nord"
          else
            return "nord-light"
          end
        end
      '';

      yazi = {
        theme = lib.mkForce (import ./yazi/theme.nix { inherit (import ./colors.nix) palette; });
      };

      swaylock.settings = mkIf config.khanelinix.programs.graphical.screenlockers.swaylock.enable {
        key-hl-color = palette.nord9.hex;
        bs-hl-color = palette.nord11.hex;
        caps-lock-key-hl-color = palette.nord12.hex;
        caps-lock-bs-hl-color = palette.nord11.hex;

        separator-color = palette.nord0.hex;

        inside-color = palette.nord1.hex;
        inside-clear-color = palette.nord1.hex;
        inside-caps-lock-color = palette.nord1.hex;
        inside-ver-color = palette.nord1.hex;
        inside-wrong-color = palette.nord1.hex;

        ring-color = palette.nord2.hex;
        ring-clear-color = palette.nord9.hex;
        ring-caps-lock-color = palette.nord12.hex;
        ring-ver-color = palette.nord2.hex;
        ring-wrong-color = palette.nord11.hex;

        line-color = palette.nord9.hex;
        line-clear-color = palette.nord9.hex;
        line-caps-lock-color = palette.nord12.hex;
        line-ver-color = palette.nord0.hex;
        line-wrong-color = palette.nord11.hex;

        text-color = palette.nord5.hex;
        text-clear-color = palette.nord5.hex;
        text-caps-lock-color = palette.nord5.hex;
        text-ver-color = palette.nord5.hex;
        text-wrong-color = palette.nord5.hex;
      };
    };

    xdg.configFile = mkIf config.khanelinix.programs.graphical.bars.sketchybar.enable {
      "sketchybar/colors.lua".text =
        let
          toLuaColor = hex: "0xff" + builtins.substring 1 6 hex;
        in
        ''
          #!/usr/bin/env lua

          local colors = {
            base = ${toLuaColor palette.nord0.hex},
            mantle = ${toLuaColor palette.nord1.hex},
            crust = ${toLuaColor palette.nord0.hex},
            text = ${toLuaColor palette.nord6.hex},
            subtext0 = ${toLuaColor palette.nord5.hex},
            subtext1 = ${toLuaColor palette.nord4.hex},
            surface0 = ${toLuaColor palette.nord1.hex},
            surface1 = ${toLuaColor palette.nord2.hex},
            surface2 = ${toLuaColor palette.nord3.hex},
            overlay0 = ${toLuaColor palette.nord3.hex},
            overlay1 = ${toLuaColor palette.nord3.hex},
            overlay2 = ${toLuaColor palette.nord3.hex},
            blue = ${toLuaColor palette.nord10.hex},
            lavender = ${toLuaColor palette.nord9.hex},
            sapphire = ${toLuaColor palette.nord8.hex},
            sky = ${toLuaColor palette.nord8.hex},
            teal = ${toLuaColor palette.nord7.hex},
            green = ${toLuaColor palette.nord14.hex},
            yellow = ${toLuaColor palette.nord13.hex},
            peach = ${toLuaColor palette.nord12.hex},
            maroon = ${toLuaColor palette.nord11.hex},
            red = ${toLuaColor palette.nord11.hex},
            mauve = ${toLuaColor palette.nord15.hex},
            pink = ${toLuaColor palette.nord15.hex},
            flamingo = ${toLuaColor palette.nord12.hex},
            rosewater = ${toLuaColor palette.nord6.hex},
          }

          colors.random_cat_color = {
            colors.blue,
            colors.lavender,
            colors.sapphire,
            colors.sky,
            colors.teal,
            colors.green,
            colors.yellow,
            colors.peach,
            colors.maroon,
            colors.red,
            colors.mauve,
            colors.pink,
            colors.flamingo,
            colors.rosewater,
          }

          colors.getRandomCatColor = function()
            return colors.random_cat_color[math.random(1, #colors.random_cat_color)]
          end

          return colors
        '';
    };

  };
}
