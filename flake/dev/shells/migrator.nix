{
  pkgs,
  lib,
  ...
}:
{
  migrator = {
    name = "migrator";

    languages.javascript = {
      enable = true;
      npm.enable = true;
      yarn.enable = true;
      pnpm.enable = true;
    };

    packages =
      with pkgs;
      [
        bun
        nodejs_20
        eslint_d
        typescript-language-server
        typescript
        claude-code
        csharpier
        (csharp-ls.overrideAttrs (_oldAttrs: {
          useDotnetFromEnv = false;
          meta.badPlatforms = [ ];
        }))
        (
          with dotnetCorePackages;
          combinePackages [
            dotnet-aspnetcore_8
            dotnet-runtime_8
            dotnet-sdk_8
          ]
        )
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
        react-native-debugger
      ];

    enterShell = ''
      echo "🔨 Migrator DevShell"
      echo "Node.js $(node --version)"
      echo "Full-stack development environment ready"
    '';
  };
}
