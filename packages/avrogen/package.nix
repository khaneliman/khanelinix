{ pkgs, ... }:
# TODO: upstream
pkgs.buildDotnetGlobalTool {
  pname = "avrogen";
  nugetName = "Apache.Avro.Tools";
  version = "1.12.0";
  nugetSha256 = "sha256-bR2ObY5hFCAWD326Y6NkN5FRyNWCKu4JaXlZ1dKY+XY=";
}
