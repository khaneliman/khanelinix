{
  pkgs,
  lib,
  ...
}:
{
  react = {
    name = "react";
    packages =
      with pkgs;
      [
        # FIXME: broken nixpkg
        # create-react-app
        nodejs_22
        pnpm
        yarn
        bun
        typescript-language-server
        typescript
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
        react-native-debugger
      ];
    devshell.motd = "🔨 React DevShell";
  };
}
