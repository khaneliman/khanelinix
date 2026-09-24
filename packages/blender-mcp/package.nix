{
  lib,
  fetchgit,
  python3Packages,
  zip,
  ...
}:

python3Packages.buildPythonApplication (finalAttrs: {
  pname = "blender-mcp";
  version = "1.0.3";

  src = fetchgit {
    url = "https://projects.blender.org/lab/blender_mcp.git";
    rev = "v1.0.3";
    hash = "sha256-pYeByO4Oi5eyynsJhGVd1vBWXHvhGn+Y5LGit6Kazlw=";
  };
  postUnpack = ''sourceRoot="$sourceRoot/mcp"'';
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
    cp -r "${finalAttrs.src}/addon/blender_mcp_addon" "$addonDir/"
    (cd "$addonDir/blender_mcp_addon" && zip -qr "$addonDir/blender_mcp_addon-${finalAttrs.version}.zip" .)
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
})
