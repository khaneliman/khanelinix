{
  pkgs,
  lib,
  ...
}:
{
  react = {
    name = "react";

    languages.javascript = {
      enable = true;
      npm.enable = true;
      yarn.enable = true;
      pnpm.enable = true;
    };

    packages =
      with pkgs;
      [
        nodejs_22
        bun
        typescript-language-server
        typescript
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
        react-native-debugger
      ];

    enterShell = ''
      echo "🔨 React DevShell"
      echo "Node.js $(node --version)"
    '';
  };
}
