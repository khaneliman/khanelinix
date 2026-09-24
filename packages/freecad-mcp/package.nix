{
  lib,
  fetchFromGitHub,
  python3Packages,
  ...
}:

python3Packages.buildPythonApplication {
  pname = "freecad-mcp";
  version = "0.1.24";

  src = fetchFromGitHub {
    owner = "neka-nat";
    repo = "freecad-mcp";
    rev = "751974609a401660a58a1772ef16f3afbeba9ba1";
    hash = "sha256-zo9FZ+hhD2DwT5zg2KKBrD52Q/doLTOIQtJfY2z2KLU=";
  };

  pyproject = true;
  build-system = [ python3Packages.hatchling ];
  dependencies = with python3Packages; [
    mcp
    validators
  ];

  nativeCheckInputs = [ python3Packages.pytestCheckHook ];
  pythonImportsCheck = [ "freecad_mcp.server" ];
  # RPC tests bind loopback sockets inside the Darwin build sandbox.
  __darwinAllowLocalNetworking = true;

  postInstall = ''
    install -d "$out/share/freecad-mcp"
    cp -r addon/FreeCADMCP "$out/share/freecad-mcp/"
    install -m644 LICENSE "$out/share/freecad-mcp/LICENSE"
  '';

  postCheck = ''
    "$out/bin/freecad-mcp" --help >/dev/null
  '';

  meta = {
    description = "MCP server and FreeCAD add-on for parametric modeling";
    homepage = "https://github.com/neka-nat/freecad-mcp";
    license = lib.licenses.mit;
    mainProgram = "freecad-mcp";
    maintainers = [ lib.maintainers.khaneliman ];
    platforms = lib.platforms.unix;
  };
}
