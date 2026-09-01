{ pkgs, ... }:
# TODO: upstream
pkgs.buildDotnetGlobalTool {
  pname = "avrogen";
  nugetName = "Apache.Avro.Tools";
  version = "1.12.2";
  nugetSha256 = "sha256-DuituWLGO4Q3fESaLg3vEM+92XRxG5muoov4g7D02gQ=";
}
