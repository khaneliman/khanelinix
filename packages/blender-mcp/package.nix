{
  lib,
  fetchgit,
  python3Packages,
  zip,
  ...
}:

let
  upstreamSrc = fetchgit {
    url = "https://projects.blender.org/lab/blender_mcp.git";
    rev = "ff54e4d8f6b09502f2f466189cca0e52b4a91643";
    hash = "sha256-RiTR8XlBiAuJ7SgD8vGGMrp55BPiYIrObs09RwykfM8=";
  };
in
python3Packages.buildPythonApplication {
  pname = "blender-mcp";
  version = "1.0.2";

  src = "${upstreamSrc}/mcp";
  pyproject = true;

  build-system = [ python3Packages.setuptools ];
  nativeBuildInputs = [ zip ];

  propagatedBuildInputs = with python3Packages; [
    docutils
    mcp
    pyyaml
  ];

  pythonImportsCheck = [ "blmcp" ];

  postInstall = ''
    addonDir="$out/share/blender-mcp/addon"
    install -d "$addonDir"
    cp -r "${upstreamSrc}/addon/blender_mcp_addon" "$addonDir/"
    (cd "$addonDir/blender_mcp_addon" && zip -qr "$addonDir/blender_mcp_addon-1.0.2.zip" .)
  '';

  installCheckPhase = ''
    runHook preInstallCheck
    "$out/bin/blender-mcp" --help >/dev/null
    runHook postInstallCheck
  '';

  meta = {
    description = "Official Blender Lab MCP server and Blender add-on";
    homepage = "https://www.blender.org/lab/mcp-server/";
    license = lib.licenses.gpl3Plus;
    mainProgram = "blender-mcp";
    maintainers = [ lib.maintainers.khaneliman ];
    platforms = lib.platforms.unix;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
}
