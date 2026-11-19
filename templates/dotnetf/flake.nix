{
  description = "Hello World in .NET";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs =
    { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachSystem
      [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ]
      (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          projectFile = "./HelloWorld/HelloWorld.fsproj";
          testProjectFile = "./HelloWorld.Test/HelloWorld.Test.fsproj";
          dotnet-sdk = pkgs.dotnet-sdk_10;
        in
        {
          packages = rec {
            fantomas = pkgs.buildDotnetGlobalTool {
              pname = "fantomas";
              version = "8.1.3";
              inherit dotnet-sdk;
              dotnet-runtime = dotnet-sdk;
              nugetHash = "sha256-qEbMjuW7wxJib1aenmWhRFvmYeeeKK8KgYmXK83trD8=";
            };
            fetchDeps = pkgs.writeShellScriptBin "fetch-dotnet-helloworld-deps" ''
              set -e
              depsFile="''${1:-$(${pkgs.coreutils}/bin/mktemp -t HelloWorld-deps-XXXXXXXX.json)}"
              exec ${default.fetch-deps} "$depsFile"
            '';
            default = pkgs.buildDotnetModule {
              pname = "HelloWorld";
              inherit
                dotnet-sdk
                projectFile
                testProjectFile
                ;
              version = "0.0.1";
              src = ./.;
              nugetDeps = ./nix/deps.json;
              doCheck = true;
              # VSTest uses loopback, but the Darwin sandbox rejects IPv4-mapped IPv6.
              __darwinAllowLocalNetworking = true;
              dotnetTestFlags = pkgs.lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
                "--environment"
                "DOTNET_SYSTEM_NET_DISABLEIPV6=1"
              ];
            };
          };
          devShells = {
            default = pkgs.mkShell {
              packages = [
                dotnet-sdk
                pkgs.git
                pkgs.alejandra
                pkgs.markdown-link-check
              ];
            };
          };
        }
      );
}
