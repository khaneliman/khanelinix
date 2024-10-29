{ pkgs, ... }:
# TODO: upstream
pkgs.buildDotnetGlobalTool {
  pname = "upgrade-assistant";
  nugetName = "upgrade-assistant";
  version = "0.5.820";
  nugetSha256 = "sha256-GB+q5aZRkBTeXUbIPjkPsll6pSI/H6Iyh5mY53uT284=";
}
