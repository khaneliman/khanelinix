_: _final: prev: {
  # TODO: remove once fix makes it to nixos-unstable
  oh-my-posh =
    let
      version = "19.6.0";

      src = prev.fetchFromGitHub {
        owner = "jandedobbeleer";
        repo = "oh-my-posh";
        rev = "refs/tags/v19.6.0";
        hash = "sha256-/VkI/ACUTGRcFpJhUV068m8HdM44NiandS+2a+Ms6vs=";
      };

      vendorHash = "sha256-8ZupQe4b3uCX79Q0oYqggMWZE9CfX5OSFdLIrxT8CHY=";
    in
    (prev.callPackage "${prev.path}/pkgs/development/tools/oh-my-posh" {
      buildGoModule = args: prev.buildGoModule (args // {
        inherit src version vendorHash;
      });
    });
}
